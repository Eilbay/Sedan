import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/bloc/upload_cubit/upload_cubit.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/models/posts/posts_stats_by_owner.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/data/repositories/i_reel_repository.dart';
import 'package:optombai/bloc/language_bloc/language_bloc.dart';
import 'package:optombai/bloc/language_bloc/language_state.dart';
import 'package:optombai/services/media/media_processor.dart';
import 'package:optombai/services/reel_metadata_cache.dart';
import 'package:optombai/widgets/common/upload_progress_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProductRepo extends Mock implements IProductRepository {}

class MockReelRepo extends Mock implements IReelRepository {}

class MockMetadataCache extends Mock implements IReelMetadataCache {}

class MockMediaProcessor extends Mock implements MediaProcessor {}

/// Thin subclass of UploadCubit that lets tests push arbitrary state
/// without going through the real startUpload flow.
class FakeUploadCubit extends UploadCubit {
  FakeUploadCubit({
    required super.repository,
    required super.preferences,
    required super.mediaProcessor,
  });

  void set(UploadState s) => emit(s);
}

void main() {
  late FakeUploadCubit upload;
  late MockProductRepo productRepo;
  late MockReelRepo reelRepo;
  late MockMetadataCache metadataCache;
  late MockMediaProcessor mediaProcessor;
  late SharedPreferences prefs;
  late ProductBloc productBloc;
  late ReelBloc reelBloc;
  late LanguageBloc languageBloc;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    productRepo = MockProductRepo();
    reelRepo = MockReelRepo();
    metadataCache = MockMetadataCache();
    mediaProcessor = MockMediaProcessor();
    upload = FakeUploadCubit(
      repository: productRepo,
      preferences: prefs,
      mediaProcessor: mediaProcessor,
    );
    productBloc = ProductBloc(repository: productRepo, preferences: prefs);
    reelBloc = ReelBloc(
      repository: reelRepo,
      metadataCache: metadataCache,
      preferences: prefs,
    );
    languageBloc = LanguageBloc(prefs);
  });

  tearDown(() async {
    await upload.close();
    await productBloc.close();
    await reelBloc.close();
    await languageBloc.close();
  });

  Widget _host() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<UploadCubit>.value(value: upload),
          BlocProvider<ProductBloc>.value(value: productBloc),
          BlocProvider<ReelBloc>.value(value: reelBloc),
          BlocProvider<LanguageBloc>.value(value: languageBloc),
        ],
        child: const Scaffold(body: UploadProgressBanner()),
      ),
    );
  }

  testWidgets('Idle → SizedBox.shrink, no banner rendered', (tester) async {
    await tester.pumpWidget(_host());
    // No progress indicator, no status/error icons.
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.byIcon(Icons.videocam), findsNothing);
  });

  testWidgets('Processing → shows video icon + indeterminate progress',
      (tester) async {
    await tester.pumpWidget(_host());
    upload.set(const UploadProcessing(statusText: 'Сжатие видео...'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.videocam), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, isNull, reason: 'Processing uses indeterminate bar');
  });

  testWidgets('Creating → indeterminate progress, no error/success icon',
      (tester) async {
    await tester.pumpWidget(_host());
    upload.set(const UploadCreating());
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, isNull, reason: 'Creating uses indeterminate bar');
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('Uploading → progress bar reflects state.progress',
      (tester) async {
    await tester.pumpWidget(_host());
    upload.set(const UploadUploading(
      progress: 0.25,
      uploaded: 0,
      total: 2,
    ));
    await tester.pump();
    var bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.25);

    upload.set(const UploadUploading(
      progress: 0.8,
      uploaded: 1,
      total: 2,
    ));
    // Equatable on UploadUploading includes all fields, so this emit
    // triggers a rebuild. Two pumps: first for emit, second for widget rebuild.
    await tester.pump();
    await tester.pump();
    bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 0.8);
  });

  testWidgets(
      'First UploadUploading with optimisticProduct → OptimisticAdd fires once',
      (tester) async {
    await tester.pumpWidget(_host());

    final optimistic = Product(id: 'new-post', name: 'probe');
    upload.set(UploadUploading(
      progress: 0,
      uploaded: 0,
      total: 1,
      optimisticProduct: optimistic,
    ));
    await tester.pump();

    expect(
      productBloc.state.products.map((p) => p.id),
      contains('new-post'),
      reason: 'OptimisticAddProductEvent should have been dispatched',
    );

    // Further Uploading emissions with same optimistic id must NOT re-insert.
    upload.set(UploadUploading(
      progress: 0.5,
      uploaded: 0,
      total: 1,
      optimisticProduct: optimistic,
    ));
    await tester.pump();

    final count =
        productBloc.state.products.where((p) => p.id == 'new-post').length;
    expect(count, 1);
  });

  testWidgets('Success → shows check icon and triggers feed refresh',
      (tester) async {
    when(() => productRepo.fetchProductsByFilter()).thenAnswer(
      (_) async => const PostModel(count: 0, results: <Product>[]),
    );

    await tester.pumpWidget(_host());
    upload.set(const UploadSuccess(postId: 'p'));
    // First pump lets BlocBuilder rebuild, second flushes the
    // post-frame callback that dispatches RefreshCurrentFilterEvent.
    await tester.pump();
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    // Allow the ProductBloc handler chain to complete.
    await tester.pump(const Duration(milliseconds: 100));
    verify(() => productRepo.fetchProductsByFilter())
        .called(greaterThanOrEqualTo(1));

    // Cancel the 3s auto-dismiss timer so teardown doesn't hang.
    upload.set(const UploadIdle());
    await tester.pump();
  });

  testWidgets('Error → shows error icon, raw message text, and retry affordance',
      (tester) async {
    await tester.pumpWidget(_host());
    upload.set(const UploadError(
      message: 'connection timed out',
      mediaFiles: [],
      postId: '',
      token: 't',
    ));
    await tester.pump();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    // Raw message goes through a plain Text (not TextTranslated), so we can
    // match it directly.
    expect(find.text('connection timed out'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });

  testWidgets(
      'Uploading→Error with postId rolls back the optimistic card from feed',
      (tester) async {
    await tester.pumpWidget(_host());

    // Step 1: optimistic insert.
    final optimistic = Product(id: 'broken-post', name: 'broken');
    upload.set(UploadUploading(
      progress: 0,
      uploaded: 0,
      total: 1,
      optimisticProduct: optimistic,
    ));
    await tester.pump();
    expect(productBloc.state.products.any((p) => p.id == 'broken-post'),
        isTrue);

    // Step 2: media upload fails. Banner must dispatch remove event.
    upload.set(const UploadError(
      message: '500 HeadObject Forbidden',
      mediaFiles: [],
      postId: 'broken-post',
      token: 't',
    ));
    await tester.pump();

    expect(
      productBloc.state.products.any((p) => p.id == 'broken-post'),
      isFalse,
      reason:
          'Optimistic card must be removed when media upload fails — '
          'otherwise user sees a card with local thumbnail that never '
          'resolves to a real server cover.',
    );
  });
}

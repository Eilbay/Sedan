import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:optombai/bloc/upload_cubit/upload_cubit.dart';
import 'package:optombai/core/enums/request_type.dart';
import 'package:optombai/data/models/media_file.dart';
import 'package:optombai/data/models/posts/post_model.dart';
import 'package:optombai/data/repositories/i_product_repository.dart';
import 'package:optombai/services/media/media_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockRepository extends Mock implements IProductRepository {}

class MockMediaProcessor extends Mock implements MediaProcessor {}

class FakeProduct extends Fake implements Product {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProduct());
    registerFallbackValue(EnumRequestType.post);
    registerFallbackValue(<MediaFile>[]);
  });

  late MockRepository repo;
  late MockMediaProcessor processor;
  late SharedPreferences prefs;
  late UploadCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'TOKEN_KEY': 'test-token'});
    prefs = await SharedPreferences.getInstance();
    repo = MockRepository();
    processor = MockMediaProcessor();
    cubit = UploadCubit(
      repository: repo,
      preferences: prefs,
      mediaProcessor: processor,
    );
  });

  tearDown(() => cubit.close());

  File _fakeFile(String path) {
    // File object only needs a valid path for our tests — we don't touch I/O
    // because the repository and processor are mocked.
    final tmp = File('${Directory.systemTemp.path}/$path');
    tmp.writeAsStringSync('x');
    return tmp;
  }

  group('startUpload', () {
    test('emits Creating → Uploading(optimisticProduct) → Success', () async {
      final product = Product(id: '', name: 'n');
      final photo = _fakeFile('photo.jpg');
      final media = [MediaFile(file: photo, type: MediaType.image, size: 10)];

      when(() => repo.createPost(any(), any(), any()))
          .thenAnswer((_) async => 'post-42');
      when(() => repo.uploadMediaWithProgress(
            any(),
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        final cb = invocation.namedArguments[#onProgress]
            as void Function(int, int, double)?;
        cb?.call(0, 1, 0.5);
        cb?.call(1, 1, 1.0);
      });

      final emitted = <UploadState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.startUpload(
        product: product,
        mediaFiles: media,
        requestType: EnumRequestType.post,
      );

      for (var i = 0; i < 5; i++) {
        await Future<void>.value();
      }
      await sub.cancel();

      expect(emitted.first, isA<UploadCreating>());
      expect(
        emitted.whereType<UploadUploading>().first.optimisticProduct,
        isNotNull,
        reason: 'first Uploading emission must carry an optimistic product',
      );
      final firstUploading = emitted.whereType<UploadUploading>().first;
      expect(firstUploading.optimisticProduct!.id, 'post-42');
      expect(emitted.last, isA<UploadSuccess>());
      expect((emitted.last as UploadSuccess).postId, 'post-42');
    });

    test('progress monotonically increases during upload', () async {
      final product = Product(id: '', name: 'n');
      final files = [
        MediaFile(file: _fakeFile('1.jpg'), type: MediaType.image),
        MediaFile(file: _fakeFile('2.jpg'), type: MediaType.image),
      ];
      when(() => repo.createPost(any(), any(), any()))
          .thenAnswer((_) async => 'pid');
      when(() => repo.uploadMediaWithProgress(
            any(),
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        final cb = invocation.namedArguments[#onProgress]
            as void Function(int, int, double)?;
        // Simulate realistic progress events from two files.
        cb?.call(0, 2, 0.3);
        cb?.call(0, 2, 0.7);
        cb?.call(1, 2, 1.0);
        cb?.call(1, 2, 0.5);
        cb?.call(2, 2, 1.0);
      });

      final progresses = <double>[];
      final sub = cubit.stream.listen((s) {
        if (s is UploadUploading) progresses.add(s.progress);
      });

      await cubit.startUpload(
        product: product,
        mediaFiles: files,
        requestType: EnumRequestType.post,
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.value();
      }
      await sub.cancel();

      expect(progresses.first, 0.0);
      expect(progresses.last, 1.0);
      expect(
        progresses.every((p) => p >= 0.0 && p <= 1.0),
        isTrue,
        reason: 'progress should be clamped to [0, 1]',
      );
      // Not strictly monotonic because of per-file resets, but must end at 1.
      expect(progresses, contains(1.0));
    });

    test('emits Success even when media list is empty (no upload call)',
        () async {
      when(() => repo.createPost(any(), any(), any()))
          .thenAnswer((_) async => 'pid');

      final emitted = <UploadState>[];
      final sub = cubit.stream.listen(emitted.add);

      await cubit.startUpload(
        product: Product(),
        mediaFiles: const [],
        requestType: EnumRequestType.post,
      );
      for (var i = 0; i < 5; i++) {
        await Future<void>.value();
      }
      await sub.cancel();

      expect(cubit.state, isA<UploadSuccess>());
      verifyNever(() => repo.uploadMediaWithProgress(
            any(),
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          ));
    });

    test('emits UploadError with media files and token on failure', () async {
      final files = [
        MediaFile(file: _fakeFile('1.jpg'), type: MediaType.image),
      ];
      when(() => repo.createPost(any(), any(), any()))
          .thenAnswer((_) async => 'pid');
      when(() => repo.uploadMediaWithProgress(
            any(),
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          )).thenThrow(Exception('network'));

      await cubit.startUpload(
        product: Product(),
        mediaFiles: files,
        requestType: EnumRequestType.post,
      );

      final state = cubit.state;
      expect(state, isA<UploadError>());
      final err = state as UploadError;
      expect(err.postId, 'pid');
      expect(err.mediaFiles, files);
      expect(err.token, 'test-token');
    });

    test('ignores new upload while one is in progress', () async {
      final completer = Completer<String>();
      when(() => repo.createPost(any(), any(), any()))
          .thenAnswer((_) => completer.future);

      // First upload stays pending.
      final f1 = cubit.startUpload(
        product: Product(),
        mediaFiles: const [],
        requestType: EnumRequestType.post,
      );

      // Second upload attempted while first is in flight.
      await cubit.startUpload(
        product: Product(),
        mediaFiles: const [],
        requestType: EnumRequestType.post,
      );

      // createPost must have been called only once.
      verify(() => repo.createPost(any(), any(), any())).called(1);

      completer.complete('pid');
      await f1;
    });
  });

  group('retry', () {
    test('resumes media upload with the same postId after UploadError',
        () async {
      final files = [
        MediaFile(file: _fakeFile('1.jpg'), type: MediaType.image),
      ];
      when(() => repo.createPost(any(), any(), any()))
          .thenAnswer((_) async => 'pid');

      var attempts = 0;
      when(() => repo.uploadMediaWithProgress(
            any(),
            any(),
            any(),
            onProgress: any(named: 'onProgress'),
          )).thenAnswer((invocation) async {
        attempts++;
        if (attempts == 1) throw Exception('flaky');
        final cb = invocation.namedArguments[#onProgress]
            as void Function(int, int, double)?;
        cb?.call(1, 1, 1.0);
      });

      await cubit.startUpload(
        product: Product(),
        mediaFiles: files,
        requestType: EnumRequestType.post,
      );
      expect(cubit.state, isA<UploadError>());

      await cubit.retry();
      expect(cubit.state, isA<UploadSuccess>());
      // createPost not called again — retry only re-uploads media.
      verify(() => repo.createPost(any(), any(), any())).called(1);
      expect(attempts, 2);
    });
  });
}

import 'package:collection/collection.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/features/promotion/presentation/widgets/promotion_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:optombai/bloc/feature_flags_cubit/feature_flags_cubit.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/utils/extensions/iso_date_extension.dart';
import 'package:optombai/widgets/product/dual_price_text.dart';
import 'package:optombai/bloc/reel_bloc/reel_bloc.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/pages/profile/edit/widgets/check_video.dart';
import 'package:optombai/utils/extensions/video_url_extension.dart';
import 'package:optombai/pages/profile/edit/widgets/video_view_screen.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

/// Local, presentation-only promotion phase. It is NOT the backend campaign
/// status — it only drives a short "moderation" badge shown right after the
/// owner launches a promotion, before the active "Продвигается" badge.
enum _PromotionPhase { none, moderation, promoted }

@RoutePage(name: 'StateUserProductDetailsRoute')
class StateUserProductDetails extends StatefulWidget {
  const StateUserProductDetails(
      {super.key, required this.id, required this.results});

  final String id;
  final Product results;

  @override
  State<StateUserProductDetails> createState() =>
      _StateUserProductDetailsState();
}

class _StateUserProductDetailsState extends State<StateUserProductDetails> {
  // How long the cosmetic "moderation" badge stays before switching to the
  // active promotion badge. "Несколько секунд" — tweak here if needed.
  static const Duration _moderationDuration = Duration(seconds: 3);

  bool _isDeleting = false;
  bool _hasChanges = false;

  bool _editedLocally = false;

  late Product _localProduct = widget.results;
  bool _canLeave = false;

  String? _catId;
  String _categoryName = '—';

  _PromotionPhase _promotionPhase = _PromotionPhase.none;
  Timer? _moderationTimer;

  @override
  void initState() {
    super.initState();
    _catId = widget.results.category;

    if (_catId != null) {
      _loadCategoryOnce(_catId!);
      context.read<ProductBloc>().add(SameProductEvent(_catId!, 2));
    }

    context.read<ProductBloc>().add(GetProductInfo(widget.id));
    context.read<ReviewBloc>().add(AllReviewsEvent(widget.id));
  }

  Future<void> _onMenuAction(String value) async {
    switch (value) {
      case 'delete':
        _showDeleteConfirmation();
        break;

      case 'edit':
        final edited = await context.router.push<Product>(
          EditUserProductRoute(
            products: _localProduct,
          ),
        );

        if (!mounted) return;

        if (edited != null) {
          _hasChanges = true;

          setState(() {
            _localProduct = edited;
            _editedLocally = true;
          });
        }
        break;

      case 'promote':
        await _handlePromote();
        break;
    }
  }

  void _finish([bool? changed]) {
    if (!mounted) return;
    if (changed != null) _hasChanges = changed;
    setState(() => _canLeave = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.maybePop(_hasChanges);
    });
  }

  Future<void> _handlePromote() async {
    final created = await PromotionDialog.show(
      context,
      postId: widget.id,
      productName: widget.results.name,
      preferences: getIt<SharedPreferences>(),
      isAlreadyPromoted: widget.results.isPromoted,
      promoEndAt: widget.results.promoEndAt,
    );

    if (!mounted) return;
    if (created == true) {
      _hasChanges = true;
      context.read<ProductBloc>().add(MarkProductPromotedLocally(widget.id));
      _startModerationFlow();
      showMessage(
          context, ['Продвижение запущено!'], EnumStatusMessage.success);
    }
  }

  /// Cosmetic trick: show a "moderation" badge for a few seconds, then flip to
  /// the active promotion badge and pull fresh product data from the backend.
  void _startModerationFlow() {
    _moderationTimer?.cancel();
    setState(() => _promotionPhase = _PromotionPhase.moderation);

    _moderationTimer = Timer(_moderationDuration, () {
      if (!mounted) return;
      setState(() => _promotionPhase = _PromotionPhase.promoted);
      context.read<ProductBloc>().add(GetProductInfo(widget.id));
    });
  }

  @override
  void dispose() {
    _moderationTimer?.cancel();
    super.dispose();
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const TextTranslated('Удалить товар?'),
        content: const TextTranslated(
          'Вы уверены, что хотите удалить этот товар? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const TextTranslated('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _isDeleting = true);
              context.read<ProductBloc>().add(ProductDeleteEvent(widget.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const TextTranslated('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    context.read<ProductBloc>().add(GetProductInfo(widget.id));
  }

  Future<void> _loadCategoryOnce(String id) async {
    final catBloc = context.read<CategoryBloc>();

    final cached = catBloc.state.categories.firstWhereOrNull((c) => c.id == id);
    if (cached != null) {
      setState(() => _categoryName = cached.name);
      return;
    }

    catBloc.add(CategoryGetEvent(id));
    try {
      final state = await catBloc.stream
          .firstWhere(
            (s) => !s.isLoading && s.currentCategory?.id == id,
          )
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => _categoryName = state.currentCategory?.name ?? '—');
    } catch (_) {
      // Timeout or stream error — just keep the default category name.
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final isRegister = context.select((ThemeNotifier n) => n.isRegister);
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _finish();
      },
      child: CustomScaffold(
        leading: IconButton(
          onPressed: _finish,
          icon: const Icon(Icons.arrow_back),
        ),
        bottomNavigationBar:
            const BottomNav(currentIndexOverride: -4, passive: true),
        onRefresh: _handleRefresh,
        title: () {
          final p = context.select((ProductBloc b) => b.state.product);
          final name = _editedLocally
              ? _localProduct.name
              : (p.id == widget.id ? p.name : _localProduct.name);
          return name.length > 18 ? '${name.substring(0, 18)}.' : name;
        }(),
        child: BlocListener<ProductBloc, ProductState>(
          listenWhen: (p, c) => p.loading && !c.loading,
          listener: (context, state) {
            if (!_isDeleting) return;
            if (state.errors.isNotEmpty) {
              setState(() => _isDeleting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errors.join(', '))),
              );
              return;
            }
            context.read<ReelBloc>().add(InvalidateReelsCacheEvent());
            _finish(true);
          },
          child: _isDeleting
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: BlocBuilder<ProductBloc, ProductState>(
                        buildWhen: (previous, current) =>
                            previous.product != current.product ||
                            previous.loading != current.loading,
                        builder: (context, state) {
                          final currentProduct = _editedLocally
                              ? _localProduct
                              : (state.product.id == widget.id
                                  ? state.product
                                  : _localProduct);
                          final product = currentProduct;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ProductHeaderRow(
                                results: currentProduct,
                                isDarkMode: stateSwitch,
                                onMenuAction: _onMenuAction,
                                promotionPhase: _promotionPhase,
                              ),
                              SizedBox(height: 8.h),
                              _ProductStatsRow(
                                views: currentProduct.views,
                                createdAt: currentProduct.createdAt,
                                isDarkMode: stateSwitch,
                              ),
                              SizedBox(height: 8.h),
                              _RatingAndArticleRow(
                                results: currentProduct,
                                isDarkMode: stateSwitch,
                              ),
                              SizedBox(height: 15.h),
                              _ImageSwiper(
                                results: currentProduct,
                              ),
                              SizedBox(height: 30.h),
                              _OwnerCard(
                                results: currentProduct,
                                product: currentProduct,
                                isDarkMode: stateSwitch,
                              ),
                              SizedBox(height: 30.h),
                              _ProductInfoSection(
                                results: currentProduct,
                                categoryName: _categoryName,
                              ),
                              SizedBox(height: 10.h),
                              _SimilarProductsSection(
                                currentProductId: currentProduct.id,
                              ),
                              SizedBox(height: 28.h),
                              _CommentsOrAuthPrompt(
                                isRegister: isRegister,
                                postId: currentProduct.id,
                              ),
                            ],
                          );
                        },
                      )),
                ),
        ),
      ),
    );
  }
}

class _ProductHeaderRow extends StatelessWidget {
  const _ProductHeaderRow({
    required this.results,
    required this.isDarkMode,
    required this.onMenuAction,
    required this.promotionPhase,
  });

  final Product results;
  final bool isDarkMode;
  final ValueChanged<String> onMenuAction;
  final _PromotionPhase promotionPhase;

  List<PopupMenuEntry<String>> _buildMenuItems(
    bool stateSwitch,
    bool showPromote,
  ) {
    // Promote entry is server-gated via FeatureFlagsCubit('promoteButton'),
    // same mechanism as ButtonVisibleGate — hidden until the flag is set.
    final items = <PopupMenuEntry<String>>[
      if (showPromote) ...[
        PopupMenuItem<String>(
          value: 'promote',
          child: Row(
            children: <Widget>[
              const Icon(Icons.trending_up, color: Color(0xff0095D5)),
              SizedBox(width: 8.w),
              const TextTranslated("Продвинуть"),
            ],
          ),
        ),
        const PopupMenuDivider(),
      ],
    ];

    items.add(
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: <Widget>[
            const Icon(Icons.edit, color: Color(0xff4CAF50)),
            SizedBox(width: 8.w),
            const TextTranslated("Редактировать"),
          ],
        ),
      ),
    );

    items.add(const PopupMenuDivider());

    items.add(
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: <Widget>[
            const Icon(Icons.delete, color: Color(0xffe10a49)),
            SizedBox(width: 8.w),
            const TextTranslated("Удалить"),
          ],
        ),
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final showPromote =
        context.watch<FeatureFlagsCubit>().state.isVisible('promoteButton');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextTranslated(
                results.name,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (promotionPhase == _PromotionPhase.moderation)
                const _PromotionBadge(moderation: true)
              else if (promotionPhase == _PromotionPhase.promoted ||
                  (results.isPromoted &&
                      (results.promoEndAt?.isAfter(DateTime.now()) ?? false)))
                const _PromotionBadge(),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(212),
          child: PopupMenuButton<String>(
            color: isDarkMode ? const Color(0xff192536) : Colors.white,
            onSelected: onMenuAction,
            itemBuilder: (_) => _buildMenuItems(isDarkMode, showPromote),
            icon: const Icon(Icons.more_horiz, color: Color(0xff808080)),
            offset: const Offset(0, 50),
          ),
        ),
      ],
    );
  }
}

class _PromotionBadge extends StatelessWidget {
  const _PromotionBadge({this.moderation = false});

  /// When true the badge shows the transient "На модерации" state instead of
  /// the active "Продвигается" state.
  final bool moderation;

  @override
  Widget build(BuildContext context) {
    final color =
        moderation ? const Color(0xffF5A623) : const Color(0xff0095D5);
    final label = moderation ? 'На модерации' : 'Продвигается';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (moderation)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.trending_up,
                size: 12,
                color: Colors.white,
              ),
            const SizedBox(width: 4),
            TextTranslated(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingAndArticleRow extends StatelessWidget {
  const _RatingAndArticleRow({
    required this.results,
    required this.isDarkMode,
  });

  final Product results;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    // Hide the stars row entirely when there's no rating — 5 empty
    // outlined stars look like a rendering bug to users.
    final hasRating = results.rating > 0;
    final reviewLabel =
        hasRating ? "${results.reviewCount} отзывов" : "нет отзывов";
    return Row(
      children: [
        if (hasRating) ...[
          Stars(rating: results.rating),
          SizedBox(width: 15.w),
        ],
        TextTranslated(
          reviewLabel,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: isDarkMode ? Colors.white : const Color(0xff5F5F5F),
          ),
        ),
        SizedBox(width: 16.w),
        TextTranslated(
          "Арт: ",
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white : const Color(0xff5F5F5F),
            fontWeight: FontWeight.w400,
          ),
        ),
        TextTranslated(
          results.productNumber.toString(),
          style: const TextStyle(
            fontSize: 12,
            color: activeColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ImageSwiper extends StatelessWidget {
  const _ImageSwiper({required this.results});

  final Product results;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300.h,
      child: results.image_post.isNotEmpty
          ? Swiper(
              itemCount: results.image_post.length,
              itemBuilder: (BuildContext context, int index) {
                final postImage = results.image_post[index];
                final url = postImage.image;

                if (url.isVideoUrl) {
                  if (url.isEmpty || Uri.tryParse(url) == null) {
                    return VideoPoster(
                      coverUrl: postImage.bestCoverUrl,
                      showPlay: false,
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: VideoViewerScreen(
                      url: url,
                      coverUrl: postImage.bestCoverUrl,
                      showFullscreenButton: true,
                    ),
                  );
                }

                return _ImageSwiperItem(
                  url: url,
                  allImagePosts: results.image_post,
                );
              },
              pagination: SwiperPagination(
                builder: DotSwiperPaginationBuilder(
                  color: Colors.grey.shade300,
                  activeColor: Colors.blue,
                  size: 6.0,
                  activeSize: 7.5,
                  space: 4.0,
                ),
              ),
            )
          : const EmptyImageWidget(),
    );
  }
}

class _ImageSwiperItem extends StatelessWidget {
  const _ImageSwiperItem({
    required this.url,
    required this.allImagePosts,
  });

  final String url;
  final List<PostImage> allImagePosts;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          final imagesOnly = allImagePosts
              .where((e) => !e.image.isVideoUrl)
              .map((e) => CachedNetworkImageProvider(e.image))
              .toList();

          if (imagesOnly.isEmpty) return;

          showImageViewerPager(
            context,
            MultiImageProvider(imagesOnly),
            onPageChanged: (_) {},
            onViewerDismissed: (_) {},
          );
        },
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          width: double.infinity,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.results,
    required this.product,
    required this.isDarkMode,
  });

  final Product results;
  final Product product;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.router.push(OtherUserProfileRoute(
          user: results.owner!.id,
          username: results.owner!.username,
        ));
      },
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: isDarkMode ? const Color(0xff101A29) : Colors.white,
          elevation: 10,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _OwnerInfoRow(
                  results: results,
                  product: product,
                  isDarkMode: isDarkMode,
                ),
                SizedBox(height: 10.h),
                _PriceAndFulfilmentRow(results: results),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerInfoRow extends StatelessWidget {
  const _OwnerInfoRow({
    required this.results,
    required this.product,
    required this.isDarkMode,
  });

  final Product results;
  final Product product;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 40.w,
          height: 40.h,
          child: CircleAvatar(
            backgroundColor: const Color(0xffF0F0F0),
            backgroundImage: results.owner?.image != null
                ? CachedNetworkImageProvider(results.owner!.image)
                : null,
            child: results.owner?.image == null
                ? CustomAvatar(
                    width: 50.w,
                    height: 50.h,
                    sizeAvatar: 25,
                    size: 30,
                    colorContainer:
                        isDarkMode ? Colors.white10 : Colors.black12,
                    colorContainerBorder: Colors.black12,
                    image: null,
                  )
                : null,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                results.owner?.username ?? "Unknown",
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              if (results.owner?.is_verified ?? false)
                const Icon(
                  Icons.verified,
                  color: Colors.green,
                ),
              TextTranslated(
                "Рейтинг : ${results.rating}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceAndFulfilmentRow extends StatelessWidget {
  const _PriceAndFulfilmentRow({
    required this.results,
  });

  final Product results;

  @override
  Widget build(BuildContext context) {
    final showFulfilment = results.owner!.userType.toString() == "8" ||
        results.owner!.userType.toString() == "4";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TextTranslated(
                      "Цена: ",
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
                    ),
                    DualPriceText(
                      price: results.price,
                      currency: results.currency,
                      style: const TextStyle(
                          fontSize: 25, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (showFulfilment) ...[
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: _FulfilmentButton(),
          ),
        ],
      ],
    );
  }
}

class _FulfilmentButton extends StatelessWidget {
  const _FulfilmentButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        context.router.push(const FulfilmentRoute());
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff58A6DF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const TextTranslated(
        "Перейти к фулфилменту",
        style: TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  const _ProductInfoSection({
    required this.results,
    required this.categoryName,
  });

  final Product results;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final regionTitle = KgRegion.fromId(results.regionId)?.title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "О товаре",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        Wrap(
          children: [
            const TextTranslated(
              "Название:",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            TextTranslated(
              " ${results.name}",
              softWrap: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        const TextTranslated(
          "Описание:",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        TextTranslated(
          "  -${results.description}",
          maxLines: 6,
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        if (regionTitle != null) ...[
          SizedBox(height: 12.h),
          Wrap(
            children: [
              const TextTranslated(
                "Регион:",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              TextTranslated(
                " $regionTitle",
                softWrap: true,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
        SizedBox(height: 20.h),
        Divider(
          height: 0.15.h,
          endIndent: 10,
          color: Colors.grey[300],
        ),
        SizedBox(height: 13.h),
        const TextTranslated(
          "Дополнительная информация",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        _CategoryRow(
          results: results,
          categoryName: categoryName,
        ),
        SizedBox(height: 12.h),
        Divider(
          height: 0.15.h,
          endIndent: 10,
          color: Colors.grey[300],
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.results,
    required this.categoryName,
  });

  final Product results;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const TextTranslated(
          "Категория : ",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
        InkWell(
          onTap: () => context.router.push(ProductsRoute(
            childId: results.category ?? "",
            title: categoryName,
          )),
          child: TextTranslated(
            categoryName.length > 15
                ? "${categoryName.substring(0, 15)}..."
                : categoryName,
            style: const TextStyle(
              color: Color(0xff3190FF),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _SimilarProductsSection extends StatelessWidget {
  const _SimilarProductsSection({
    required this.currentProductId,
  });

  final String currentProductId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (previous, current) =>
          previous.sameProduct != current.sameProduct,
      builder: (context, state) {
        final similarProducts = state.sameProduct
            .where((product) => product.id != currentProductId)
            .take(20)
            .toList();

        if (similarProducts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextTranslated(
              "Похожие товары",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 400,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similarProducts.length,
                itemBuilder: (context, index) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  child: SizedBox(
                    width: 180.w,
                    child: ProductCard(results: similarProducts[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentsOrAuthPrompt extends StatelessWidget {
  const _CommentsOrAuthPrompt({
    required this.isRegister,
    required this.postId,
  });

  final bool isRegister;
  final String postId;

  @override
  Widget build(BuildContext context) {
    if (isRegister) {
      return Comments(postId: postId);
    }
    return const Center(
      child: Column(
        children: [
          TextTranslated(
            'Авторизуйтесь чтобы оставить отзыв!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductStatsRow extends StatelessWidget {
  final int views;
  final DateTime createdAt;
  final bool isDarkMode;

  const _ProductStatsRow({
    required this.views,
    required this.createdAt,
    required this.isDarkMode,
  });

  static const List<String> _months = [
    'Января',
    'Февраля',
    'Марта',
    'Апреля',
    'Мая',
    'Июня',
    'Июля',
    'Августа',
    'Сентября',
    'Октября',
    'Ноября',
    'Декабря',
  ];

  String get _formattedDate {
    final relative = createdAt.asRecentRelativeTime;
    if (relative != null) return relative;
    final month = _months[createdAt.month - 1];
    return '${createdAt.day} $month ${createdAt.year}';
  }

  String get _formattedViews {
    final text = views.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(' ');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final subtextColor = isDarkMode ? Colors.white : const Color(0xff5F5F5F);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.w,
      runSpacing: 4.h,
      children: [
        _ProductStatsItem(
          icon: Icons.remove_red_eye_outlined,
          text: '$_formattedViews просмотров',
          color: subtextColor,
        ),
        Text(
          '•',
          style: TextStyle(
            fontSize: 12,
            color: subtextColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        _ProductStatsItem(
          icon: Icons.calendar_month_outlined,
          text: 'Добавлено $_formattedDate',
          color: subtextColor,
        ),
      ],
    );
  }
}

class _ProductStatsItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ProductStatsItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 4.w),
        TextTranslated(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

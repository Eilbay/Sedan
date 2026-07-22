import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/utils/extensions/video_url_extension.dart';
import 'package:optombai/pages/profile/edit/widgets/video_view_screen.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/data/models/account/user/socials/social_owner.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_card.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage(name: 'ProductDetailsRoute')
class ProductDetails extends StatefulWidget {
  const ProductDetails(
      {super.key,
      required this.results,
      this.postId,
      this.chooseMainType,
      this.isRegistered,
      this.commentId});

  final Product results;
  final String? postId;
  final int? chooseMainType;
  final bool? isRegistered;

  final String? commentId;

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late Product product;

  final _fromKey = GlobalKey<FormState>();
  final ScrollController _detailsScrollController = ScrollController();
  final GlobalKey _similarProductsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    product = widget.results;

    context.read<ProductBloc>().add(GetProductInfo(widget.results.id));
    context.read<ReviewBloc>().add(AllReviewsEvent(widget.results.id));
    context.read<ProductBloc>().add(RegisterPostViewEvent(widget.results.id));

    _recordImpressionIfNeeded();
  }

  @override
  void dispose() {
    _detailsScrollController.dispose();
    super.dispose();
  }

  Future<void> _recordImpressionIfNeeded() async {
    if (!widget.results.isPromoted ||
        !(widget.results.promoEndAt?.isAfter(DateTime.now()) ?? false)) {
      return;
    }

    final currentUser = context.read<UserBloc>().state.user;

    if (widget.results.owner?.id == currentUser.id) {
      return;
    }

    try {
      await getIt<PromotionRepository>().recordImpression(
        widget.results.id,
        'product_details',
      );
    } catch (e) {
      // Impression errors are non-critical, ignore
    }
  }

  FavoriteResult? isLike(List<FavoriteResult> list, String prodId) {
    for (var element in list) {
      if (element.post.id == prodId) {
        return element;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);
    final bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    final String displayTitle = widget.results.name.length > 18
        ? '${widget.results.name.substring(0, 18)}.'
        : widget.results.name;

    final productOwner = widget.results.owner;
    final productOwnerId = productOwner?.id ?? '';
    final isOwnProduct = productOwnerId.isNotEmpty &&
        productOwnerId == context.read<UserBloc>().state.user.id;

    return BlocListener<BlockBloc, BlockState>(
        listenWhen: (prev, curr) =>
            productOwnerId.isNotEmpty &&
            prev.justBlockedUserId != curr.justBlockedUserId &&
            curr.justBlockedUserId == productOwnerId,
        listener: (ctx, _) => ctx.router.maybePop(),
        child: Form(
          key: _fromKey,
          child: CustomScaffold(
            bottomNavigationBar:
                const BottomNav(currentIndexOverride: -1, passive: true),
            title: displayTitle,
            action: (!isRegister || isOwnProduct || productOwnerId.isEmpty)
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Действия',
                      onPressed: () => UserActionsSheet.show(
                        context,
                        userId: productOwnerId,
                        username: productOwner?.username ?? '',
                        reportTargetType: ReportTargetType.post,
                        reportTargetId: widget.results.id.toString(),
                      ),
                    ),
                  ],
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: BlocListener<ProductBloc, ProductState>(
                listenWhen: (prev, curr) => prev.product != curr.product,
                listener: (context, state) {
                  final p = state.product;
                  if (p.category != null) {
                    context
                        .read<ProductBloc>()
                        .add(SameProductEvent(p.category, 2));
                  }
                },
                child: BlocBuilder<ProductBloc, ProductState>(
                  buildWhen: (prev, curr) =>
                      prev.product != curr.product ||
                      prev.products != curr.products ||
                      prev.profileProducts != curr.profileProducts ||
                      prev.isLoading != curr.isLoading,
                  builder: (context, state) {
                    final p = state.product;
                    final realDataReady =
                        p.id == widget.results.id && p.name.isNotEmpty;

                    final hasData =
                        widget.results.name.isNotEmpty || realDataReady;
                    if (!hasData) {
                      return const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: ShimmerProductCard(),
                      );
                    }
                    Product? findFresh(List<Product> list) {
                      for (final x in list) {
                        if (x.id == widget.results.id) return x;
                      }
                      return null;
                    }

                    final fresh = findFresh(state.products) ??
                        findFresh(state.profileProducts) ??
                        findFresh(state.sameProduct) ??
                        findFresh(state.postModel?.results ?? []) ??
                        (state.product.id == widget.results.id
                            ? state.product
                            : null) ??
                        widget.results;

                    final categoryId = p.category;
                    final categoryName = p.categories?.name ?? "—";
                    final r = (p.id == widget.results.id && p.name.isNotEmpty)
                        ? p
                        : widget.results;
                    return SingleChildScrollView(
                      controller: _detailsScrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 14.h),
                            _ImageCarousel(
                              imagePosts: r.image_post,
                              product: r,
                              isRegister: isRegister,
                              isLike: isLike,
                            ),
                            SizedBox(height: 14.h),
                            _PriceViewsRow(
                              price: r.price,
                              currency: r.currency,
                              views: fresh.views,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 14.h),
                            _ProductTitleRow(name: r.name),
                            SizedBox(height: 14.h),
                            _OwnerCardRow(
                              owner: r.owner,
                              chooseMainType: widget.chooseMainType,
                              isRegistered: widget.isRegistered,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 18.h),
                            _DescriptionBlock(description: r.description),
                            SizedBox(height: 16.h),
                            _ContactButtonsRow(
                              owner: r.owner,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 22.h),
                            _FinancingSection(
                              carPrice: r.price ?? 0,
                              currency: r.currency,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 22.h),
                            _AboutProductSection(
                              name: r.name,
                              regionId: r.regionId,
                              owner: r.owner,
                            ),
                            SizedBox(height: 12.h),
                            Divider(
                              height: 0.15.h,
                              endIndent: 10,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 13.h),
                            _AdditionalInfoSection(
                              categoryId: categoryId,
                              categoryName: categoryName,
                            ),
                            SizedBox(height: 12.h),
                            Divider(
                              height: 0.15.h,
                              endIndent: 10,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 10.h),
                            KeyedSubtree(
                              key: _similarProductsKey,
                              child: _SimilarProductsSection(
                                currentProductId: widget.results.id,
                              ),
                            ),
                            SizedBox(height: 28.h),
                            _CommentsSection(
                              isRegister: isRegister,
                              postId: widget.results.id,
                              commentId: widget.commentId,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ));
  }
}

class _PriceViewsRow extends StatelessWidget {
  final double? price;
  final String currency;
  final int views;
  final bool isDarkMode;

  const _PriceViewsRow({
    required this.price,
    required this.currency,
    required this.views,
    required this.isDarkMode,
  });

  static const Color _accent = Color(0xFF2F80ED);

  static String _formatNum(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final currencyLabel = switch (currency.toUpperCase()) {
      'KGS' => 'сом',
      'USD' => '\$',
      _ => currency,
    };

    final hasPrice = price != null && price != 0;
    final priceText =
        hasPrice ? '${_formatNum(price!)} $currencyLabel' : 'Договорная';

    final Color sub = isDarkMode ? Colors.white70 : const Color(0xFF5F5F5F);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            priceText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Icon(Icons.remove_red_eye_outlined, size: 18, color: sub),
        const SizedBox(width: 5),
        Text(
          _formatNum(views),
          style: TextStyle(fontSize: 14, color: sub),
        ),
      ],
    );
  }
}

class _ProductTitleRow extends StatelessWidget {
  final String name;

  const _ProductTitleRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: TextTranslated(
            name,
            softWrap: true,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerCardRow extends StatelessWidget {
  final User? owner;
  final int? chooseMainType;
  final bool? isRegistered;
  final bool isDarkMode;

  const _OwnerCardRow({
    required this.owner,
    required this.chooseMainType,
    required this.isRegistered,
    required this.isDarkMode,
  });

  void _openOwner(BuildContext context) {
    context.router.push(OtherUserProfileRoute(
      username: owner?.username ?? "",
      user: owner?.id ?? "",
      productType: chooseMainType,
      isRegistered: isRegistered,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF14181F) : Colors.white;
    final Color borderColor =
        (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.06);

    return InkWell(
      onTap: () => _openOwner(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44.w,
              height: 44.w,
              child: CircleAvatar(
                backgroundColor: const Color(0xffF0F0F0),
                backgroundImage: owner?.image != null
                    ? CachedNetworkImageProvider(owner!.image!)
                    : null,
                child: owner?.image == null
                    ? CustomAvatar(
                        width: 44.w,
                        height: 44.h,
                        sizeAvatar: 22,
                        size: 24,
                        colorContainer:
                            isDarkMode ? Colors.white10 : Colors.black12,
                        colorContainerBorder: Colors.black12,
                        image: null,
                      )
                    : null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: TextTranslated(
                      owner?.username ?? "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (owner?.is_verified ?? false) ...[
                    SizedBox(width: 5.w),
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF2F80ED),
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right_rounded,
              size: 26,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  final String description;

  const _DescriptionBlock({required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "Описание",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8.h),
        TextTranslated(
          description,
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
      ],
    );
  }
}

class _ContactButtonsRow extends StatelessWidget {
  final User? owner;
  final bool isDarkMode;

  const _ContactButtonsRow({required this.owner, required this.isDarkMode});

  static const Color _accent = Color(0xFF2F80ED);

  SocialOwner? _findWhatsApp() {
    final o = owner;
    if (o == null) return null;
    for (final s in o.socials) {
      if (s.socialType.title.toLowerCase() == 'whatsapp') return s;
    }
    return null;
  }

  Future<void> _openWhatsApp(BuildContext context, SocialOwner wa) async {
    try {
      await launchUrl(
        Uri.parse(wa.socialType.domainUrl + wa.link),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть WhatsApp')),
      );
    }
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось позвонить')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wa = _findWhatsApp();
    final phone = owner?.phone_number.trim() ?? '';
    final hasPhone = phone.isNotEmpty;

    final Color waBg = isDarkMode ? const Color(0xFF14181F) : Colors.white;
    final Color waBorder =
        (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.12);
    final Color waText = isDarkMode ? Colors.white : Colors.black87;

    final buttons = <Widget>[];

    if (wa != null) {
      buttons.add(
        Expanded(
          child: _ActionButton(
            onTap: () => _openWhatsApp(context, wa),
            background: waBg,
            borderColor: waBorder,
            iconWidget: Image.asset(
              'assets/icons/socials_dark/whatsapp_dark.png',
              width: 20.w,
              height: 20.w,
              fit: BoxFit.contain,
              color: const Color(0xFF25D366),
            ),
            label: 'Написать в WhatsApp',
            labelColor: waText,
          ),
        ),
      );
    }

    if (hasPhone) {
      if (buttons.isNotEmpty) buttons.add(SizedBox(width: 10.w));
      buttons.add(
        Expanded(
          child: _ActionButton(
            onTap: () => _call(context, phone),
            background: _accent,
            borderColor: _accent,
            iconWidget: const Icon(Icons.call, color: Colors.white, size: 20),
            label: 'Позвонить',
            labelColor: Colors.white,
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color background;
  final Color borderColor;
  final Widget iconWidget;
  final String label;
  final Color labelColor;

  const _ActionButton({
    required this.onTap,
    required this.background,
    required this.borderColor,
    required this.iconWidget,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 50.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            SizedBox(width: 8.w),
            Flexible(
              child: TextTranslated(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<PostImage> imagePosts;
  final Product product;
  final bool isRegister;
  final FavoriteResult? Function(List<FavoriteResult>, String) isLike;

  const _ImageCarousel({
    required this.imagePosts,
    required this.product,
    required this.isRegister,
    required this.isLike,
  });

  static final Color _overlayColor =
      const Color(0xff89898a).withValues(alpha: 0.3);

  void _showImageViewer(BuildContext context) {
    final imagesOnly = imagePosts
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
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300.h,
      child: Stack(
        children: [
          imagePosts.isNotEmpty
              ? Swiper(
                  itemCount: imagePosts.length,
                  itemBuilder: (BuildContext context, int index) {
                    final postImage = imagePosts[index];
                    final url = postImage.image;

                    if (url.isVideoUrl) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: VideoViewerScreen(
                          url: url,
                          coverUrl: postImage.bestCoverUrl,
                          showFullscreenButton: true,
                          fullscreenButtonRight: 15,
                        ),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => _showImageViewer(context),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          alignment: Alignment.center,
                        ),
                      ),
                    );
                  },
                  pagination: SwiperPagination(
                    builder: DotSwiperPaginationBuilder(
                      color: Colors.grey.shade300,
                      activeColor: const Color(0xFF2F80ED),
                      size: 6.0,
                      activeSize: 7.5,
                      space: 4.0,
                    ),
                  ),
                )
              : const EmptyImageWidget(),
          _FavoriteButton(
            overlayColor: _overlayColor,
            product: product,
            isRegister: isRegister,
            isLike: isLike,
          ),
          _ShareButton(
            overlayColor: _overlayColor,
            product: product,
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final Color overlayColor;
  final Product product;

  const _ShareButton({
    required this.overlayColor,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 65,
      right: 5,
      child: Container(
        margin: const EdgeInsets.all(10),
        width: 50.w,
        height: 45.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: overlayColor,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.share,
            size: 26,
          ),
          onPressed: () {
            // Don't include `product.name` in the share text — receiver
            // apps (WhatsApp, Telegram) auto-render an OG link-preview
            // card off the deeplink which already shows the title.
            // Including it again here duplicates the name.
            final deepLink = 'https://optombai.com/p/${product.id}';
            final description = product.description.trim();
            final text = <String>[
              'Смотри в ',
              if (description.isNotEmpty) description,
              deepLink,
            ].join('\n');
            SharePlus.instance.share(ShareParams(text: text));
          },
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final Color overlayColor;
  final Product product;
  final bool isRegister;
  final FavoriteResult? Function(List<FavoriteResult>, String) isLike;

  const _FavoriteButton({
    required this.overlayColor,
    required this.product,
    required this.isRegister,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (previous, current) => previous.results != current.results,
      builder: (context, state) {
        final favorite = isLike(state.results, product.id);
        final isFavorite = favorite != null;

        return Positioned(
          top: 135,
          right: 5,
          child: Container(
            margin: const EdgeInsets.all(10),
            width: 50.w,
            height: 45.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: overlayColor,
            ),
            child: IconButton(
              icon: isFavorite
                  ? const Icon(
                      Icons.bookmark,
                      color: Color(0xFF2F80ED),
                      size: 30,
                    )
                  : const Icon(
                      Icons.bookmark_border,
                      color: Colors.black,
                      size: 30,
                    ),
              onPressed: () {
                if (!isRegister) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: TextTranslated(
                          'Чтобы добавить продукт в избранные,зарегистрируйтесь'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                if (isFavorite) {
                  context.read<FavoriteBloc>().add(
                        FavoriteDelete(id: favorite.id),
                      );
                } else {
                  context.read<FavoriteBloc>().add(
                        FavoriteCreateEvent(
                          post: product.id,
                          favoriteResult: FavoriteResult(
                            post: product,
                          ),
                        ),
                      );
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _AboutProductSection extends StatelessWidget {
  final String name;
  final int? regionId;
  final User? owner;

  const _AboutProductSection({
    required this.name,
    this.regionId,
    this.owner,
  });

  String? get _marketName {
    final markets = owner?.supplierMarkets ?? const [];
    for (final link in markets) {
      if (link.isActive && link.marketName.trim().isNotEmpty) {
        return link.marketName;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final regionTitle = KgRegion.fromId(regionId)?.title;
    final marketName = _marketName;

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
              " $name",
              softWrap: true,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
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
        if (marketName != null) ...[
          SizedBox(height: 12.h),
          Wrap(
            children: [
              const TextTranslated(
                "Рынок:",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              TextTranslated(
                " $marketName",
                softWrap: true,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AdditionalInfoSection extends StatelessWidget {
  final String? categoryId;
  final String categoryName;

  const _AdditionalInfoSection({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          "Дополнительная информация",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            const TextTranslated(
              "Категория : ",
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
            ),
            InkWell(
              onTap: () => context.router.push(ProductsRoute(
                childId: categoryId ?? "",
                title: categoryName,
              )),
              child: TextTranslated(
                categoryName,
                style: const TextStyle(
                  color: Color(0xff3190FF),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SimilarProductsSection extends StatelessWidget {
  final String currentProductId;

  const _SimilarProductsSection({required this.currentProductId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (prev, curr) => prev.sameProduct != curr.sameProduct,
      builder: (context, state) {
        final similarProducts = state.sameProduct
            .where((product) => product.id != currentProductId)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (similarProducts.isNotEmpty)
              const TextTranslated(
                "Похожие товары",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            SizedBox(height: 10.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  similarProducts.length,
                  (index) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: SizedBox(
                      width: 180.w,
                      height: 350.h,
                      child: ProductCard(results: similarProducts[index]),
                    ),
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

class _CommentsSection extends StatelessWidget {
  final bool isRegister;
  final String postId;
  final String? commentId;

  const _CommentsSection({
    required this.isRegister,
    required this.postId,
    this.commentId,
  });

  @override
  Widget build(BuildContext context) {
    if (isRegister) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 100.h,
          maxHeight: 500.h,
        ),
        child: Comments(postId: postId, scrollToCommentId: commentId),
      );
    }

    return Center(
      child: Column(
        children: [
          const TextTranslated(
            'Авторизуйтесь чтобы оставить отзыв!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _FinancingSection extends StatefulWidget {
  final double carPrice;
  final String currency;
  final bool isDarkMode;

  const _FinancingSection({
    required this.carPrice,
    required this.currency,
    required this.isDarkMode,
  });

  @override
  State<_FinancingSection> createState() => _FinancingSectionState();
}

class _FinancingSectionState extends State<_FinancingSection> {
  static const Color _accent = Color(0xFF2F80ED);
  static const Color _green = Color(0xFF2EB872);

  static const double _downPaymentRate = 0.30;

  int _tab = 2;
  double _termMonths = 60;
  bool _consentAccepted = false;

  double get _bankMarkupRate => 0.20 * (_termMonths / 60);

  String get _currencyLabel => switch (widget.currency.toUpperCase()) {
        'KGS' => 'сом',
        'USD' => '\$',
        _ => widget.currency,
      };

  static String _fmt(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _money(num v) => '${_fmt(v)} $_currencyLabel';

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    final price = widget.carPrice;
    final downPayment = price * _downPaymentRate;
    final financed = price - downPayment;
    final markupRate = _bankMarkupRate;
    final markup = financed * markupRate;
    final totalPayable = financed + markup;
    final monthly = _termMonths > 0 ? totalPayable / _termMonths : 0;

    final Color cardColor = isDark ? const Color(0xFF14181F) : Colors.white;
    final Color border =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final Color subText = isDark ? Colors.white60 : const Color(0xFF7A7A7A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TextTranslated(
          'Ипотека и финансирование',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14181F) : const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _tabButton('Ипотека', 0),
              _tabButton('Лизинг', 1),
              _tabButton('Мурабаха', 2),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BakAiLogo(),
                  SizedBox(height: 4.h),
                  SizedBox(
                    width: 90.w,
                    child: Text(
                      'Ваш инновационный мобильный банк',
                      style: TextStyle(fontSize: 10, color: _accent),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: TextTranslated(
                            'Покупка автомобиля по Мурабаха',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.info_outline, size: 16, color: subText),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _bullet('Соответствует нормам шариата'),
                    _bullet('Фиксированная наценка'),
                    _bullet('Прозрачные условия'),
                    _bullet('Срок финансирования до 20 лет.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: TextTranslated(
                      'Калькулятор Мурабаха',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.edit_outlined, size: 18, color: subText),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child:
                        _field('Стоимость автомобиля', _money(price), subText),
                  ),
                  Expanded(
                    child: _field(
                      'Первоначальный взнос',
                      '${(_downPaymentRate * 100).round()}%   ${_money(downPayment)}',
                      subText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                      child:
                          _field('Сумма Мурабаха', _money(financed), subText)),
                  Expanded(
                    child: _field(
                      'Наценка банка',
                      '${(markupRate * 100).toStringAsFixed(1)}%   ${_money(markup)}',
                      subText,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                      child: _field(
                          'Сумма к оплате', _money(totalPayable), subText)),
                  Expanded(
                      child: _field(
                          'Срок', '${_termMonths.round()} мес.', subText)),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: TextTranslated(
                        'Ежемесячный платёж',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _money(monthly),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              const TextTranslated(
                'Срок Мурабаха, месяцы',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _accent,
                  inactiveTrackColor: _accent.withValues(alpha: 0.2),
                  thumbColor: _accent,
                  overlayColor: _accent.withValues(alpha: 0.15),
                  trackHeight: 4,
                ),
                child: Slider(
                  min: 12,
                  max: 60,
                  divisions: 48,
                  value: _termMonths,
                  onChanged: (v) => setState(() => _termMonths = v),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('12 мес.',
                      style: TextStyle(fontSize: 12, color: subText)),
                  Text('60 мес.',
                      style: TextStyle(fontSize: 12, color: subText)),
                ],
              ),
              SizedBox(height: 18.h),
              InkWell(
                onTap: () {
                  setState(() {
                    _consentAccepted = !_consentAccepted;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: Checkbox(
                          value: _consentAccepted,
                          onChanged: (value) {
                            setState(() {
                              _consentAccepted = value ?? false;
                            });
                          },
                          activeColor: _accent,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: _consentAccepted
                                ? _accent
                                : isDark
                                    ? Colors.white38
                                    : const Color(0xFF9AA4B2),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF8A94A3),
                            ),
                            children: const [
                              TextSpan(
                                text: 'Я даю согласие на передачу и обработку ',
                              ),
                              TextSpan(
                                text: 'персональных данных',
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(text: ' в целях '),
                              TextSpan(
                                text: 'автофинансирования',
                                style: TextStyle(
                                  color: _accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _consentAccepted
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Заявка на автофинансирование'),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    disabledBackgroundColor: isDark
                        ? const Color(0xFF253247)
                        : const Color(0xFFD5DCE6),
                    foregroundColor: Colors.white,
                    disabledForegroundColor:
                        isDark ? Colors.white38 : const Color(0xFF98A2B3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const TextTranslated(
                    'Подать заявку',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? (widget.isDarkMode ? const Color(0xFF0E1420) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active ? Border.all(color: _accent, width: 1.4) : null,
          ),
          child: TextTranslated(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? _accent
                  : (widget.isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 14, color: _green),
          const SizedBox(width: 6),
          Expanded(
            child: TextTranslated(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String value, Color subText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(
          label,
          style: TextStyle(fontSize: 11, color: subText),
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _BakAiLogo extends StatelessWidget {
  const _BakAiLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_balance, color: Color(0xFFE5234B), size: 20),
        const SizedBox(width: 4),
        Text.rich(
          TextSpan(
            children: const [
              TextSpan(
                text: 'Bak',
                style: TextStyle(
                  color: Color(0xFFE5234B),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: 'Ai',
                style: TextStyle(
                  color: Color(0xFF2F80ED),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

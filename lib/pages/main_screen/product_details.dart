import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/models/region/kg_region.dart';
import 'package:optombai/utils/extensions/iso_date_extension.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/utils/extensions/string_validation_extension.dart';
import 'package:optombai/utils/extensions/video_url_extension.dart';
import 'package:optombai/pages/profile/edit/widgets/video_view_screen.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/core/di/injection.dart';
import 'package:optombai/features/promotion/domain/repository/promotion_repository.dart';
import 'package:optombai/widgets/product/dual_price_text.dart';
import 'package:optombai/widgets/shimmer/shimmer_product_card.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/bloc/chat_bloc/chat_bloc.dart';
import 'package:optombai/data/models/chat/linked_post.dart';
import 'package:optombai/bloc/message_bloc/message_bloc.dart';
import 'package:optombai/bloc/language_bloc/extensions/translation_context_extension.dart';
import 'package:optombai/core/appColors.dart';

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

  /// Optional comment/review id to scroll to (best-effort) when opened from a
  /// "new comment" notification.
  final String? commentId;

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late Product product;

  final _fromKey = GlobalKey<FormState>();
  final TextEditingController _sellerMessageController =
      TextEditingController();
  final ScrollController _detailsScrollController = ScrollController();
  final GlobalKey _similarProductsKey = GlobalKey();

  bool _isSellerQuickBarVisible = true;

  static const List<String> _quickSellerMessages = [
    'Здравствуйте! Ещё актуально?',
    'Здравствуйте! Я заинтересован!',
    'Здравствуйте! Есть ли доставка?',
    'Здравствуйте! За сколько отдадите?',
  ];

  @override
  void initState() {
    super.initState();
    product = widget.results;

    _detailsScrollController.addListener(_updateSellerQuickBarVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSellerQuickBarVisibility();
    });

    context.read<ProductBloc>().add(GetProductInfo(widget.results.id));
    context.read<ReviewBloc>().add(AllReviewsEvent(widget.results.id));
    context.read<ProductBloc>().add(RegisterPostViewEvent(widget.results.id));

    _recordImpressionIfNeeded();
  }

  @override
  void dispose() {
    _detailsScrollController.removeListener(_updateSellerQuickBarVisibility);
    _detailsScrollController.dispose();
    _sellerMessageController.dispose();
    super.dispose();
  }

  void _updateSellerQuickBarVisibility() {
    if (!mounted) return;

    final similarContext = _similarProductsKey.currentContext;
    if (similarContext == null) {
      if (!_isSellerQuickBarVisible) {
        setState(() => _isSellerQuickBarVisible = true);
      }
      return;
    }

    final renderBox = similarContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final top = renderBox.localToGlobal(Offset.zero).dy;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final hideTriggerY = screenHeight / 2.5;

    final shouldShow = top > hideTriggerY;
    if (shouldShow != _isSellerQuickBarVisible) {
      setState(() => _isSellerQuickBarVisible = shouldShow);
    }
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

  int? choseMain = 2;

  Future<void> _sendMessageToSeller(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    // `isAgree` is stale on most legacy accounts — gating sends valid
    // logged-in users to the auth screen for no reason. Auth check now
    // relies solely on the registration flag.
    final bool isRegister = context.read<ThemeNotifier>().isRegister;

    if (!isRegister) {
      if (!mounted) return;
      debugPrint('[AUTH] product details gate -> sign in');
      context.router.push(const SignInRoute());
      return;
    }

    final targetUserId = widget.results.owner?.id;
    final currentUserId = context.read<UserBloc>().state.user.id;

    // Guard against missing or malformed ids. Backend `POST /chat/start/`
    // rejects non-UUID `user_id` with a 400 "Must be a valid UUID." that
    // would otherwise surface to the user as a confusing raw error.
    if (targetUserId == null || !targetUserId.isValidUuid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить продавца')),
      );
      return;
    }

    if (targetUserId == currentUserId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя отправить сообщение самому себе')),
      );
      return;
    }

    final chatBloc = context.read<ChatBloc>();
    chatBloc.add(
      CreatePersonalChatEvent(targetUserId, productId: widget.results.id),
    );

    try {
      final chatState = await chatBloc.stream.firstWhere((s) {
        final hasChatForUser = s.chats.any(
          (c) => c.participants.any((p) => p.id == targetUserId),
        );
        return !s.isLoading && (hasChatForUser || s.errors.isNotEmpty);
      }).timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (chatState.errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chatState.errors.join(', '))),
        );
        return;
      }

      final chat = chatState.chats.firstWhere(
        (c) => c.participants.any((p) => p.id == targetUserId),
        orElse: () => chatState.chats.first,
      );

      context.read<MessageBloc>().add(
            SendMessageEvent(
              chatId: chat.id,
              text: text,
            ),
          );

      _sellerMessageController.clear();

      final linkedPost = LinkedPost(
        id: widget.results.id,
        title: widget.results.name,
        imageUrl: widget.results.image_post.isNotEmpty
            ? widget.results.image_post.first.image
            : null,
        price: widget.results.price,
        currency: widget.results.currency,
      );

      context.router.push(
        ChatConversationRoute(chat: chat, linkedPost: linkedPost),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось отправить сообщение')),
      );
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardInset > 0;
    final showSellerQuickBar = _isSellerQuickBarVisible || isKeyboardOpen;
    final String displayTitle = widget.results.name.length > 18
        ? '${widget.results.name.substring(0, 18)}.'
        : widget.results.name;

    final productOwner = widget.results.owner;
    final productOwnerId = productOwner?.id ?? '';
    final isOwnProduct = productOwnerId.isNotEmpty &&
        productOwnerId == context.read<UserBloc>().state.user.id;

    return BlocListener<BlockBloc, BlockState>(
        // When this product's author gets blocked, leave the detail screen and
        // return to the feed — which refetches without the blocked author.
        listenWhen: (prev, curr) =>
            productOwnerId.isNotEmpty &&
            prev.justBlockedUserId != curr.justBlockedUserId &&
            curr.justBlockedUserId == productOwnerId,
        listener: (ctx, _) => ctx.router.maybePop(),
        child: Form(
          key: _fromKey,
          child: CustomScaffold(
            bottomNavigationBar: showSellerQuickBar
                ? Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: SafeArea(
                      top: false,
                      child: _SellerQuickChatBar(
                        controller: _sellerMessageController,
                        quickMessages: _quickSellerMessages,
                        onSend: _sendMessageToSeller,
                      ),
                    ),
                  )
                : const BottomNav(currentIndexOverride: -1, passive: true),
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

                    // Show shimmer only when we have no displayable data yet:
                    // - normal nav: widget.results already has full data, never shimmer
                    // - chat nav (stub): shimmer until GetProductInfo returns
                    // Do NOT shimmer for SameProduct loading (it reuses isLoading flag)
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
                    // Use freshly loaded product from bloc when available
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
                            SizedBox(height: 16.h),
                            _ProductTitleRow(name: r.name),
                            SizedBox(height: 8.h),
                            _ProductStatsRow(
                              views: fresh.views,
                              createdAt: r.createdAt,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 8.h),
                            _ProductMetaRow(
                              rating: fresh.rating,
                              reviewCount: fresh.reviewCount,
                              productNumber: r.productNumber,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 15.h),
                            _OwnerInfoRow(
                              owner: r.owner,
                              chooseMainType: widget.chooseMainType,
                              isRegistered: widget.isRegistered,
                              isDarkMode: stateSwitch,
                            ),
                            SizedBox(height: 15.h),
                            _ImageCarousel(
                              imagePosts: r.image_post,
                              product: r,
                              isRegister: isRegister,
                              isLike: isLike,
                            ),
                            SizedBox(height: 30.h),
                            _PriceSection(
                              owner: r.owner,
                              price: r.price,
                              currency: r.currency,
                              chooseMainType: widget.chooseMainType,
                              isRegistered: widget.isRegistered,
                            ),
                            SizedBox(height: 30.h),
                            _AboutProductSection(
                              name: r.name,
                              description: r.description,
                              regionId: r.regionId,
                              owner: r.owner,
                            ),
                            SizedBox(height: 9.h),
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

class _SellerQuickChatBar extends StatelessWidget {
  final TextEditingController controller;
  final List<String> quickMessages;
  final ValueChanged<String> onSend;

  const _SellerQuickChatBar({
    required this.controller,
    required this.quickMessages,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select((ThemeNotifier n) => n.isDarkMode);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 4.h),
      color: isDarkMode ? const Color(0xFF1A1A1A) : AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickMessages.length,
              separatorBuilder: (_, __) => SizedBox(width: 5.w),
              itemBuilder: (context, index) {
                final text = quickMessages[index];
                return InkWell(
                  onTap: () async {
                    final translated = await context.translateText(text);
                    onSend(translated);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xff22E07B),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: TextTranslated(
                        text,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xff2d3348) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xff49506b)
                          : const Color(0xffd4d8e5),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: onSend,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hint: TextTranslated(
                        'Спросить продавца',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 7.h,
                      ),
                    ),
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ),
              SizedBox(width: 7.w),
              BlocBuilder<MessageBloc, MessageState>(
                buildWhen: (prev, curr) => prev.isSending != curr.isSending,
                builder: (context, state) {
                  return InkWell(
                    onTap:
                        state.isSending ? null : () => onSend(controller.text),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: const BoxDecoration(
                        color: Color(0xff8C93A9),
                        shape: BoxShape.circle,
                      ),
                      child: state.isSending
                          ? Padding(
                              padding: EdgeInsets.all(9.w),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductTitleRow extends StatelessWidget {
  final String name;

  const _ProductTitleRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: TextTranslated(
            name,
            softWrap: true,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
        Text(
          '•',
          style: TextStyle(
            fontSize: 12,
            color: subtextColor,
            fontWeight: FontWeight.w400,
          ),
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
        Icon(
          icon,
          size: 16.sp,
          color: color,
        ),
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

class _ProductMetaRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final int? productNumber;
  final bool isDarkMode;

  const _ProductMetaRow({
    required this.rating,
    required this.reviewCount,
    required this.productNumber,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final subtextColor = isDarkMode ? Colors.white : const Color(0xff5F5F5F);

    // Hide stars row entirely at rating=0 — 5 empty outlined stars
    // look like a rendering bug. Show only the textual label.
    return Row(
      children: [
        if (rating > 0) ...[
          Stars(rating: rating),
          SizedBox(width: 15.w),
        ],
        TextTranslated(
          reviewCount == 0 ? "нет отзывов" : "$reviewCount отзывов",
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: subtextColor,
          ),
        ),
        SizedBox(width: 16.w),
        TextTranslated(
          "Арт: ",
          style: TextStyle(
            fontSize: 12,
            color: subtextColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        TextTranslated(
          productNumber.toString(),
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

class _OwnerInfoRow extends StatelessWidget {
  final User? owner;
  final int? chooseMainType;
  final bool? isRegistered;
  final bool isDarkMode;

  const _OwnerInfoRow({
    required this.owner,
    required this.chooseMainType,
    required this.isRegistered,
    required this.isDarkMode,
  });

  void _navigateToOwnerProfile(BuildContext context) {
    context.router.push(OtherUserProfileRoute(
      username: owner?.username ?? "",
      user: owner?.id ?? "",
      productType: chooseMainType,
      isRegistered: isRegistered,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => _navigateToOwnerProfile(context),
          child: SizedBox(
            width: 40.w,
            height: 40.h,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2.w,
                  color: Colors.transparent,
                ),
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xffF0F0F0),
                backgroundImage: owner?.image != null
                    ? CachedNetworkImageProvider(owner!.image!)
                    : null,
                child: owner?.image == null
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
          ),
        ),
        SizedBox(width: 6.w),
        Flexible(
          child: InkWell(
            onTap: () => _navigateToOwnerProfile(context),
            child: TextTranslated(
              owner?.username ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        SizedBox(width: 5.w),
        if (owner?.is_verified ?? false)
          const Icon(
            Icons.verified,
            color: Colors.green,
          ),
        SizedBox(width: 15.w),
        TextTranslated(
          "Рейтинг : ${owner?.rating ?? 0}",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        SizedBox(width: 35.w),
      ],
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
                      activeColor: Colors.blue,
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
                      color: Color(0xFF7B2FF2),
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

class _PriceSection extends StatelessWidget {
  final User? owner;
  final double? price;
  final String currency;
  final int? chooseMainType;
  final bool? isRegistered;

  const _PriceSection({
    required this.owner,
    required this.price,
    required this.currency,
    required this.chooseMainType,
    required this.isRegistered,
  });

  @override
  Widget build(BuildContext context) {
    final showFulfilment =
        chooseMainType.toString() == "8" || chooseMainType.toString() == "4";

    return InkWell(
      onTap: () {
        context.router.push(OtherUserProfileRoute(
          username: owner?.username ?? "",
          user: owner?.id ?? "",
          productType: chooseMainType,
          isRegistered: isRegistered,
        ));
      },
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                child: DualPriceText(
                  price: price,
                  currency: currency,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              if (showFulfilment)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutProductSection extends StatelessWidget {
  final String name;
  final String description;
  final int? regionId;
  final User? owner;

  const _AboutProductSection({
    required this.name,
    required this.description,
    this.regionId,
    this.owner,
  });

  /// The seller's active market link, if any — the "Рынок" row is shown
  /// only for sellers actually attached to a market.
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
        SizedBox(height: 12.h),
        const TextTranslated(
          "Описание:",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        TextTranslated(
          description,
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

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/data/models/report/report_target_type.dart';
import 'package:optombai/pages/profile/edit/widgets/media_tile.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/moderation/user_actions_sheet.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/block_bloc/block_bloc.dart';
import 'package:optombai/bloc/document_bloc/document_bloc.dart';
import 'package:optombai/bloc/image_bloc/image_bloc.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/store_review_bloc/store_review_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/configs/app_color.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/app_scaffold/custom_scaffold.dart';
import 'package:optombai/widgets/product/details/comments.dart';
import 'package:optombai/widgets/profile/about_us/profile_about_us.dart';
import 'package:optombai/widgets/profile/profile_header.dart';
import 'package:optombai/widgets/profile/second_header.dart';
import 'package:optombai/widgets/utils/card/empty_product_card.dart';
import 'package:optombai/widgets/shimmer/shimmer_profile_grid.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

@RoutePage(name: 'OtherUserProfileRoute')
class OtherUserProfile extends StatefulWidget {
  const OtherUserProfile(
      {super.key,
      required this.user,
      this.productType,
      this.isRegistered,
      this.flagName,
      required this.username});

  final String user;
  final int? productType;
  final bool? isRegistered;
  final String? flagName;
  final String username;

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  int currentIndex = 0;
  int? choseMain = 2;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    BlocProvider.of<ProductBloc>(context)
        .add(GetProfileProductsEvent(widget.username));
    BlocProvider.of<StoreReviewBloc>(context)
        .add(AllStoreReviewEvent(widget.user));
    BlocProvider.of<ImageBloc>(context).add(GetAllImage(widget.user));
    BlocProvider.of<DocumentBloc>(context)
        .add(GetAllDocumentImage(widget.user));
    BlocProvider.of<UserBloc>(context).add(UserOtherEvent(widget.user));
    BlocProvider.of<UserBloc>(context)
        .add(UserOtherWithoutTokenEvent(widget.user));

    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.pixels <
        _controller.position.maxScrollExtent - 200) {
      return;
    }
    final bloc = context.read<ProductBloc>();
    final s = bloc.state;
    if (s.isLoadingProfileMore || !s.hasMoreProfileProducts) return;
    bloc.add(FetchMoreProfileProductsEvent(widget.username));
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.select((ThemeNotifier n) => n.isDarkMode);
    var bloc = context.select((UserBloc b) => b.state.otherUser);
    var blocWithoutToken =
        context.select((UserBloc b) => b.state.otherUserWithoutToken);
    final notFound = context.select((UserBloc b) => b.state.otherUserNotFound);
    final blockedByThem =
        context.select((UserBloc b) => b.state.otherUserBlockedByThem);
    bool isRegister = context.select((ThemeNotifier n) => n.isRegister);
    var stateUser = context.read<UserBloc>().state.user;
    bool isCurrentUser2 = false;

    final currentUserId = stateUser.id;
    final isSelfProfile = currentUserId == widget.user;
    debugPrint(
      '[PROFILE_OTHER] build isRegister=$isRegister isSelfProfile=$isSelfProfile '
      'currentUserId=$currentUserId targetUser=${widget.user} '
      'productType=${widget.productType}',
    );

    // Refetch the profile when this user's block status changes locally
    // (block OR unblock). Without this `widget.currentUser.isBlockedByMe`
    // stays stale after a block via UserActionsSheet, so the "Написать"
    // button remains visible and pressing it triggers a 403 BLOCKED
    // snackbar from the server.
    return BlocListener<BlockBloc, BlockState>(
      listenWhen: (prev, curr) {
        final blockToggled = prev.justBlockedUserId != curr.justBlockedUserId &&
            curr.justBlockedUserId == widget.user;
        final unblockToggled =
            prev.justUnblockedUserId != curr.justUnblockedUserId &&
                curr.justUnblockedUserId == widget.user;
        return blockToggled || unblockToggled;
      },
      listener: (ctx, state) {
        ctx.read<UserBloc>().add(UserOtherEvent(widget.user));
        ctx
            .read<ProductBloc>()
            .add(GetProfileProductsEvent(widget.username, forceRefresh: true));
        ctx.read<BlockBloc>().add(const ResetBlockStatusEvent());
      },
      // The backend hides unreachable profiles two ways: 403 code=BLOCKED
      // when the target blocked the viewer, and 404 when the profile is
      // deleted. Show the matching explanatory stub instead of an empty
      // profile — and if the viewer is the one who blocked them, expose an
      // unblock shortcut.
      child: (blockedByThem || notFound)
          ? _NotFoundProfileScaffold(
              userId: widget.user,
              username: widget.username,
              blockedByThem: blockedByThem,
            )
          : _buildLoadedProfile(
              context: context,
              bloc: bloc,
              blocWithoutToken: blocWithoutToken,
              isRegister: isRegister,
              stateUser: stateUser,
              isCurrentUser2: isCurrentUser2,
              isSelfProfile: isSelfProfile,
            ),
    );
  }

  Widget _buildLoadedProfile({
    required BuildContext context,
    required User bloc,
    required User blocWithoutToken,
    required bool isRegister,
    required User stateUser,
    required bool isCurrentUser2,
    required bool isSelfProfile,
  }) {
    return DefaultTabController(
      length: 3,
      child: Form(
        key: _formKey,
        child: CustomScaffold(
            bottomNavigationBar: const BottomNav(
              currentIndexOverride: -1,
              passive: true,
            ),
            title: '',
            // Block/report need an account — hide the actions menu for guests
            // and on the own profile.
            action: (isSelfProfile || !isRegister)
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Действия',
                      onPressed: () => UserActionsSheet.show(
                        context,
                        userId: widget.user,
                        username: widget.username,
                        reportTargetType: ReportTargetType.user,
                        reportTargetId: widget.user,
                      ),
                    ),
                  ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  child: Column(children: [
                    SizedBox(
                      height: 20.h,
                    ),
                    _BlockedByMeBanner(
                      userId: widget.user,
                      serverFlag: bloc.isBlockedByMe,
                    ),
                    BlocBuilder<ProductBloc, ProductState>(
                      buildWhen: (previous, current) =>
                          previous.profileProducts != current.profileProducts ||
                          previous.profileProductsTotalCount !=
                              current.profileProductsTotalCount,
                      builder: (context, productState) {
                        final int postCounts =
                            productState.profileProductsTotalCount;
                        final headerKind = !isRegister
                            ? 'SecondHeader:guest'
                            : ((widget.productType == 0 ||
                                        widget.productType == 16) &&
                                    stateUser.userStatus!.isPremium == false)
                                ? 'SecondHeader:non_premium'
                                : 'ProfileHeader';
                        debugPrint(
                          '[PROFILE_OTHER] header=$headerKind postCounts=$postCounts',
                        );
                        if (!isRegister) {
                          return SecondHeader(
                            currentUser: blocWithoutToken,
                            isCurrentUser: isCurrentUser2,
                            postCounts: postCounts,
                          );
                        } else if ((widget.productType == 0 ||
                                widget.productType == 16) &&
                            stateUser.userStatus!.isPremium == false) {
                          return SecondHeader(
                            currentUser: bloc,
                            isCurrentUser: isCurrentUser2,
                            postCounts: postCounts,
                          );
                        } else {
                          return ProfileHeader(
                            currentUser: bloc,
                            isCurrentUser: isCurrentUser2,
                            postCounts: postCounts,
                          );
                        }
                      },
                    ),
                    TabBar(
                        dividerColor: Colors.transparent,
                        labelColor: activeColor,
                        overlayColor:
                            WidgetStateProperty.all(Colors.transparent),
                        indicatorColor: activeColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        onTap: (index) {
                          setState(() {
                            currentIndex = index;
                          });
                        },
                        tabs: const [
                          Tab(
                            text: "Товары",
                          ),
                          Tab(
                            text: "О нас",
                          ),
                          Tab(
                            text: "Отзывы",
                          ),
                        ]),
                    Builder(builder: (_) {
                      if (currentIndex == 0) {
                        return BlocBuilder<ProductBloc, ProductState>(
                          buildWhen: (previous, current) =>
                              previous.profileProducts !=
                                  current.profileProducts ||
                              previous.isLoading != current.isLoading,
                          builder: (context, state) {
                            // Gate the shimmer on the profile list being empty —
                            // not on the shared `isLoading` flag, which any other
                            // ProductBloc operation (catalog/search/product info)
                            // flips while it loads, flickering the profile grid.
                            if (state.isLoading &&
                                state.profileProducts.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: ShimmerProfileGrid(itemCount: 6),
                              );
                            }
                            if (state.profileProducts.isEmpty) {
                              return Column(
                                children: [
                                  SizedBox(
                                    height: 30.h,
                                  ),
                                  EmptyProductCard(
                                    title:
                                        'В разделе “Продукты” пока что пусто! ',
                                    subTitle: "",
                                    width: 350.w,
                                    height: 180.h,
                                    image: "assets/icons/korzinka.png",
                                  ),
                                  SizedBox(
                                    height: 20.h,
                                  )
                                ],
                              );
                            }
                            // Render whenever profile products exist. Don't gate
                            // on the shared `isSuccess` flag — unrelated catalog/
                            // search operations on the global ProductBloc set it
                            // false while loading, which hid an already-loaded
                            // profile grid until a manual pull-to-refresh.
                            if (state.profileProducts.isNotEmpty) {
                              final ownerProducts = state.profileProducts;

                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 150,
                                          mainAxisSpacing: 5,
                                          childAspectRatio: 1 / 1,
                                          crossAxisSpacing: 5,
                                        ),
                                        itemCount: ownerProducts.length,
                                        itemBuilder: (BuildContext ctx, index) {
                                          final product = ownerProducts[index];
                                          return RepaintBoundary(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: GestureDetector(
                                                onTap: () {
                                                  context.router.push(
                                                    ProductDetailsRoute(
                                                      chooseMainType:
                                                          widget.productType,
                                                      results: product,
                                                    ),
                                                  );
                                                },
                                                child: product
                                                        .image_post.isNotEmpty
                                                    ? MediaTile(
                                                        url: product.image_post
                                                            .first.image,
                                                        coverUrl: product
                                                            .image_post
                                                            .first
                                                            .bestCoverUrl)
                                                    : const EmptyImageWidget(),
                                              ),
                                            ),
                                          );
                                        }),
                                  ),
                                  if (state.isLoadingProfileMore)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                        );
                      } else if (currentIndex == 1) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const TextTranslated(
                                "О нас",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(
                                height: 19.h,
                              ),
                              AboutUsWidget(
                                userId: widget.user,
                                isCurrentUser: isCurrentUser2,
                                user: bloc,
                              )
                            ],
                          ),
                        );
                      } else if (currentIndex == 2) {
                        return StoreComments(shopId: widget.user);
                      } else {
                        return const SizedBox();
                      }
                    }),
                  ])),
            )),
      ),
    );
  }
}

/// Stub shown when a profile can't be opened. Three cases, by priority:
///  - [blockedByThem]: target blocked the viewer (403 code=BLOCKED) →
///    "Вас заблокировал этот пользователь", no unblock CTA.
///  - viewer blocked the target (local `BlockBloc`) → "Вы заблокировали
///    этого пользователя" + unblock CTA. (Rare via this stub: blocking
///    someone keeps their profile readable — 200 — so this mainly covers
///    the brief optimistic-block window before the refetch.)
///  - otherwise (404): the profile is deleted → "Пользователь не найден".
class _NotFoundProfileScaffold extends StatelessWidget {
  final String userId;
  final String username;
  final bool blockedByThem;

  const _NotFoundProfileScaffold({
    required this.userId,
    required this.username,
    this.blockedByThem = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBlockedByMe = !blockedByThem &&
        context.select((BlockBloc b) => b.state.blockedIds.contains(userId));
    final isMutating = context.select((BlockBloc b) => b.state.isMutating);

    final String message;
    if (blockedByThem) {
      message = 'Вас заблокировал этот пользователь';
    } else if (isBlockedByMe) {
      message = 'Вы заблокировали этого пользователя';
    } else {
      message = 'Пользователь не найден';
    }

    return CustomScaffold(
      bottomNavigationBar: const BottomNav(
        currentIndexOverride: -1,
        passive: true,
      ),
      title: '',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                (blockedByThem || isBlockedByMe)
                    ? Icons.block
                    : Icons.person_off_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16.h),
              TextTranslated(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (username.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  '@$username',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
              SizedBox(height: 24.h),
              if (isBlockedByMe)
                ElevatedButton.icon(
                  onPressed: isMutating
                      ? null
                      : () {
                          context
                              .read<BlockBloc>()
                              .add(UnblockUserEvent(userId: userId));
                        },
                  icon: const Icon(Icons.lock_open),
                  label: const TextTranslated('Разблокировать'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact banner rendered on top of a blocked user's profile.
/// Shows "you blocked this user" + an unblock CTA so the viewer can
/// see the full profile but understands why interactions (chat etc.)
/// are restricted. Reacts to BlockBloc.isMutating to disable the
/// button while the unblock request is in flight.
///
/// Visibility combines the server-side `is_blocked_by_me` flag with
/// the local `BlockBloc.blockedIds` so the banner toggles instantly
/// on block/unblock, without waiting for the profile refetch.
class _BlockedByMeBanner extends StatelessWidget {
  final String userId;
  final bool serverFlag;

  const _BlockedByMeBanner({required this.userId, required this.serverFlag});

  @override
  Widget build(BuildContext context) {
    final localFlag =
        context.select((BlockBloc b) => b.state.blockedIds.contains(userId));
    if (!serverFlag && !localFlag) return const SizedBox.shrink();
    final isMutating = context.select((BlockBloc b) => b.state.isMutating);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h), //
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.block, color: Colors.orange, size: 20),
          SizedBox(width: 10.w),
          const Expanded(
            child: TextTranslated(
              'Вы заблокировали этого пользователя',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: isMutating
                ? null
                : () => context
                    .read<BlockBloc>()
                    .add(UnblockUserEvent(userId: userId)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const TextTranslated(
              'Разблокировать',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

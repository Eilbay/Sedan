import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/bloc/review_bloc/review_bloc.dart';
import 'package:optombai/configs/app_style.dart';
import 'package:optombai/data/models/review/review_model.dart';
import 'package:optombai/widgets/product/details/comment_stars.dart';
import 'package:optombai/widgets/product/details/stars.dart';
import 'package:optombai/widgets/product/details/custom_review_card.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/card/empty_product_card.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/store_review_bloc/store_review_bloc.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/store_review/store_review_model.dart';
import 'package:optombai/widgets/utils/message_show.dart';

class Comments extends StatefulWidget {
  final String postId;

  /// When set, the matching review is scrolled into view once after the list
  /// loads (best-effort — silently skipped if no review has this id).
  final String? scrollToCommentId;

  const Comments({super.key, required this.postId, this.scrollToCommentId});

  @override
  State<Comments> createState() => _CommentsState();
}

class _CommentsState extends State<Comments> {
  int starIndex = 0;
  final _formKey = GlobalKey<FormState>();
  bool _shouldValidate = false;
  final TextEditingController _textEditingController = TextEditingController();

  // Anchor on the targeted review + one-shot guard for the scroll attempt.
  final GlobalKey _commentAnchorKey = GlobalKey();
  bool _didTryScroll = false;

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _maybeScrollToComment(List<ReviewResult> list) {
    if (_didTryScroll) return;
    final target = widget.scrollToCommentId;
    if (target == null || target.isEmpty) return;
    if (!list.any((r) => r.id.toString() == target)) return;

    _didTryScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _commentAnchorKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextTranslated(
            "Оцените покупку",
            style: AppTextStyle.productDetailsText,
          ),
          SizedBox(
            height: 8.h,
          ),
          Row(
            children: [
              ReviewStars(
                active: 1 <= starIndex,
                callback: () {
                  setState(() {
                    starIndex = 1;
                  });
                },
              ),
              ReviewStars(
                active: 2 <= starIndex,
                callback: () {
                  setState(() {
                    starIndex = 2;
                  });
                },
              ),
              ReviewStars(
                active: 3 <= starIndex,
                callback: () {
                  setState(() {
                    starIndex = 3;
                  });
                },
              ),
              ReviewStars(
                active: 4 <= starIndex,
                callback: () {
                  setState(() {
                    starIndex = 4;
                  });
                },
              ),
              ReviewStars(
                active: 5 <= starIndex,
                callback: () {
                  setState(() {
                    starIndex = 5;
                  });
                },
              )
            ],
          ),
          SizedBox(
            height: 15.h,
          ),
          const TextTranslated(
            "Напишите свой отзыв",
            style: AppTextStyle.productDetailsText,
          ),
          SizedBox(
            height: 8.h,
          ),
          CustomReviewTextField(
            shouldValidate: _shouldValidate,
            hintText: 'Напишите свой отзыв о товаре',
            controller: _textEditingController,
            icon: BlocConsumer<ReviewBloc, ReviewState>(
              listenWhen: (prev, curr) =>
                  prev.errors != curr.errors ||
                  (!prev.isSuccess && curr.isSuccess),
              listener: (context, state) {
                if (state.errors.isNotEmpty) {
                  showMessage(
                      context, ["Произошла ошибка"], EnumStatusMessage.error);
                  return;
                }
                if (state.isSuccess) {
                  // The review is now persisted server-side — refresh this
                  // post's aggregated counters (rating, review_count) so the
                  // details header, feed card and profile reflect it. Doing
                  // this synchronously right after dispatching the create event
                  // refetched stale numbers (the POST was still in flight).
                  context
                      .read<ProductBloc>()
                      .add(RefreshSingleProduct(widget.postId));
                  context.read<ProductBloc>().add(GetProductInfo(widget.postId));
                }
              },
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (starIndex == 0) {
                      showMessage(context, ["Пожалуйста, оцените покупку"],
                          EnumStatusMessage.error);
                      return;
                    }
                    if (!_formKey.currentState!.validate()) {
                      setState(() {
                        _shouldValidate = false;
                      });
                      return;
                    }
                    BlocProvider.of<ReviewBloc>(context).add(ReviewCreateEvent(
                        review: ReviewResult(
                            post: widget.postId,
                            review: _textEditingController.text,
                            stars: starIndex)));

                    // Counters are refreshed in the listener above, once the
                    // create actually succeeds — not here, where the POST is
                    // still in flight and a refetch would read stale numbers.
                    setState(() {
                      _textEditingController.clear();
                      starIndex = 0;
                    });
                  },
                );
              },
            ),
          ),
          SizedBox(
            height: 30.h,
          ),
          BlocBuilder<ReviewBloc, ReviewState>(
            buildWhen: (previous, current) =>
                previous.list != current.list ||
                previous.isLoading != current.isLoading,
            builder: (context, state) {
              if (state.isLoading) {
                return spinkit;
              }
              if (state.list.isEmpty) {
                return Center(
                    child: EmptyComment(
                  subTitle: 'Отзывов пока что нет!',
                  image: 'assets/empty_comment.png',
                  height: 180.h,
                ));
              }
              _maybeScrollToComment(state.list);
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.list.length,
                itemBuilder: (BuildContext context, int index) {
                  final review = state.list[index];
                  final isTarget =
                      review.id.toString() == widget.scrollToCommentId;
                  final card = CustomReviewCard(
                    userComments: review,
                    child: Stars(
                      rating: (review.stars ?? 0).roundToDouble(),
                    ),
                  );
                  return isTarget
                      ? KeyedSubtree(key: _commentAnchorKey, child: card)
                      : card;
                },
              );
            },
          ),
          SizedBox(
            height: 30.h,
          ),
        ],
      ),
    );
  }
}

class StoreComments extends StatefulWidget {
  final String shopId;
  final StoreReviewResult? existingReview;

  const StoreComments({super.key, required this.shopId, this.existingReview});

  @override
  State<StoreComments> createState() => _StoreCommentsState();
}

class _StoreCommentsState extends State<StoreComments> {
  int starIndex = 0;
  final _formKey = GlobalKey<FormState>();
  bool _shouldValidate = false;

  final TextEditingController _textEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _textEditingController.text = widget.existingReview!.review;
      starIndex = widget.existingReview!.stars ?? 0;
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userId = context.read<UserBloc>().state.user.id;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userId != widget.shopId)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextTranslated(
                  "Оцените магазин",
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(
                  height: 8.h,
                ),
                Row(
                  children: [
                    ReviewStars(
                      active: 1 <= starIndex,
                      callback: () {
                        setState(() {
                          starIndex = 1;
                        });
                      },
                    ),
                    ReviewStars(
                      active: 2 <= starIndex,
                      callback: () {
                        setState(() {
                          starIndex = 2;
                        });
                      },
                    ),
                    ReviewStars(
                      active: 3 <= starIndex,
                      callback: () {
                        setState(() {
                          starIndex = 3;
                        });
                      },
                    ),
                    ReviewStars(
                      active: 4 <= starIndex,
                      callback: () {
                        setState(() {
                          starIndex = 4;
                        });
                      },
                    ),
                    ReviewStars(
                      active: 5 <= starIndex,
                      callback: () {
                        setState(() {
                          starIndex = 5;
                        });
                      },
                    )
                  ],
                ),
                SizedBox(
                  height: 15.h,
                ),
                const TextTranslated(
                  "Напишите свой отзыв",
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(
                  height: 10.h,
                ),
                CustomReviewTextField(
                  shouldValidate: _shouldValidate,
                  controller: _textEditingController,
                  hintText: 'Напишите свой отзыв о магазине',
                  icon: BlocConsumer<StoreReviewBloc, StoreReviewState>(
                    listener: (context, state) {
                      if (state.errors.isNotEmpty) {
                        showMessage(context, ["Произошла ошибка"],
                            EnumStatusMessage.error);
                      }
                    },
                    builder: (context, state) {
                      return IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          if (starIndex == 0) {
                            showMessage(
                                context,
                                ["Пожалуйста, оцените покупку"],
                                EnumStatusMessage.error);
                            return;
                          }
                          if (!_formKey.currentState!.validate()) {
                            setState(() {
                              _shouldValidate = false;
                            });
                            return;
                          }
                          BlocProvider.of<StoreReviewBloc>(context).add(
                              StoreReviewCreateEvent(
                                  review: StoreReviewResult(
                                      shop: widget.shopId,
                                      review: _textEditingController.text,
                                      stars: starIndex)));
                          // Refresh seller profile so the aggregated
                          // rating + reviews_count in the header update
                          // immediately, not on the next manual reload.
                          context
                              .read<UserBloc>()
                              .add(UserOtherEvent(widget.shopId));
                          setState(() {
                            _textEditingController.clear();
                            starIndex = 0;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          SizedBox(
            height: 15.h,
          ),
          const TextTranslated(
            "Все отзывы",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            height: 20.h,
          ),
          BlocBuilder<StoreReviewBloc, StoreReviewState>(
            buildWhen: (previous, current) =>
                previous.list != current.list ||
                previous.isLoading != current.isLoading,
            builder: (context, state) {
              var list = state.list;

              if (state.isLoading) {
                return spinkit;
              }
              if (list.isEmpty) {
                return Column(
                  children: [
                    Center(
                        child: EmptyComment(
                      subTitle: 'Отзывов пока что нет!',
                      image: 'assets/empty_comment.png',
                      height: 180.h,
                    )),
                    SizedBox(
                      height: 50.h,
                    )
                  ],
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.list.length,
                itemBuilder: (BuildContext context, int index) {
                  return CustomStoreReviewCard(
                    userComments: state.list[index],
                    child: Stars(
                      rating: (state.list[index].stars ?? 0).roundToDouble(),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(
            height: 20.h,
          ),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/bloc/review_bloc/review_bloc.dart';
import 'package:optombai/bloc/store_review_bloc/store_review_bloc.dart';
import 'package:optombai/data/models/review/review_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';
import 'package:optombai/widgets/utils/fields/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/product_bloc/product_bloc.dart';
import 'package:optombai/utils/extensions/iso_date_extension.dart';
import 'package:optombai/bloc/user_bloc/user_bloc.dart';
import 'package:optombai/data/models/store_review/store_review_model.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';
import 'package:optombai/widgets/utils/message_show.dart';

ReviewModel review = const ReviewModel();

class CustomReviewCard extends StatefulWidget {
  const CustomReviewCard(
      {super.key, this.child, this.post_id, required this.userComments});

  final Widget? child;
  final String? post_id;
  final ReviewResult userComments;

  @override
  State<CustomReviewCard> createState() => _CustomReviewCard();
}

class _CustomReviewCard extends State<CustomReviewCard> {
  final GlobalKey _menuKey = GlobalKey();
  bool isEditing = false;
  final bool isLoading = false;

  late final TextEditingController reviewController;
  late int currentRating;

  @override
  void initState() {
    super.initState();
    reviewController = TextEditingController(text: widget.userComments.review);
    currentRating = widget.userComments.stars ?? 0;
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  void deleteComment() {
    context
        .read<ReviewBloc>()
        .add(ReviewDeleteEvent(id: widget.userComments.id));
  }

  @override
  Widget build(BuildContext context) {
    final displayFormater = widget.userComments.created_at.asShortDate;

    final userId = context.read<UserBloc>().state.user.id;
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        _ReviewAvatar(
          imageUrl: widget.userComments.user?.image,
          isDarkMode: stateSwitch,
        ),
        SizedBox(width: 20.w),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(child: widget.child),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ReviewHeaderRow(
                    username: (widget.userComments.user?.username.isNotEmpty ?? false)
                        ? widget.userComments.user!.username
                        : "no username",
                    formattedDate: displayFormater,
                    useScrollable: true,
                  ),
                  if (userId == widget.userComments.user?.id)
                    _ReviewPopupMenu(
                      menuKey: _menuKey,
                      isDarkMode: stateSwitch,
                      onEdit: () => setState(() => isEditing = true),
                      onDelete: () => _showDeleteDialog(context, stateSwitch),
                    ),
                ],
              ),
              if (isEditing)
                _ReviewEditForm(
                  currentRating: currentRating,
                  onRatingChanged: (rating) =>
                      setState(() => currentRating = rating),
                  controller: reviewController,
                  onSubmit: () {
                    BlocProvider.of<ReviewBloc>(context).add(
                      UpdateReviewEvent(
                        review: ReviewResult(
                          post: widget.userComments.post,
                          id: widget.userComments.id,
                          review: reviewController.text,
                          stars: currentRating,
                        ),
                      ),
                    );
                    setState(() => isEditing = false);
                  },
                )
              else
                _ReviewTextContent(text: widget.userComments.review),
            ],
          ),
        )
      ]),
    );
  }

  void _showDeleteDialog(BuildContext context, bool stateSwitch) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _DeleteConfirmationDialog(
          isDarkMode: stateSwitch,
          onDelete: () {
            deleteComment();
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }
}

class CustomStoreReviewCard extends StatefulWidget {
  const CustomStoreReviewCard(
      {super.key, this.child, this.shop_id, required this.userComments});

  final Widget? child;
  final String? shop_id;
  final StoreReviewResult userComments;

  @override
  State<CustomStoreReviewCard> createState() => _CustomStoreReviewCardState();
}

class _CustomStoreReviewCardState extends State<CustomStoreReviewCard> {
  final GlobalKey _menuKey = GlobalKey();
  bool isEditing = false;
  bool isLoading = false;

  late final TextEditingController reviewController;
  late int currentRating = 0;

  @override
  void initState() {
    super.initState();
    reviewController = TextEditingController(text: widget.userComments.review);
    currentRating = widget.userComments.stars ?? 0;
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  void deleteStoreComment() {
    context
        .read<StoreReviewBloc>()
        .add(StoreReviewDeleteEvent(id: widget.userComments.id));
  }

  @override
  Widget build(BuildContext context) {
    final displayFormater = widget.userComments.created_at.asShortDate;
    final userId = context.read<UserBloc>().state.user.id;
    final stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _ReviewAvatar(
            imageUrl: widget.userComments.user?.image,
            isDarkMode: stateSwitch,
          ),
          SizedBox(width: 20.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(child: widget.child),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ReviewHeaderRow(
                      username: widget.userComments.user?.username ?? 'no username',
                      formattedDate: displayFormater,
                    ),
                    if (userId == widget.userComments.user?.id)
                      _ReviewPopupMenu(
                        menuKey: _menuKey,
                        isDarkMode: stateSwitch,
                        onEdit: () => setState(() => isEditing = true),
                        onDelete: () =>
                            _showDeleteDialog(context, stateSwitch),
                      ),
                  ],
                ),
                if (isEditing)
                  _ReviewEditForm(
                    currentRating: currentRating,
                    onRatingChanged: (rating) =>
                        setState(() => currentRating = rating),
                    controller: reviewController,
                    onSubmit: () {
                      BlocProvider.of<StoreReviewBloc>(context).add(
                        UpdateStoreReviewEvent(
                          review: StoreReviewResult(
                            shop: widget.userComments.shop,
                            id: widget.userComments.id,
                            review: reviewController.text,
                            stars: currentRating,
                          ),
                        ),
                      );
                      setState(() => isEditing = false);
                    },
                  )
                else
                  _ReviewTextContent(text: widget.userComments.review),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, bool stateSwitch) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _DeleteConfirmationDialog(
          isDarkMode: stateSwitch,
          onDelete: () {
            deleteStoreComment();
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  const _ReviewAvatar({
    required this.imageUrl,
    required this.isDarkMode,
  });

  final String? imageUrl;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 53.w,
      height: 53.h,
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
          backgroundImage:
              imageUrl != null ? CachedNetworkImageProvider(imageUrl!) : null,
          child: imageUrl == null
              ? CustomAvatar(
                  width: 53.w,
                  height: 53.h,
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
    );
  }
}

class _ReviewHeaderRow extends StatelessWidget {
  const _ReviewHeaderRow({
    required this.username,
    required this.formattedDate,
    this.useScrollable = false,
  });

  final String username;
  final String formattedDate;
  final bool useScrollable;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        TextTranslated(
          username,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(width: useScrollable ? 20.w : 15.w),
        TextTranslated(
          formattedDate,
          style: const TextStyle(fontSize: 12, color: Color(0xff808080)),
        ),
      ],
    );

    if (useScrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    return content;
  }
}

class _ReviewPopupMenu extends StatelessWidget {
  const _ReviewPopupMenu({
    required this.menuKey,
    required this.isDarkMode,
    required this.onEdit,
    required this.onDelete,
  });

  final GlobalKey menuKey;
  final bool isDarkMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: isDarkMode ? const Color(0xff192536) : const Color(0xffEAE8EB),
      key: menuKey,
      onSelected: (String value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: <Widget>[
              const Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8.w),
              const TextTranslated("Удалить"),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_horiz, color: Color(0xff808080)),
      offset: Offset.fromDirection(2.0),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog({
    required this.isDarkMode,
    required this.onDelete,
  });

  final bool isDarkMode;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        height: 150.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xff061324) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),
            const TextTranslated(
              'Вы действительно хотите удалить?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15.h),
            BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state.isSuccess) {
                  showMessage(
                    context,
                    ["Успешно"],
                    EnumStatusMessage.success,
                  );
                  Navigator.pop(context);
                }
              },
              builder: (context, state) {
                return CustomButton(
                  borderRadius: 20,
                  isLoading: state.isLoading,
                  title: 'Удалить',
                  onPressed: onDelete,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRatingEditor extends StatelessWidget {
  const _StarRatingEditor({
    required this.currentRating,
    required this.onRatingChanged,
  });

  final int currentRating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () {
            if (currentRating == index + 1) {
              onRatingChanged(index);
            } else {
              onRatingChanged(index + 1);
            }
          },
        );
      }),
    );
  }
}

class _ReviewEditForm extends StatelessWidget {
  const _ReviewEditForm({
    required this.currentRating,
    required this.onRatingChanged,
    required this.controller,
    required this.onSubmit,
  });

  final int currentRating;
  final ValueChanged<int> onRatingChanged;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StarRatingEditor(
          currentRating: currentRating,
          onRatingChanged: onRatingChanged,
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: CustomEditReviewTextField(
            controller: controller,
            inputFormatters: 400,
            onPressed: onSubmit,
          ),
        ),
      ],
    );
  }
}

class _ReviewTextContent extends StatelessWidget {
  const _ReviewTextContent({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextTranslated(
          text,
          maxLines: 6,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

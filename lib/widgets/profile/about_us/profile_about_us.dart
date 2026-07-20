import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/profile/about_us/about_us_card.dart';
import 'package:optombai/widgets/translation/text_translated.dart';

import 'package:optombai/bloc/image_bloc/image_bloc.dart';
import 'package:optombai/widgets/profile/about_us/gallery_about_us.dart';

class AboutUsWidget extends StatefulWidget {
  const AboutUsWidget({
    super.key,
    required this.user,
    required this.isCurrentUser,
    required this.userId,
  });

  final String userId;
  final User user;
  final bool isCurrentUser;

  @override
  State<AboutUsWidget> createState() => _AboutUsWidgetState();
}

class _AboutUsWidgetState extends State<AboutUsWidget> {
  @override
  Widget build(BuildContext context) {
    final bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    Widget emptyBox() {
      return Container(
        width: 190.w,
        height: 190.h,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color:
              stateSwitch ? const Color(0xff101A29) : const Color(0xffEDF3FF),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30.h),
            const Icon(Icons.warning, size: 38),
            SizedBox(height: 5.h),
            const TextTranslated(
              "Пока пуста",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AboutUsCard(
            user: widget.user,
            isCurrentUser: widget.isCurrentUser,
          ),
          const SizedBox(height: 12),
          RequisitesCard(
            user: widget.user,
            isCurrentUser: widget.isCurrentUser,
          ),
          SizedBox(height: 50.h),
          const TextTranslated(
            "Фотографии документов",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 20.h),
          if (widget.isCurrentUser) DocumentImageAboutUs(user: widget.user),
          SizedBox(height: 20.h),
          BlocBuilder<DocumentBloc, DocumentState>(
            buildWhen: (previous, current) =>
                previous.results != current.results ||
                previous.isLoading != current.isLoading,
            builder: (context, state) {
              if (state.isLoading) return spinkit;

              final filtered =
                  state.results.where((e) => e.user == widget.userId).toList();

              if (filtered.isEmpty && !widget.isCurrentUser) {
                return emptyBox();
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 10,
                  childAspectRatio:
                      (MediaQuery.sizeOf(context).width * .2) / 80,
                  crossAxisSpacing: 15,
                ),
                itemCount: filtered.length,
                itemBuilder: (BuildContext ctx, index) {
                  return DocumentImage(
                    results: filtered[index],
                    userId: widget.user.id,
                    isCurrentUser: widget.isCurrentUser,
                    onPressed: () {
                      Navigator.of(context).pop();
                      BlocProvider.of<DocumentBloc>(context)
                          .add(ImageDocumentDelete(id: filtered[index].id));
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 50.h),
          const TextTranslated(
            "Фотографии организации",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 20.h),
          if (widget.isCurrentUser)
            GalleryAboutUs(
              user: widget.user,
            ),
          SizedBox(height: 20.h),
          BlocBuilder<ImageBloc, ImageState>(
            buildWhen: (previous, current) =>
                previous.results != current.results ||
                previous.isLoading != current.isLoading,
            builder: (context, state) {
              if (state.isLoading) return spinkit;

              if (state.results.isEmpty && !widget.isCurrentUser) {
                return emptyBox();
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 10,
                  childAspectRatio:
                      (MediaQuery.sizeOf(context).width * .2) / 80,
                  crossAxisSpacing: 15,
                ),
                itemCount: state.results.length,
                itemBuilder: (BuildContext ctx, index) {
                  return ImageAboutUs(
                    results: state.results[index],
                    userId: widget.user.id,
                    isCurrentUser: widget.isCurrentUser,
                    onPressed: () {
                      BlocProvider.of<ImageBloc>(context)
                          .add(ImageDelete(id: state.results[index].id));
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
          SizedBox(height: 50.h),
        ],
      ),
    );
  }
}

class ImageAboutUs extends StatefulWidget {
  const ImageAboutUs({
    super.key,
    required this.results,
    required this.onPressed,
    required this.userId,
    required this.isCurrentUser,
  });

  final String userId;
  final ImageAboutModel results;
  final VoidCallback onPressed;
  final bool isCurrentUser;

  @override
  State<ImageAboutUs> createState() => _ImageAboutUsState();
}

class _ImageAboutUsState extends State<ImageAboutUs> {
  @override
  Widget build(BuildContext context) {
    final bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        SizedBox(
          width: 190.w,
          height: 190.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image(
              image: CachedNetworkImageProvider(widget.results.file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (widget.isCurrentUser)
          Container(
            margin: const EdgeInsets.all(10),
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
            ),
            child: Center(
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        height: 150.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: stateSwitch
                              ? const Color(0xff061324)
                              : Colors.white,
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
                            CustomButton(
                              title: 'удалить',
                              onPressed: widget.onPressed,
                              borderRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xff323232),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DocumentImage extends StatefulWidget {
  const DocumentImage({
    super.key,
    required this.results,
    required this.onPressed,
    required this.userId,
    required this.isCurrentUser,
  });

  final String userId;
  final DocumentImageModel results;
  final VoidCallback onPressed;
  final bool isCurrentUser;

  @override
  State<DocumentImage> createState() => _DocumentImageState();
}

class _DocumentImageState extends State<DocumentImage> {
  @override
  Widget build(BuildContext context) {
    final bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Stack(
      alignment: Alignment.topRight,
      children: [
        SizedBox(
          width: 190.w,
          height: 190.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image(
              image: CachedNetworkImageProvider(widget.results.file),
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (widget.isCurrentUser)
          Container(
            margin: const EdgeInsets.all(10),
            width: 24.w,
            height: 24.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white,
            ),
            child: Center(
              child: GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        height: 150.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: stateSwitch
                              ? const Color(0xff061324)
                              : Colors.white,
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
                            CustomButton(
                              title: 'удалить',
                              onPressed: widget.onPressed,
                              borderRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xff323232),
                ),
              ),
            ),
          )
        else
          const SizedBox(),
      ],
    );
  }
}

import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/bloc/category_bloc/category_bloc.dart';
import 'package:optombai/data/models/favorite/favorite_model.dart';
import 'package:optombai/core/theme_notifier.dart';
import 'package:optombai/widgets/utils/card/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/widgets/utils/custom_avatar.dart';

class ProviderCard extends StatefulWidget {
  const ProviderCard({
    super.key,
  });

  // final Product results;

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  @override
  void initState() {
    super.initState();
  }

  FavoriteResult? isLike(List<FavoriteResult> list, String prodId) {
    for (var element in list) {
      if (element.post.id == prodId) {
        return element;
      }
    }
    return null;
  }

  bool isFav = false;

  @override
  Widget build(BuildContext context) {
    bool stateSwitch = context.select((ThemeNotifier n) => n.isDarkMode);

    return Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 10,
        color: stateSwitch ? const Color(0xff0e1e33) : Colors.white,
        child: BlocBuilder<CategoryBloc, CategoryState>(
          buildWhen: (previous, current) =>
              previous.categories != current.categories,
          builder: (context, state) {
            return InkWell(
              onTap: () {},
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                      ),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 180.h,
                            child: const ClipRRect(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10),
                                    topRight: Radius.circular(10)),
                                child: EmptyImageWidget()),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 7.h),
                          const Text(
                            "Test Test",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: TextStyle(fontSize: 15),
                          ),
                          const Text(
                            "Description",
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                          ),
                          SizedBox(
                            height: 5.h,
                          ),
                          // FittedBox(
                          //   child: Text(
                          //     "${widget.results.price} USD",
                          //     maxLines: 1,
                          //     overflow: TextOverflow.fade,
                          //     style: const TextStyle(
                          //         fontSize: 16, fontWeight: FontWeight.w600),
                          //   ),
                          // ),
                          SizedBox(
                            height: 10.h,
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 30.w,
                                  height: 30.h,
                                  child: CircleAvatar(
                                      backgroundColor: const Color(0xffF0F0F0),
                                      // backgroundImage:
                                      // widget.results.owner.image != null
                                      //     ? CachedNetworkImageProvider(
                                      //     widget.results.owner.image!)
                                      //     : null,
                                      child: CustomAvatar(
                                        width: 50.w,
                                        height: 50.h,
                                        sizeAvatar: 25,
                                        size: 30,
                                        colorContainer: stateSwitch
                                            ? Colors.white10
                                            : Colors.black12,
                                        colorContainerBorder: Colors.black12,
                                        image: null,
                                      )),
                                ),
                                SizedBox(width: 10.w),
                                InkWell(
                                  onTap: () {
                                    context.router.push(const ProAccountsRoute());
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    width: 70.w,
                                    height: 30.h,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xff63BDFF),
                                          Color(0xff0075FF),
                                          Color(0xff1B68FF)
                                        ],
                                      ),
                                    ),
                                    child: const Text('Premium',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 10)),
                                  ),
                                ),
                                IconButton(
                                  icon: isFav
                                      ? const Icon(
                                          Icons.bookmark,
                                          color: Color(0xFF7B2FF2),
                                        )
                                      : const Icon(
                                          Icons.bookmark_border,
                                        ),
                                  onPressed: () {},
                                )
                                // BlocBuilder<FavoriteBloc, FavoriteState>(
                                //   builder: (context, state) {
                                //     return IconButton(
                                //       icon: isLike(state.results,
                                //           widget.results.id) !=
                                //           null
                                //           ? const Icon(
                                //         Icons.favorite,
                                //         color: Colors.red,
                                //       )
                                //           : const Icon(Icons.favorite_border),
                                //       onPressed: () {
                                //         var favorite = isLike(
                                //             state.results, widget.results.id);
                                //         if (favorite != null) {
                                //           context.read<FavoriteBloc>().add(
                                //             FavoriteDelete(id: favorite.id),
                                //           );
                                //         } else {
                                //           context.read<FavoriteBloc>().add(
                                //             FavoriteCreateEvent(
                                //                 post: widget.results.id,
                                //                 favoriteResult:
                                //                 FavoriteResult(
                                //                     post: widget
                                //                         .results)),
                                //           );
                                //         }
                                //       },
                                //     );
                                //   },
                                // )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}

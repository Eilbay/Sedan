import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:optombai/core/country_flags.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:auto_route/auto_route.dart';
import 'package:optombai/app/router/app_router.dart';

class OrderProductCard extends StatefulWidget {
  final Product order;
  final VoidCallback? onTap;

  const OrderProductCard({
    super.key,
    required this.order,
    this.onTap,
  });

  FavoriteResult? isLike(List<FavoriteResult> list, String prodId) {
    for (var element in list) {
      if (element.post.id == prodId) {
        return element;
      }
    }
    return null;
  }

  @override
  State<OrderProductCard> createState() => _OrderProductCardState();
}

class _OrderProductCardState extends State<OrderProductCard> {
  @override
  void initState() {
    super.initState();
  }

  int _viewsFromBloc(BuildContext context, String id, int fallback) {
    final b = context.select((ProductBloc bloc) => bloc.state);

    Product? find(List<Product> list) {
      for (final p in list) {
        if (p.id == id) return p;
      }
      return null;
    }

    return find(b.postModel?.results ?? [])?.views ??
        find(b.products)?.views ??
        find(b.profileProducts)?.views ??
        find(b.sameProduct)?.views ??
        fallback;
  }

  @override
  Widget build(BuildContext context) {
    _viewsFromBloc(context, widget.order.id, widget.order.views);

    return InkWell(
      onTap: widget.onTap ??
          () {
            context.router.push(OtherUserProfileRoute(
              username: widget.order.owner?.username ?? "",
              user: widget.order.owner?.id ?? "",
            ));
          },
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _OrderInfoColumn(order: widget.order),
            ),
            _OrderImageColumn(
              order: widget.order,
              isLike: widget.isLike,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoColumn extends StatelessWidget {
  final Product order;

  const _OrderInfoColumn({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextTranslated(
          order.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            if (kCountryFlagsExtended
                .containsKey(order.owner?.country?.name))
              Image(
                image: AssetImage(
                    kCountryFlagsExtended[order.owner?.country?.name]!),
                width: 15.w,
              ),
            SizedBox(width: 5.w),
            TextTranslated(
              order.owner?.country?.name ?? "Неизвестно",
              style: const TextStyle(color: Colors.grey),
            ),
            SizedBox(width: 5.w),
            const Text(
              "·",
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(width: 5.w),
            Text(
              DateFormat('dd.MM.yyyy').format(order.createdAt),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 5.h),
        TextTranslated(
          order.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _OrderImageColumn extends StatelessWidget {
  final Product order;
  final FavoriteResult? Function(List<FavoriteResult> list, String prodId)
      isLike;

  const _OrderImageColumn({
    required this.order,
    required this.isLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 100.w,
            height: 100.h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _OrderPreview(
                  url: order.previewUrl,
                ),
                if (order.image_post.isNotEmpty &&
                    order.image_post.first.isVideo)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 5.h),
        BlocBuilder<FavoriteBloc, FavoriteState>(
          buildWhen: (previous, current) =>
              previous.results != current.results,
          builder: (context, state) {
            var favorite = isLike(state.results, order.id);
            return IconButton(
              icon: Icon(
                favorite != null ? Icons.bookmark : Icons.bookmark_border,
                color: favorite != null ? const Color(0xFF7B2FF2) : Colors.grey,
              ),
              onPressed: () {
                if (favorite != null) {
                  context
                      .read<FavoriteBloc>()
                      .add(FavoriteDelete(id: favorite.id));
                } else {
                  context.read<FavoriteBloc>().add(
                        FavoriteCreateEvent(
                          post: order.id,
                          favoriteResult: FavoriteResult(post: order),
                        ),
                      );
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class _OrderPreview extends StatelessWidget {
  final String? url;

  const _OrderPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const Image(
        image: AssetImage('assets/place_holder_order.png'),
        fit: BoxFit.fill,
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      // Decode at display size, not source resolution.
      memCacheWidth: 400,
      fit: BoxFit.cover,
      placeholder: (context, _) => const Image(
        image: AssetImage('assets/place_holder_order.png'),
        fit: BoxFit.fill,
      ),
      errorWidget: (context, _, __) => const Image(
        image: AssetImage('assets/place_holder_order.png'),
        fit: BoxFit.fill,
      ),
    );
  }
}

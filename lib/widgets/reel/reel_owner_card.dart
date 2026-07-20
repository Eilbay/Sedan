import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:optombai/data/models/reel/reel_model.dart';
import 'package:optombai/data/models/region/kg_region.dart';

class ReelOwnerCard extends StatelessWidget {
  final ReelOwner owner;
  final int views;
  final bool isPromoted;

  /// Product/video name (reel's `description`), shown under the views count.
  final String productName;

  const ReelOwnerCard({
    super.key,
    required this.owner,
    required this.views,
    this.isPromoted = false,
    this.productName = '',
  });

  @override
  Widget build(BuildContext context) {
    final supplier = owner.suppliers.isNotEmpty ? owner.suppliers.first : null;
    final regionLabel = KgRegion.fromId(owner.regionId)?.title;

    return GestureDetector(
      onTap: () {
        context.router.push(OtherUserProfileRoute(
          user: owner.id,
          username: owner.username,
        ));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2,
                  ),
                  image: owner.image != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(owner.image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                // Same no-photo placeholder as user cards (CustomAvatar) for
                // visual consistency, instead of a generic person icon.
                child: owner.image == null
                    ? ClipOval(
                        child: Image.asset(
                          'assets/icons/profile.png',
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.username,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          if (regionLabel != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (owner.country?.squareFlag != null)
                  Text(
                    owner.country!.squareFlag!,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                if (owner.country?.squareFlag != null) SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    regionLabel,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (regionLabel != null) SizedBox(height: 6.h),
          if (supplier != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 12.sp,
                ),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    supplier.market.name,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          if (supplier != null) SizedBox(height: 6.h),
          if (owner.isVerified)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 12.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Проверено',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          if (owner.isVerified) SizedBox(height: 6.h),
          // Row(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [
          //     Icon(
          //       Icons.play_arrow,
          //       color: Colors.white.withValues(alpha: 0.7),
          //       size: 12.sp,
          //     ),
          //     SizedBox(width: 4.w),
          //     TextTranslated(
          //       '${views.toCompactFormat()} просмотров',
          //       style: TextStyle(
          //         fontSize: 10.sp,
          //         color: Colors.white.withValues(alpha: 0.9),
          //       ),
          //     ),
          //   ],
          // ),
          if (productName.trim().isNotEmpty) ...[
            SizedBox(height: 6.h),
            _ExpandableDescription(text: productName.trim()),
          ],
          if (isPromoted) SizedBox(height: 8.h),
          if (isPromoted)
            Text(
              'Реклама',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({required this.text});

  final String text;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const int _collapsedMaxLines = 2;
  bool _expanded = false;

  /// Collapsed text ending in "…". `TextOverflow.ellipsis` only draws its
  /// ellipsis when the last visible line is clipped by width; when the
  /// maxLines cut lands on a hard line break (\n) Flutter drops the rest
  /// silently (long-standing engine limitation). So we cut at the last
  /// character the laid-out painter actually shows and append "…" ourselves
  /// — the same approach readmore/expandable_text packages use internally.
  String _ellipsized(TextPainter laidOutPainter) {
    final cutoff = laidOutPainter
        .getPositionForOffset(
            Offset(laidOutPainter.width, laidOutPainter.height))
        .offset
        .clamp(0, widget.text.length);
    return '${widget.text.substring(0, cutoff).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.25,
    );
    final moreStyle = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w700,
      color: Colors.white.withValues(alpha: 0.6),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _expanded = !_expanded),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;

          final tp = TextPainter(
            text: TextSpan(text: widget.text, style: baseStyle),
            maxLines: _collapsedMaxLines,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: maxWidth);

          final overflows = tp.didExceedMaxLines;

          if (_expanded || !overflows) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Short (non-overflowing) text still gets a trailing "…" so
                // every reel description ends the same way.
                Text(
                  _expanded ? widget.text : '${widget.text}…',
                  style: baseStyle,
                  maxLines: _expanded ? null : _collapsedMaxLines,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                ),
                if (_expanded && overflows)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text('свернуть', style: moreStyle),
                  ),
              ],
            );
          }

          return Text(
            _ellipsized(tp),
            style: baseStyle,
            maxLines: _collapsedMaxLines,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}

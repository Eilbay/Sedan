import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/app/router/app_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:optombai/data/models/banner/settings_banners_model.dart';
import 'package:optombai/widgets/product/banner_slide.dart';
import 'package:optombai/widgets/product/slider_dots_indicator.dart';
import 'package:optombai/utils/extensions/url_string_extension.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
  });

  final List<BannerModel> banners;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const double _sliderHeight = 130.0;
  static const double _dotSize = 6.0;
  static const double _activeDotSize = 8.0;
  static const double _dotSpacing = 4.0;

  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final slides = widget.banners
        .map(
          (banner) => BannerSlide(
            imageUrl: banner.mobile,
            onTap: () => _openBanner(context, banner),
          ),
        )
        .toList();

    final activeSlideCount = slides.length;

    return Column(
      children: [
        SizedBox(
          height: _sliderHeight,
          child: CarouselSlider(
            items: slides,
            carouselController: _carouselController,
            options: CarouselOptions(
              height: _sliderHeight,
              viewportFraction: 1,
              enableInfiniteScroll: true,
              autoPlay: true,
              scrollPhysics: const BouncingScrollPhysics(),
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ),
        SizedBox(height: 6.h),
        SliderDotsIndicator(
          itemCount: activeSlideCount,
          carouselController: _carouselController,
          currentIndex: _currentIndex,
          dotSize: _dotSize,
          activeDotSize: _activeDotSize,
          dotSpacing: _dotSpacing,
          activeColor: const Color(0xff58A6DF),
          inactiveColor: const Color(0xff8AD8FF),
        ),
      ],
    );
  }

  Future<void> _openBanner(
    BuildContext context,
    BannerModel banner,
  ) async {
    if (banner.linkType == BannerLinkType.external) {
      final rawUrl = banner.externalUrl?.trim();
      if (rawUrl == null || rawUrl.isEmpty) return;

      final uri = Uri.tryParse(rawUrl.ensureHttpsPrefix());
      if (uri == null) return;

      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final userId = banner.user.trim();
    if (userId.isEmpty) return;

    context.router.push(OtherUserProfileRoute(
      user: userId,
      username: banner.username ?? '',
    ));
  }
}

class BannerFallback extends StatelessWidget {
  const BannerFallback({super.key});

  static const double _sliderHeight = 200.0;
  static const double _slideBorderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _sliderHeight,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_slideBorderRadius),
        child: Image.asset(
          'assets/demoda2.png',
          width: double.infinity,
          height: _sliderHeight,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}

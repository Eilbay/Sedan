import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:optombai/bloc/banner_bloc/banner_bloc.dart';
import 'package:optombai/data/models/banner/settings_banners_model.dart';
import 'package:optombai/widgets/product/banner_carousel.dart';
import 'package:optombai/widgets/shimmer/shimmer_banner.dart';

class CustomSlider extends StatelessWidget {
  const CustomSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerBloc, BannerState>(
      buildWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      builder: (context, state) {
        if (state is BannerLoading) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: ShimmerBanner(),
          );
        }

        if (state is BannerSuccess && state.list.isNotEmpty) {
          final List<BannerModel> banners =
              state.list.where((item) => item.mobile.isNotEmpty).toList();

          if (banners.isEmpty) {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BannerCarousel(banners: banners),
          );
        }

        return const SizedBox();
      },
    );
  }
}

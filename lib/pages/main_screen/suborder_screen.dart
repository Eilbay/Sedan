import 'package:auto_route/auto_route.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/pages/main_screen/order_screen.dart';
import 'package:optombai/widgets/app_scaffold/bazarlar_app_scaffold.dart';
import 'package:optombai/widgets/bottom_nav.dart';
import 'package:optombai/widgets/promotion/maybe_promoted_card.dart';
import 'package:optombai/widgets/promotion/promotion_placement.dart';

@RoutePage(name: 'OrderStatusRoute')
class OrderStatusScreen extends StatefulWidget {
  final String categoryId;

  const OrderStatusScreen({super.key, required this.categoryId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final ScrollController _scrollController = ScrollController();
  String? search;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      context.read<ProductBloc>().add(ProductPageEvent());
    }
  }

  void _fetchProducts() {
    context.read<ProductBloc>().add(ProductWithFilter(
          search: search,
          category: widget.categoryId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BazarlarAppScaffold(
      bottomNavigationBar:
          const BottomNav(currentIndexOverride: -1, passive: true),
      onRefresh: () async {
        final bloc = context.read<ProductBloc>();
        bloc.add(ProductWithFilter(
          search: search,
          category: widget.categoryId,
          forceRefresh: true,
        ));
        await bloc.stream
            .firstWhere((s) => !s.isLoading)
            .timeout(const Duration(seconds: 10), onTimeout: () => bloc.state);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
          child: Column(
            children: [
              CustomSearchField(
                onChange: (value) {
                  setState(() => search = value);
                  _fetchProducts();
                },
              ),
              SizedBox(height: 30.h),
              if (search != null && search!.isNotEmpty)
                BlocBuilder<ProductBloc, ProductState>(
                  buildWhen: (previous, current) =>
                      previous.products != current.products ||
                      previous.isLoading != current.isLoading,
                  builder: (context, state) {
                    if (state.isLoading && state.products.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.products.isEmpty) {
                      return const Text("Ничего не найдено");
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        return MaybePromotedCard(
                          postId: product.id,
                          isPromoted: product.isPromoted,
                          promoEndAt: product.promoEndAt,
                          placement: PromotionPlacement.main,
                          child: AbsorbPointer(
                            absorbing: true,
                            child: OrderProductCard(order: product),
                          ),
                        );
                      },
                    );
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text(
                    "Введите артикул, чтобы отследить статус фулфилмента вашего товара",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

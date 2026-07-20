import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_event.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_state.dart';
import 'package:optombai/data/models/account/user/user.dart';
import 'package:optombai/data/models/market/market_model.dart';
import 'package:optombai/widgets/translation/text_translated.dart';
import 'package:optombai/widgets/utils/buttons/custom_button.dart';

class MarketRequestBlock extends StatefulWidget {
  final User user;
  const MarketRequestBlock({super.key, required this.user});

  @override
  State<MarketRequestBlock> createState() => _MarketRequestBlockState();
}

class _MarketRequestBlockState extends State<MarketRequestBlock> {
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    context.read<SupplierMarketBloc>().add(
        SupplierMarketInit(widget.user.id, username: widget.user.username));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierMarketBloc, SupplierMarketState>(
      builder: (context, state) {
        if (state.isLoading && state.markets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.errors.isNotEmpty) {
          return TextTranslated(
            state.errors.first,
            style: const TextStyle(color: Colors.red),
          );
        }

        if (state.hasApproved) {
          return TextTranslated(
            'Вы участник рынка «${state.approvedMarket!.name}»',
            style: const TextStyle(fontWeight: FontWeight.w600),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextTranslated(
                'Если вы являетесь поставщиком рынка, отправьте заявку на добавление в рынок.',
              ),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Выбор рынка',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<MarketModel>(
                    isExpanded: true,
                    value: state.selectedMarket,
                    items: state.markets
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: TextTranslated(m.name),
                            ))
                        .toList(),
                    onChanged: (m) {
                      if (m != null) {
                        context
                            .read<SupplierMarketBloc>()
                            .add(SupplierMarketSelect(m));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (state.isPending)
                const TextTranslated(
                  'На модерации\nПосле одобрения вы будете привязаны к рынку.',
                ),
              if (state.isRejected)
                const TextTranslated(
                  'В заявке отказано. Вы можете отправить запрос повторно.',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              if (state.canSendRequest)
                CustomButton(
                  title: state.isRejected
                      ? 'Отправить запрос снова'
                      : 'Отправить запрос',
                  onPressed: () {
                    context
                        .read<SupplierMarketBloc>()
                        .add(const SupplierMarketSendRequest());
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

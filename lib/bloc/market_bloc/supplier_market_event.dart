import 'package:equatable/equatable.dart';
import 'package:optombai/data/models/market/market_model.dart';

abstract class SupplierMarketEvent extends Equatable {
  const SupplierMarketEvent();
}

class SupplierMarketInit extends SupplierMarketEvent {
  final String userId;
  final String? username;
  const SupplierMarketInit(this.userId, {this.username});

  @override
  List<Object?> get props => [userId, username];
}

class SupplierMarketSelect extends SupplierMarketEvent {
  final MarketModel market;
  const SupplierMarketSelect(this.market);

  @override
  List<Object?> get props => [market];
}

class SupplierMarketSendRequest extends SupplierMarketEvent {
  const SupplierMarketSendRequest();

  @override
  List<Object?> get props => [];
}

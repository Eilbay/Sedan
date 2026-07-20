import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_event.dart';
import 'package:optombai/bloc/market_bloc/supplier_market_state.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/data/models/market/market_model.dart';
import 'package:optombai/data/repositories/i_market_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupplierMarketBloc
    extends Bloc<SupplierMarketEvent, SupplierMarketState> {
  final IMarketRepository _repository;
  final SharedPreferences preferences;

  SupplierMarketBloc({required IMarketRepository repository, required this.preferences})
      : _repository = repository,
        super(const SupplierMarketState()) {
    on<SupplierMarketInit>(_init);
    on<SupplierMarketSelect>(_select);
    on<SupplierMarketSendRequest>(_sendRequest);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? '';

  Future<void> _init(
    SupplierMarketInit event,
    Emitter<SupplierMarketState> emit,
  ) async {
    if (state.markets.isNotEmpty) return;

    emit(state.copyWith(isLoading: true, errors: []));

    try {
      final markets = await _repository.getMarkets();

      final username = event.username;
      if (username == null || username.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          markets: markets,
          approvedMarket: null,
          lastRequest: null,
          selectedMarket: null,
        ));
        return;
      }

      final token = getToken();
      if (token.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          markets: markets,
          approvedMarket: null,
          lastRequest: null,
          selectedMarket: null,
        ));
        return;
      }

      final supplier = await _repository.getSupplierByUsername(token, username);

      MarketModel? approvedMarket;
      if (supplier != null) {
        approvedMarket = MarketModel.fromJson(supplier['market']);
      }

      SupplierRequestModel? lastRequest;
      if (approvedMarket == null) {
        final reqs = await _repository.getMySupplierRequests(token);
        if (reqs.isNotEmpty) lastRequest = reqs.last;
      }

      MarketModel? selectedMarket;
      if (lastRequest != null &&
          lastRequest.status == SupplierRequestStatus.pending) {
        selectedMarket = lastRequest.market;
      }

      emit(state.copyWith(
        isLoading: false,
        markets: markets,
        approvedMarket: approvedMarket,
        lastRequest: lastRequest,
        selectedMarket: selectedMarket,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }

  void _select(
    SupplierMarketSelect event,
    Emitter<SupplierMarketState> emit,
  ) {
    emit(state.copyWith(selectedMarket: event.market));
  }

  Future<void> _sendRequest(
    SupplierMarketSendRequest event,
    Emitter<SupplierMarketState> emit,
  ) async {
    final selected = state.selectedMarket;
    if (selected == null) return;
    if (state.hasApproved) return;

    final last = state.lastRequest;
    if (last != null &&
        last.status == SupplierRequestStatus.pending &&
        last.market.id == selected.id) {
      return;
    }

    emit(state.copyWith(isLoading: true, errors: []));

    try {
      await _repository.createSupplierRequest(getToken(), selected.id);

      final reqs = await _repository.getMySupplierRequests(getToken());
      final lastReq = reqs.isNotEmpty ? reqs.last : null;

      emit(state.copyWith(
        isLoading: false,
        lastRequest: lastReq,
        selectedMarket: selected,
      ));
    } on AppException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errors: e.messages,
      ));
    }
  }
}

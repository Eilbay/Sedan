import 'package:optombai/bloc/subscription_bloc/subscription_event.dart';
import 'package:optombai/bloc/subscription_bloc/subscription_state.dart';
import 'package:optombai/configs/constrants.dart';
import 'package:optombai/core/error/app_exception.dart';
import 'package:optombai/core/import_links.dart';
import 'package:optombai/data/repositories/i_subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final ISubscriptionRepository _repository;
  final SharedPreferences preferences;

  SubscriptionBloc({required ISubscriptionRepository repository, required this.preferences})
      : _repository = repository,
        super(SubscriptionLoading()) {
    on<FetchSubscriptionEvent>(_onFetchSubscription);
  }

  String getToken() => preferences.getString(TOKEN_KEY) ?? "";

  Future<void> _onFetchSubscription(
      FetchSubscriptionEvent event, Emitter<SubscriptionState> emit) async {
    emit(SubscriptionLoading());
    try {
      final plans = await _repository.fetchPlans(token: getToken());
      emit(SubscriptionLoaded(plans: plans));
    } on AppException catch (e) {
      emit(SubscriptionError(message: e.messages.join(", ")));
    } catch (e) {
      emit(SubscriptionError(message: e.toString()));
    }
  }
}

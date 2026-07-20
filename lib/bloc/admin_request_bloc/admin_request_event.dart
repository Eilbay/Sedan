part of 'admin_request_bloc.dart';

@immutable
abstract class AdminRequestEvent extends Equatable {}

class SendRequest extends AdminRequestEvent {
  final String requset;

  SendRequest({
    required this.requset,
  });

  @override
  List<Object?> get props => [];
}

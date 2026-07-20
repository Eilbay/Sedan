import 'package:optombai/bloc/pmt_bloc/pmt_state.dart';
import 'package:optombai/data/models/pmt/pmt_model.dart';
import 'package:equatable/equatable.dart';

abstract class PmtEvent extends Equatable {
  const PmtEvent();

  @override
  List<Object?> get props => [];
}

class PmtCreateEvent extends PmtEvent {
  final PmtModel pmt;

  const PmtCreateEvent({required this.pmt});

  @override
  List<Object?> get props => [pmt];
}

class PmtHistoryEvent extends PmtEvent {
  const PmtHistoryEvent();

  @override
  List<Object?> get props => [];
}

class PmtUpdateEvent extends PmtEvent {
  final PmtModel pmt;

  const PmtUpdateEvent({required this.pmt});

  @override
  List<Object?> get props => [pmt];
}

class PmtDeleteEvent extends PmtEvent {
  final int id;

  const PmtDeleteEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class PmtStatusEvent extends PmtEvent {
  const PmtStatusEvent();

  @override
  List<Object?> get props => [];
}

class PmtByIdEvent extends PmtEvent {
  final String pmtId;

  const PmtByIdEvent({required this.pmtId});

  @override
  List<Object?> get props => [pmtId];
}

class PmtStatusUpdateEvent extends PmtEvent {
  final String pmtId;
  final String amount;
  final String pmtMethod;
  final String premiumId;

  const PmtStatusUpdateEvent(
      {required this.pmtId,
      required this.amount,
      required this.pmtMethod,
      required this.premiumId});

  @override
  List<Object?> get props => [pmtId, amount, pmtMethod, premiumId];
}


class PmtSuccess extends PmtState {
  final PmtModel pmt;

  const PmtSuccess({required this.pmt});

  @override
  List<Object?> get props => [pmt];
}

class PmtFailure extends PmtState {
  final String error;

  const PmtFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

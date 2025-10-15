part of 'shedule_bloc.dart';

sealed class SheduleState extends Equatable {
  const SheduleState();

  @override
  List<Object> get props => [];
}

final class SheduleInitial extends SheduleState {}

final class SheduleLoading extends SheduleState {}

final class SheduleSuccess extends SheduleState {
  final List<Shedule> shedule;

  const SheduleSuccess({required this.shedule});

  @override
  List<Object> get props => [shedule];
}

final class SheduleError extends SheduleState {
  final String errorMessage;

  const SheduleError({required this.errorMessage});
  @override
  List<Object> get props => [errorMessage];
}

part of 'shedule_bloc.dart';

sealed class SheduleEvent extends Equatable {
  const SheduleEvent();

  @override
  List<Object> get props => [];
}

final class SheduleLoadEvent extends SheduleEvent {
  final String groupName;
  final int dayOfWeek;

  const SheduleLoadEvent({required this.groupName, required this.dayOfWeek});

  @override
  List<Object> get props => [groupName, dayOfWeek];
}

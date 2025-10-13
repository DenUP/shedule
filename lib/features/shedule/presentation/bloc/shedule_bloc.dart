import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:shedule_test/features/shedule/domain/repositories/shedule_repository.dart';

part 'shedule_event.dart';
part 'shedule_state.dart';

class SheduleBloc extends Bloc<SheduleEvent, SheduleState> {
  final SheduleRepository repository;
  SheduleBloc({required this.repository}) : super(SheduleInitial()) {
    on<SheduleEvent>((event, emit) {});
    on<SheduleLoadEvent>(_onLoading);
  }

  Future<void> _onLoading(
    SheduleLoadEvent event,
    Emitter<SheduleState> emit,
  ) async {
    try {
      emit(SheduleLoading());
      final response = await repository.getShedule(
        groupName: event.groupName,
        dayOfWeek: event.dayOfWeek,
      );
      emit(SheduleSuccess(shedule: response));
    } catch (e) {
      emit(SheduleError(errorMessage: e.toString()));
    }
  }
}

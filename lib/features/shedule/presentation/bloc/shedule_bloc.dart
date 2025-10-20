import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shedule_test/features/shedule/domain/entity/shedule.dart';
import 'package:shedule_test/features/shedule/domain/repositories/shedule_repository.dart';

part 'shedule_event.dart';
part 'shedule_state.dart';

class SheduleBloc extends Bloc<SheduleEvent, SheduleState> {
  final SheduleRepository repository;

  final Map<String, int> groupMap = {
    "11": 8,
    "12": 9,
    "21": 10,
    "22": 11,
    "22-27ТМ": 12,
    "22-2ИСП": 13,
    "23-29ТМ": 14,
    "23-3ИСП": 15,
    "24-31ТМ": 16,
    "25-33ТМ": 17,
  };
  SheduleBloc({required this.repository}) : super(SheduleInitial()) {
    on<SheduleLoadEvent>(_onLoading);
  }

  Future<void> _onLoading(
    SheduleLoadEvent event,
    Emitter<SheduleState> emit,
  ) async {
    try {
      emit(SheduleLoading());
      final groupId = groupMap[event.groupName]!;
      final response = await repository.getShedule(
        groupId: groupId,
        selectedDate: event.selectedDate,
      );
      emit(SheduleSuccess(shedule: response));
    } catch (e) {
      print('❌ Ошибка в _onLoading: $e');
      emit(SheduleError(errorMessage: e.toString()));
    }
  }
}

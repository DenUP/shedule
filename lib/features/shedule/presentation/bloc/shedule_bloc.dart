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
    on<SheduleRefreshEvent>(_onRefresh); // Добавляем событие обновления
    on<SheduleBackgroundRefreshEvent>(_onBackgroundRefresh);
  }
  Future<void> _onLoading(
    SheduleLoadEvent event,
    Emitter<SheduleState> emit,
  ) async {
    // Пробуем показать кэш мгновенно
    final cached = await repository.getCachedShedule(
      groupName: event.groupName,
      selectedDate: event.selectedDate,
    );
    if (cached != null) {
      emit(SheduleSuccess(shedule: cached));
      // Запускаем фоновую проверку обновлений
      add(
        SheduleBackgroundRefreshEvent(
          groupName: event.groupName,
          selectedDate: event.selectedDate,
        ),
      );
      return;
    }

    // Кэша нет – показываем загрузку и грузим из сети/кэша
    emit(SheduleLoading());
    try {
      final response = await repository.getShedule(
        groupName: event.groupName,
        selectedDate: event.selectedDate,
        forceRefresh: false,
      );
      emit(SheduleSuccess(shedule: response));
      add(
        SheduleBackgroundRefreshEvent(
          groupName: event.groupName,
          selectedDate: event.selectedDate,
        ),
      );
    } catch (e) {
      emit(SheduleError(errorMessage: e.toString()));
    }
  }

  Future<void> _onRefresh(
    SheduleRefreshEvent event,
    Emitter<SheduleState> emit,
  ) async {
    try {
      emit(SheduleLoading());

      // Загружаем с принудительным обновлением из интернета
      final response = await repository.getShedule(
        groupName: event.groupName,
        selectedDate: event.selectedDate,
        forceRefresh: true, // Принудительно обновляем из интернета
      );

      emit(SheduleSuccess(shedule: response));
    } catch (e) {
      print('❌ Ошибка в _onRefresh: $e');
      emit(SheduleError(errorMessage: e.toString()));
    }
  }

  Future<void> _onBackgroundRefresh(
    SheduleBackgroundRefreshEvent event,
    Emitter<SheduleState> emit,
  ) async {
    try {
      // Загружаем свежие данные с forceRefresh: true
      final freshData = await repository.getShedule(
        groupName: event.groupName,
        selectedDate: event.selectedDate,
        forceRefresh: true,
      );

      // Получаем текущее состояние, чтобы сравнить данные
      final currentState = state;
      if (currentState is SheduleSuccess) {
        // Если данные отличаются (например, по содержимому), обновляем состояние
        // Для простоты сравниваем списки по json-представлению (можно улучшить)
        final currentJson = currentState.shedule
            .map((e) => e.toJson())
            .toList();
        final freshJson = freshData.map((e) => e.toJson()).toList();
        if (currentJson.toString() != freshJson.toString()) {
          emit(SheduleSuccess(shedule: freshData));
        }
      } else {
        // Если текущее состояние не Success (например, Initial или Loading),
        // просто ничего не делаем — фоновая проверка не должна перебивать.
      }
    } catch (e) {
      // Ошибки (например, нет интернета) игнорируем — пользователь продолжает видеть кэш
      print('Background refresh error: $e');
    }
  }
}

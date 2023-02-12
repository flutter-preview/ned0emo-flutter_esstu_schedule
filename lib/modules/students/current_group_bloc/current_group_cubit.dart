import 'package:bloc/bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:schedule/modules/students/current_group_bloc/current_group_repository.dart';

part 'current_group_state.dart';

class CurrentGroupCubit extends Cubit<CurrentGroupState> {
  final CurrentGroupRepository _currentGroupRepository;

  int _currentLesson = -1;
  int _weekNumber = 0;
  bool _isZo = false;

  final classicDaysOfWeekList = [
    'Понедельник',
    'Вторник',
    'Среда',
    'Четверг',
    'Пятница',
    'Суббота',
    'Воскресенье',
  ];

  CurrentGroupCubit(CurrentGroupRepository repository)
      : _currentGroupRepository = repository,
        super(CurrentGroupInitial()) {
    //TODO: Возможно, надо перенести в основной кубит
    //Подумать над правильным распознаванием при смещении номера на сайте
    _weekNumber = (Jiffy().week + 1) % 2;
  }

  Future<void> hideSchedule() async {
    emit(CurrentGroupInitial());
  }

  Future<void> loadCurrentGroup(String fullLink, String name) async {
    emit(CurrentGroupLoading());
    _isZo = false;

    final currentTime = Jiffy().dateTime.minute + Jiffy().dateTime.hour * 60;
    if (currentTime >= 540 && currentTime <= 635) {
      _currentLesson = 0;
    } else if (currentTime >= 645 && currentTime <= 740) {
      _currentLesson = 1;
    } else if (currentTime >= 780 && currentTime <= 875) {
      _currentLesson = 2;
    } else if (currentTime >= 885 && currentTime <= 980) {
      _currentLesson = 3;
    } else if (currentTime >= 985 && currentTime <= 1080) {
      _currentLesson = 4;
    } else if (currentTime >= 1085 && currentTime <= 1180) {
      _currentLesson = 5;
    }

    try {
      ///Для заочников 7 пар, для остальных - 6. На сайте прописано 8 пар,
      ///потому одну пару всегда надо скипать
      if (fullLink.contains('zo')) {
        _isZo = true;
      }

      final groupSchedulePage =
          (await _currentGroupRepository.loadCurrentGroupSchedulePage(fullLink))
              .replaceAll(' COLOR="#0000ff"', '');

      final List<List<String>> currentScheduleList = [];
      List<String>? daysOfWeekList;

      if (_isZo) {
        daysOfWeekList = [];

        final List<String> splittedPage = groupSchedulePage
            .split('<FONT FACE="Arial" SIZE=1><P ALIGN="CENTER">');

        const numOfLessons = 8;

        for (int i = 0, k = 0; i + 7 < splittedPage.length; i += 8, k++) {
          final List<String> dayScheduleList = [];

          ///День недели
          try {
            final currentDayOfWeekStrSplit =
                splittedPage[i].split('SIZE=2><P ALIGN="CENTER">');

            if (currentDayOfWeekStrSplit.length > 1) {
              daysOfWeekList.add(currentDayOfWeekStrSplit[1]
                  .substring(0, currentDayOfWeekStrSplit[1].indexOf('</B>')));
            } else {
              daysOfWeekList.add(classicDaysOfWeekList[k % 7]);
            }
          } catch (_) {
            daysOfWeekList.add('Ошибка определения дня недели лол');
          }

          ///Расписание
          for (int j = i + 1; j < i + numOfLessons; j++) {
            dayScheduleList.add(
                splittedPage[j].substring(0, splittedPage[j].indexOf('<')));
          }

          currentScheduleList.add(dayScheduleList);
        }
      } else {
        final List<String> splittedPage = groupSchedulePage
            .split('<FONT FACE="Arial" SIZE=1><P ALIGN="CENTER">')
            .skip(1)
            .toList();

        const numOfLessons = 6;

        for (int i = 0; i + 7 < splittedPage.length; i += 8) {
          final List<String> dayScheduleList = [];

          for (int j = i; j < i + numOfLessons; j++) {
            dayScheduleList.add(
                splittedPage[j].substring(0, splittedPage[j].indexOf('<')));
          }

          currentScheduleList.add(dayScheduleList);
        }
      }

      emit(
        CurrentGroupLoaded(
          name: name,
          currentScheduleList: currentScheduleList,
          scheduleFullLink: fullLink,
          openedDayIndex: Jiffy().dateTime.weekday - 1,
          currentLesson: _currentLesson,
          weekNumber: _weekNumber,
          isZo: _isZo,
          daysOfWeekList: daysOfWeekList,
        ),
      );
    } catch (exception) {
      emit(CurrentGroupLoadingError(message: exception.toString()));
    }
  }

  Future<void> changeOpenedDay(int index) async {
    final currentState = state;
    if (currentState is CurrentGroupLoaded) {
      emit(
        CurrentGroupLoaded(
          name: currentState.name,
          currentScheduleList: currentState.currentScheduleList,
          scheduleFullLink: currentState.scheduleFullLink,
          openedDayIndex: index,
          currentLesson: _currentLesson,
          weekNumber: currentState.weekNumber,
          isZo: currentState.isZo,
          daysOfWeekList: currentState.daysOfWeekList,
        ),
      );
    }
  }
}

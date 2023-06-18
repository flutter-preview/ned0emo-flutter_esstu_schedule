import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:schedule/core/logger.dart';
import 'package:schedule/modules/teachers/repositories/teachers_repository.dart';

part 'faculty_event.dart';

part 'faculty_state.dart';

class FacultyBloc extends Bloc<FacultyEvent, FacultyState> {
  ///Маги, колледж
  final magLink = "/spezialitet/craspisanEdt.htm";

  ///Баки, специалитет
  final bakLink = "/bakalavriat/craspisanEdt.htm";

  final TeachersRepository _teachersRepository;

  FacultyBloc(TeachersRepository repository)
      : _teachersRepository = repository,
        super(FacultyInitial()) {
    on<FacultyEvent>((event, emit) {});
    on<LoadFaculties>(_loadFaculties);
    on<ChooseFaculty>(_chooseFaculty);
  }

  Future<void> _loadFaculties(
      LoadFaculties event, Emitter<FacultyState> emit) async {
    emit(FacultiesLoadingState());
    try {
      final siteTexts =
          await _teachersRepository.loadFacultiesPages(bakLink, link2: magLink);
      final facultyDepartmentLinkMap =
          _createFacultyDepartmentLinkMap(siteTexts[0], siteTexts[1]);

      emit(FacultiesLoadedState(
          facultyDepartmentLinkMap: facultyDepartmentLinkMap));
    } on RangeError catch (e) {
      Logger.addLog(
        Logger.error,
        'Ошибка загрузки страницы факультетов',
        'Имя аргумента: ${e.name}'
            '\nМинимально допустимое значение: ${e.start}'
            '\nМаксимально допустимое значение: ${e.end}'
            '\nТекущее значение: ${e.invalidValue}'
            '\n${e.message}'
            '\n${e.stackTrace}',
      );
      emit(FacultiesErrorState(
          'Ошибка обработки списка факультетов\n${e.message}\n${e.stackTrace}'));
    } on SocketException catch (e) {
      Logger.addLog(
        Logger.error,
        'Ошибка загрузки страницы факультетов',
        'Отсутствие интернета или недоступность сайта: ${e.message}',
      );
      emit(FacultiesErrorState(
          'Ошибка загрузки списка факультетов\n${e.message}'));
    } catch (e) {
      Logger.addLog(
        Logger.error,
        'Ошибка загрузки страницы факультетов',
        'Неизвестная ошибка. Тип: ${e.runtimeType}',
      );
      emit(FacultiesErrorState(
          'Ошибка загрузки списка факультетов\n${e.runtimeType}'));
    }
  }

  Map<String, Map<String, List<String>>> _createFacultyDepartmentLinkMap(
      String bakSiteText, String magSiteText) {
    int facultyWordExistingCheck = 0;
    Iterable<String> bakSiteList = [], magSiteList = [];

    if (bakSiteText.contains('faculty')) {
      bakSiteList = bakSiteText
          .replaceAll(RegExp(r"<!--.*-->"), '')
          .split('faculty')
          .skip(1);
    } else {
      facultyWordExistingCheck++;
    }

    if (magSiteText.contains('faculty')) {
      magSiteList = magSiteText
          .replaceAll(RegExp(r"<!--.*-->"), '')
          .split('faculty')
          .skip(1);
    } else {
      facultyWordExistingCheck++;
    }

    if (facultyWordExistingCheck > 1) {
      Logger.addLog(
        Logger.error,
        'Не удалось найти ключевое слово на странице факультетов',
        'Отсутствие интернета или недоступность сайта\nfacultyWordExistingCheck = 2',
      );

      return {};
    }

    final Map<String, Map<String, List<String>>> facultyMap = {};

    void fillMapByOneSiteText(Iterable<String> siteList, String linkName) {
      for (String facultySection in siteList) {
        String facultyName;

        try {
          facultyName = facultySection.contains('id')
              ? facultySection.substring(
                  facultySection.indexOf(RegExp(r"[а-я]|[А-Я]")),
                  facultySection.indexOf('</h2>'))
              : 'Прочее';
        } catch (e) {
          facultyName = 'Не удалось распознать название факультета';

          Logger.addLog(
            Logger.warning,
            'Не удалось распознать название факультета',
            'Cсылка: $linkName\nТип: ${e.runtimeType}',
          );
        }

        final Map<String, List<String>> departmentMap =
            facultyMap[facultyName] ?? {};

        final departmentsList = facultySection.split('href="').skip(1);

        for (String departmentSection in departmentsList) {
          String link;
          String departmentName;

          try {
            link =
                '/$linkName/${departmentSection.substring(0, departmentSection.indexOf('"'))}';
            departmentName = departmentSection.substring(
                departmentSection.indexOf(RegExp(r"[а-я]|[А-Я]")),
                departmentSection.indexOf('<'));
          } catch (e) {
            link = '/$linkName/0.htm';
            departmentName =
                'Не удалось распознать ссылку и/или название кафедры';

            Logger.addLog(
              Logger.warning,
              'Не удалось распознать ссылку и/или название кафедры',
              'Cсылка: $link\nТип: ${e.runtimeType}',
            );
          }

          if (!departmentMap.keys.contains(departmentName)) {
            departmentMap[departmentName] = [];
          }
          departmentMap[departmentName]!.add(link);
        }

        facultyMap[facultyName] = departmentMap;
      }
    }

    fillMapByOneSiteText(bakSiteList, 'bakalavriat');
    fillMapByOneSiteText(magSiteList, 'spezialitet');

    return facultyMap;
  }

  Future<void> _chooseFaculty(
      ChooseFaculty event, Emitter<FacultyState> emit) async {
    emit(CurrentFacultyState(
      facultyName: event.facultyName,
      departmentsMap: event.departmentsMap,
    ));
  }
}

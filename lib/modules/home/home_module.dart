import 'package:flutter_modular/flutter_modular.dart';
import 'package:schedule/core/app_routes.dart';
import 'package:schedule/modules/home/home_page.dart';
import 'package:schedule/modules/settings/bloc/settings_cubit.dart';
import 'package:schedule/modules/settings/bloc/settings_repository.dart';
import 'package:schedule/modules/settings/settings_module.dart';
import 'package:schedule/modules/students/students_module.dart';

class HomeModule extends Module {
  @override
  List<Bind<Object>> get binds => [
    Bind.singleton((i) => SettingsRepository()),
    Bind.singleton((i) => SettingsCubit(i.get<SettingsRepository>()), export: true),

  ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (context, args) => HomePage()),
        ModuleRoute(AppRoutes.studentsRoute, module: StudentsModule()),
        ModuleRoute(AppRoutes.settingsRoute, module: SettingsModule()),
      ];
}
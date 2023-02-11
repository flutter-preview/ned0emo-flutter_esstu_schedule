import 'package:flutter_modular/flutter_modular.dart';
import 'package:schedule/app_module.dart';
import 'package:schedule/modules/students/all_groups_bloc/all_groups_cubit.dart';
import 'package:schedule/modules/students/all_groups_bloc/all_groups_repository.dart';
import 'package:schedule/modules/students/current_group_bloc/current_group_cubit.dart';
import 'package:schedule/modules/students/current_group_bloc/current_group_repository.dart';
import 'package:schedule/modules/students/students_page.dart';

class StudentsModule extends Module{
  @override
  List<Bind<Object>> get binds => [
    Bind((i) => AllGroupsRepository()),
    Bind((i) => AllGroupsCubit(i.get<AllGroupsRepository>())..loadGroupList()),
    Bind((i) => CurrentGroupRepository()),
    Bind((i) => CurrentGroupCubit(i.get<CurrentGroupRepository>())),
  ];

  @override
  List<ModularRoute> get routes => [
    ChildRoute('/', child: (context, args) => const StudentsPage())
  ];

  @override
  List<Module> get imports => [
    AppModule(),
  ];
}
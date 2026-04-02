import 'package:br_thp_meubenapp/app/feature/classroom/data/models/classroom_item_model.dart';

abstract class IClassroomRepository {
  Future<List<ClassroomItemModel>> getClassroomsByProject({
    required int year,
    required String socialTechnologyId,
    required String projectId,
  });
}

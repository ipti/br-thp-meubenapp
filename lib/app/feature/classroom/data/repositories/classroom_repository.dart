import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/classroom/data/models/classroom_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/classroom/data/repositories/i_classroom_repository.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/mobile_store_repository.dart';

class ClassroomRepository implements IClassroomRepository {
  ClassroomRepository({required IApiClient apiClient})
      : _mobileStoreRepository = MobileStoreRepository(apiClient: apiClient);

  final MobileStoreRepository _mobileStoreRepository;

  @override
  Future<List<ClassroomItemModel>> getClassroomsByProject({
    required int year,
    required String socialTechnologyId,
    required String projectId,
  }) async {
    final snapshot = await _mobileStoreRepository.getSnapshot(year: year);
    final socialTechnology = snapshot.where(
      (item) => item.id.toString() == socialTechnologyId,
    );
    if (socialTechnology.isEmpty) return const [];

    final project = socialTechnology.first.project.where(
      (item) => item.id.toString() == projectId,
    );
    if (project.isEmpty) return const [];

    return project.first.classrooms
        .map(
          (item) => ClassroomItemModel(
            id: item.id,
            name: item.name,
            projectId: project.first.id,
            socialTechnologyId: socialTechnology.first.id,
          ),
        )
        .toList();
  }
}

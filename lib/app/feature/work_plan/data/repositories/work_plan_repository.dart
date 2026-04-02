import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/mobile_store_repository.dart';
import 'package:br_thp_meubenapp/app/feature/work_plan/data/models/social_technology_one_model.dart';
import 'package:br_thp_meubenapp/app/feature/work_plan/data/repositories/i_work_plan_repository.dart';

class WorkPlanRepository implements IWorkPlanRepository {
  WorkPlanRepository({required IApiClient apiClient})
      : _mobileStoreRepository = MobileStoreRepository(apiClient: apiClient);

  final MobileStoreRepository _mobileStoreRepository;

  @override
  Future<SocialTechnologyOneModel> getSocialTechnologyOne(
    String id,
    int year,
  ) async {
    final snapshot = await _mobileStoreRepository.getSnapshot(year: year);
    final socialTechnology = snapshot.firstWhere(
      (item) => item.id.toString() == id,
      orElse: SocialTechnologyOneModel.emptyFromMobileStore,
    );
    return SocialTechnologyOneModel.fromMobileStore(socialTechnology);
  }
}

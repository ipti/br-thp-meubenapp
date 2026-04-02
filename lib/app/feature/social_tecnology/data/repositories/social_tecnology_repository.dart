import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/mobile_store_repository.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/models/social_technology_model.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/repositories/i_social_tecnology_repository.dart';

class SocialTecnollogyRepository implements ISocialTecnollogyRepository {
  SocialTecnollogyRepository({required IApiClient apiClient})
      : _mobileStoreRepository = MobileStoreRepository(apiClient: apiClient);

  final MobileStoreRepository _mobileStoreRepository;

  @override
  Future<List<SocialTechnologyModel>> getSocialTechnologyUser({
    required int year,
  }) async {
    final snapshot = await _mobileStoreRepository.getSnapshot(year: year);
    return snapshot
        .map(
          (item) => SocialTechnologyModel(
            id: item.id,
            name: item.name,
            avartarUrl: item.avartarUrl,
            areaOfActivity: item.areaOfActivity,
            active: item.active,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
          ),
        )
        .toList();
  }
}

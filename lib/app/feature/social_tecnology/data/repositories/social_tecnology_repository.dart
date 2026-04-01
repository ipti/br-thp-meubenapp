import 'package:br_thp_meubenapp/app/core/network/api_response.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/social_tecnology_endpoints.dart';

class SocialTecnollogyRepository {
  SocialTecnollogyRepository({required IApiClient apiClient})
    : _apiClient = apiClient;

  final IApiClient _apiClient;

  Future<ApiResponse> getSocialTechnologyUser(String userId) {
    return _apiClient.get(
      SocialTecnollogyPageEndpoints.socialTechnologyUserById(userId),
    );
  }
}

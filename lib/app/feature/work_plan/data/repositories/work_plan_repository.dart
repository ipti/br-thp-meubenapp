import 'package:br_thp_meubenapp/app/core/network/api_response.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/work_plan/data/work_plan_endpoints.dart';

class WorkPlanRepository {
  WorkPlanRepository({required IApiClient apiClient}) : _apiClient = apiClient;

  final IApiClient _apiClient;

  Future<ApiResponse> getSocialTechnologyOne(String id, int year) {
    return _apiClient.get(
      WorkPlanPageEndpoints.socialTechnologyOneById(id, year),
    );
  }
}

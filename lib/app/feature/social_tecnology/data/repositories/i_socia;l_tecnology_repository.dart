import 'package:br_thp_meubenapp/app/core/network/api_response.dart';

abstract class IWorkPlanRepository {
  Future<ApiResponse> getSocialTechnologyOne(String id, int year);
}

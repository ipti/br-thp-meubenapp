import 'package:br_thp_meubenapp/app/core/network/api_response.dart';

abstract class IApiExamplesRepository {
  Future<ApiResponse> getWorkPlans();
  Future<ApiResponse> createWorkPlan();
  Future<ApiResponse> updateWorkPlanPut(int id);
  Future<ApiResponse> updateWorkPlanPatch(int id);
  Future<ApiResponse> deleteWorkPlan(int id);
}

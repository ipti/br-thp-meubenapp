import 'package:br_thp_meubenapp/app/core/network/api_response.dart';
import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/api_examples/data/api_examples_endpoints.dart';
import 'package:br_thp_meubenapp/app/feature/api_examples/data/dto/work_plan_request_dto.dart';
import 'package:br_thp_meubenapp/app/feature/api_examples/data/repositories/i_api_examples_repository.dart';

class ApiExamplesRepository implements IApiExamplesRepository {
  ApiExamplesRepository({required IApiClient apiClient})
    : _apiClient = apiClient;

  final IApiClient _apiClient;

  @override
  Future<ApiResponse> getWorkPlans() {
    return _apiClient.get(ApiExamplesEndpoints.workPlans);
  }

  @override
  Future<ApiResponse> createWorkPlan() {
    final dto = WorkPlanRequestDto(
      title: 'Novo plano',
      description: 'Criado via POST no app Flutter.',
      active: true,
    );
    return _apiClient.post(ApiExamplesEndpoints.workPlans, body: dto.toJson());
  }

  @override
  Future<ApiResponse> updateWorkPlanPut(int id) {
    final dto = WorkPlanRequestDto(
      title: 'Plano atualizado com PUT',
      description: 'Substituicao completa do recurso.',
      active: true,
    );
    return _apiClient.put(
      ApiExamplesEndpoints.workPlanById(id),
      body: dto.toJson(),
    );
  }

  @override
  Future<ApiResponse> updateWorkPlanPatch(int id) {
    return _apiClient.patch(
      ApiExamplesEndpoints.workPlanById(id),
      body: {'description': 'Atualizacao parcial com PATCH.'},
    );
  }

  @override
  Future<ApiResponse> deleteWorkPlan(int id) {
    return _apiClient.delete(ApiExamplesEndpoints.workPlanById(id));
  }
}

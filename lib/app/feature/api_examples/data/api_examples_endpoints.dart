class ApiExamplesEndpoints {
  ApiExamplesEndpoints._();

  // Ajuste os endpoints conforme os recursos reais do seu backend.
  static const String workPlans = '/api/work-plans';

  static String workPlanById(int id) => '$workPlans/$id';
}

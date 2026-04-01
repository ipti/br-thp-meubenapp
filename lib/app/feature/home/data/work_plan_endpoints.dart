class WorkPlanPageEndpoints {
  WorkPlanPageEndpoints._();

  static const String socialTechnologyOne = '/social-technology-bff/one';

  static String socialTechnologyOneById(String id, int year) =>
      '$socialTechnologyOne?stId=$id&year=$year';
}

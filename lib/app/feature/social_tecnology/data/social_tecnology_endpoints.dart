class SocialTecnollogyPageEndpoints {
  SocialTecnollogyPageEndpoints._();

  static const String socialTechnologyUser =
      '/social-technology-bff/user-token';

  static String socialTechnologyUserByYear(int year) =>
      '$socialTechnologyUser?year=$year';
}

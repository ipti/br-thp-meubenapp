class SocialTecnollogyPageEndpoints {
  SocialTecnollogyPageEndpoints._();

  static const String socialTechnologyUser = '/social-technology-bff/user';

  static String socialTechnologyUserById(String userId) =>
      '$socialTechnologyUser?userId=$userId';
}

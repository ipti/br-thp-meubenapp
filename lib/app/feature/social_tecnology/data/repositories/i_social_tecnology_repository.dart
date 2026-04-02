import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/models/social_technology_model.dart';

abstract class ISocialTecnollogyRepository {
  Future<List<SocialTechnologyModel>> getSocialTechnologyUser({
    required int year,
  });
}

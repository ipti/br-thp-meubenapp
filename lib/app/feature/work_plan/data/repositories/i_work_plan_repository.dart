import 'package:br_thp_meubenapp/app/feature/work_plan/data/models/social_technology_one_model.dart';

abstract class IWorkPlanRepository {
  Future<SocialTechnologyOneModel> getSocialTechnologyOne(String id, int year);
}

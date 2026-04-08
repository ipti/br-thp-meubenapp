import 'package:br_thp_meubenapp/app/feature/profile/data/models/user_profile_model.dart';

abstract class IProfileRepository {
  Future<UserProfileModel> getUserProfile();
}

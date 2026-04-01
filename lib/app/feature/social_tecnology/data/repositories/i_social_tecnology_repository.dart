import 'package:br_thp_meubenapp/app/core/network/api_response.dart';

abstract class ISocialTecnollogyRepository {
  Future<ApiResponse> getSocialTechnologyOne(String id, int year);
}

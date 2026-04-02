import 'package:br_thp_meubenapp/app/core/network/i_api_client.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/local/mobile_store_cache_datasource.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/models/mobile_store_snapshot_model.dart';
import 'package:br_thp_meubenapp/app/feature/mobile_store/data/repositories/i_mobile_store_repository.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/social_tecnology_endpoints.dart';

class MobileStoreRepository implements IMobileStoreRepository {
  MobileStoreRepository({
    required IApiClient apiClient,
    MobileStoreCacheDatasource? cacheDatasource,
  })  : _apiClient = apiClient,
        _cacheDatasource = cacheDatasource ?? MobileStoreCacheDatasource();

  final IApiClient _apiClient;
  final MobileStoreCacheDatasource _cacheDatasource;

  @override
  Future<List<MobileStoreSnapshotModel>> getSnapshot({required int year}) async {
    final cachedPayload = await _cacheDatasource.getSnapshot(year: year);

    try {
      await sync(year: year);
      final refreshed = await _cacheDatasource.getSnapshot(year: year);
      return _parseSnapshot(refreshed);
    } catch (_) {
      return _parseSnapshot(cachedPayload);
    }
  }

  @override
  Future<void> sync({required int year}) async {
    final response = await _apiClient.get(
      SocialTecnollogyPageEndpoints.socialTechnologyUserByYear(year),
      withAuthToken: true,
    );
    final payload = _extractPayload(response.data);
    await _cacheDatasource.saveSnapshot(year: year, payload: payload);
  }

  dynamic _extractPayload(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return data['data'] ??
          data['items'] ??
          data['socialTechnologies'] ??
          data['result'] ??
          data;
    }
    return const [];
  }

  List<MobileStoreSnapshotModel> _parseSnapshot(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(MobileStoreSnapshotModel.fromJson)
          .toList();
    }
    if (payload is Map<String, dynamic>) {
      return [MobileStoreSnapshotModel.fromJson(payload)];
    }
    return const [];
  }
}

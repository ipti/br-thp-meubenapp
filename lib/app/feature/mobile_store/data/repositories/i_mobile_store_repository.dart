import 'package:br_thp_meubenapp/app/feature/mobile_store/data/models/mobile_store_snapshot_model.dart';

abstract class IMobileStoreRepository {
  Future<List<MobileStoreSnapshotModel>> getSnapshot({required int year});
  Future<void> sync({required int year});
}

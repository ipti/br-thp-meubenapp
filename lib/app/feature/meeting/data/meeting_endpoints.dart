class MeetingEndpoints {
  MeetingEndpoints._();

  static const String meeting = '/meeting';
  static const String usersBff = '/user-bff';
  static String meetingBffSyncOffline({String? source}) {
    final sourceQuery = (source == null || source.trim().isEmpty)
        ? ''
        : '?source=$source';
    return '/meeting-bff/sync-offline$sourceQuery';
  }
}

class ArchiveEndpoints {
  ArchiveEndpoints._();

  static const String archiveMeetingBff = '/archive-meeting-bff';

  static String uploadByMeetingId(int meetingId, {String? source}) {
    final sourceQuery = (source == null || source.trim().isEmpty)
        ? ''
        : '&source=$source';
    return '$archiveMeetingBff?meetingId=$meetingId$sourceQuery';
  }

  static String deleteById(int id) => '$archiveMeetingBff/$id';
}

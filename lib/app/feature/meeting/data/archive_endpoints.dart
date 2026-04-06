class ArchiveEndpoints {
  ArchiveEndpoints._();

  static const String archiveMeetingBff = '/archive-meeting-bff';

  static String uploadByMeetingId(int meetingId) =>
      '$archiveMeetingBff?meetingId=$meetingId';

  static String deleteById(int id) => '$archiveMeetingBff/$id';
}

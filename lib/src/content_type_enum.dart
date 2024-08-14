/// Content Type
/// More content types:
/// https://www.iana.org/assignments/media-types/media-types.xhtml
enum ContentType {
  /// Application Type
  json('application/json'),

  /// Image Type
  /// GIF
  gif('image/gif'),

  /// JPEG
  jpeg('image/jpeg'),

  /// PNG
  png('image/png'),

  /// Multipart Type
  /// Form Data
  formData('multipart/form-data'),

  /// Text Type
  /// HTML
  htmnl('text/html'),

  /// CSV
  csv('text/csv'),

  /// XML
  xml('text/xml'),

  /// MPEG
  mpeg('video/mpeg'),

  /// MP4
  mp4('video/mp4'),

  /// Quicktime
  quicktime('video/quicktime');

  const ContentType(this.value);

  /// Value of content type
  final String value;
}

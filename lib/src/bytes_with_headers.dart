import 'dart:typed_data';

/// {@template bytes_with_headers}
/// A response body read as bytes, with the response's headers.
/// {@endtemplate}
class BytesWithHeaders {
  /// {@macro bytes_with_headers}
  const BytesWithHeaders({required this.bytes, required this.headers});

  /// The response body.
  final Uint8List bytes;

  /// The response headers, with lower-case names as `package:http` gives
  /// them, such as `content-type` and `content-disposition`.
  final Map<String, String> headers;
}

import 'package:api_request_helper_flutter/src/content_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContentType', () {
    test('json has correct value', () {
      expect(ContentType.json.value, 'application/json');
    });

    test('formData has correct value', () {
      expect(ContentType.formData.value, 'multipart/form-data');
    });

    test('jpeg has correct value', () {
      expect(ContentType.jpeg.value, 'image/jpeg');
    });

    test('png has correct value', () {
      expect(ContentType.png.value, 'image/png');
    });

    test('xml has correct value', () {
      expect(ContentType.xml.value, 'text/xml');
    });

    test('mp4 has correct value', () {
      expect(ContentType.mp4.value, 'video/mp4');
    });
  });
}

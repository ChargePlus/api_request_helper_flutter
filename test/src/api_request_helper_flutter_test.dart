import 'dart:convert';
import 'dart:typed_data';

import 'package:api_request_helper_flutter/api_request_helper_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('ApiRequestHelperFlutter', () {
    test('can be instantiated', () {
      expect(ApiRequestHelper(), isNotNull);
    });

    group('post', () {
      final uri = Uri.parse('https://api.chargeplus.co/auth/getSMSOTPv2');
      late Map<String, String> sentHeaders;

      setUp(() {
        PackageInfo.setMockInitialValues(
          appName: 'app',
          packageName: 'co.chargeplus.app',
          version: '1.0.0',
          buildNumber: '1',
          buildSignature: '',
        );
      });

      Future<void> post({
        String? userToken,
        Map<String, String>? extraHeaders,
      }) {
        return http.runWithClient(
          () => ApiRequestHelper().post(
            uri: uri,
            data: const {},
            userToken: userToken,
            extraHeaders: extraHeaders,
          ),
          () => MockClient((request) async {
            sentHeaders = request.headers;
            return http.Response(
              jsonEncode({'status': 200, 'result': <String, dynamic>{}}),
              200,
            );
          }),
        );
      }

      test('sends extraHeaders alongside the default headers', () async {
        await post(extraHeaders: {'X-Firebase-AppCheck': 'token'});

        expect(sentHeaders['X-Firebase-AppCheck'], 'token');
        expect(sentHeaders['build-number'], '1');
      });

      test('never lets extraHeaders override the default headers', () async {
        await post(
          userToken: 'real-token',
          extraHeaders: {
            'Authorization': 'forged',
            'Content-Type': 'text/plain',
            'x-api-key': 'forged',
            'x-api-token': 'forged',
            'build-number': 'forged',
            'platform': 'forged',
          },
        );

        expect(sentHeaders['Authorization'], 'real-token');
        expect(sentHeaders['Content-Type'], startsWith('application/json'));
        expect(sentHeaders['x-api-key'], isNot('forged'));
        expect(sentHeaders['x-api-token'], isNot('forged'));
        expect(sentHeaders['build-number'], '1');
        expect(sentHeaders['platform'], isNot('forged'));
      });

      test('sends only the default headers without extraHeaders', () async {
        await post();

        expect(sentHeaders.containsKey('X-Firebase-AppCheck'), isFalse);
        expect(sentHeaders['build-number'], '1');
      });
    });

    group('readBytesWithHeaders', () {
      final uri = Uri.parse('https://files.chargeplus.co/invoice/123');
      final body = Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]);
      late Map<String, String> sentHeaders;

      MockClient respond(
        int status, {
        Map<String, String> headers = const {},
      }) => MockClient((request) async {
        sentHeaders = request.headers;
        return http.Response.bytes(body, status, headers: headers);
      });

      test('returns the bytes with the response headers', () async {
        final result = await http.runWithClient(
          () => ApiRequestHelper().readBytesWithHeaders(uri: uri),
          () => respond(
            200,
            headers: {
              'content-type': 'application/pdf',
              'content-disposition': 'attachment; filename="invoice.pdf"',
            },
          ),
        );

        expect(result.bytes, body);
        expect(result.headers['content-type'], 'application/pdf');
        expect(
          result.headers['content-disposition'],
          'attachment; filename="invoice.pdf"',
        );
      });

      test('sends the user token as readBytes does, and only then', () async {
        await http.runWithClient(
          () => ApiRequestHelper().readBytesWithHeaders(
            uri: uri,
            userToken: 'token',
          ),
          () => respond(200),
        );
        expect(sentHeaders['Authorization'], 'token');

        await http.runWithClient(
          () => ApiRequestHelper().readBytesWithHeaders(uri: uri),
          () => respond(200),
        );
        expect(sentHeaders.containsKey('Authorization'), isFalse);
      });

      // Callers read the status from the message (`failed with status 404`),
      // so a failure must read exactly as readBytes' does.
      for (final status in [404, 500]) {
        test(
          'fails on $status with the same ClientException as readBytes',
          () async {
            Future<Object?> errorOf(Future<Object?> Function() call) async {
              try {
                await http.runWithClient(call, () => respond(status));
              } on http.ClientException catch (error) {
                return error;
              }
              return null;
            }

            final expected =
                await errorOf(
                      () => ApiRequestHelper().readBytes(uri: uri),
                    )
                    as http.ClientException?;
            final actual =
                await errorOf(
                      () => ApiRequestHelper().readBytesWithHeaders(uri: uri),
                    )
                    as http.ClientException?;

            expect(expected, isNotNull);
            expect(actual?.message, expected?.message);
            expect(actual?.uri, expected?.uri);
            expect(actual?.message, contains('failed with status $status'));
          },
        );
      }

      test('leaves readBytes returning the bytes alone', () async {
        final bytes = await http.runWithClient(
          () => ApiRequestHelper().readBytes(uri: uri),
          () => respond(200, headers: {'content-type': 'application/pdf'}),
        );

        expect(bytes, body);
      });
    });
  });
}

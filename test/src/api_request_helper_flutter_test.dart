import 'dart:convert';

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

      Future<void> post({Map<String, String>? extraHeaders}) {
        return http.runWithClient(
          () => ApiRequestHelper().post(
            uri: uri,
            data: const {},
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

      test('sends only the default headers without extraHeaders', () async {
        await post();

        expect(sentHeaders.containsKey('X-Firebase-AppCheck'), isFalse);
        expect(sentHeaders['build-number'], '1');
      });
    });
  });
}

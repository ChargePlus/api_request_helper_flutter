import 'dart:async';

import 'package:api_request_helper_flutter/api_request_helper_flutter.dart';
import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('server message on 400 and 422', () {
    final uri = Uri.parse('https://example.com/api');

    const fixed = {
      400: (
        code: 'bad-request',
        message: 'The server could not process the request',
      ),
      422: (
        code: 'unprocessable-entity',
        message: 'Could not process due to possible semantic errors',
      ),
    };

    ApiServiceException thrown(String body, int status) {
      try {
        RequestFunctions.getResponse(
          responseBody: body,
          statusCode: status,
          uri: uri,
          statusController: StreamController<num>.broadcast(),
        );
      } on ApiServiceException catch (e) {
        return e;
      }
      throw StateError('nothing thrown');
    }

    for (final entry in fixed.entries) {
      final status = entry.key;
      final code = entry.value.code;
      final message = entry.value.message;

      group('$status', () {
        test('string message is exposed, code and message unchanged', () {
          final e = thrown('{"message":"Price too low"}', status);
          expect(e.serverMessage, 'Price too low');
          expect(e.code, code);
          expect(e.message, message);
        });

        test('msg is used when message is absent', () {
          final e = thrown('{"msg":"Price too low"}', status);
          expect(e.serverMessage, 'Price too low');
          expect(e.message, message);
        });

        for (final body in [
          '{"status":$status}',
          '{"message":""}',
          '{"message":"   "}',
          '{"message":null}',
        ]) {
          test('$body leaves serverMessage null', () {
            final e = thrown(body, status);
            expect(e.serverMessage, isNull);
            expect(e.code, code);
            expect(e.message, message);
          });
        }

        for (final body in [
          '{"message":{"price":["too low"]}}',
          '{"message":["too low"]}',
          '{"message":42}',
        ]) {
          test('$body (not a string) leaves serverMessage null', () {
            final e = thrown(body, status);
            expect(e.serverMessage, isNull);
            expect(e.code, code);
            expect(e.message, message);
          });
        }

        test('displayMessageKey still read', () {
          final e = thrown(
            '{"message":"x","result":{"display_message_key":"k"}}',
            status,
          );
          expect(e.displayMessageKey, 'k');
        });
      });
    }

    test('a 200 whose body status is 422 exposes the message too', () {
      final e = thrown('{"status":422,"message":"Price too low"}', 200);
      expect(e.code, 'unprocessable-entity');
      expect(e.serverMessage, 'Price too low');
    });

    test('getException exposes errorMessage on 400 and 422 only', () {
      for (final status in [400, 422]) {
        final e = RequestFunctions.getException(
          statusCode: status,
          errorMessage: 'x',
        );
        expect((e as ApiServiceException).serverMessage, 'x');
      }
      expect(
        RequestFunctions.getException(statusCode: 404, errorMessage: 'x'),
        isNot(isA<ApiServiceException>()),
      );
    });

    test('is still a ServiceException', () {
      expect(thrown('{"message":"x"}', 400), isA<ServiceException>());
    });

    test('other statuses are plain ServiceExceptions', () {
      for (final status in [401, 403, 404, 429, 500, 418]) {
        expect(
          () => RequestFunctions.getResponse(
            responseBody: '{"message":"server text"}',
            statusCode: status,
            uri: uri,
            statusController: StreamController<num>.broadcast(),
          ),
          throwsA(
            isA<ServiceException>().having(
              (e) => e is ApiServiceException,
              'is ApiServiceException',
              isFalse,
            ),
          ),
        );
      }
    });

    test('serverMessage takes part in equality, null stays equal', () {
      const a = ApiServiceException(code: 'c', serverMessage: 'x');
      const b = ApiServiceException(code: 'c', serverMessage: 'y');
      const c = ApiServiceException(code: 'c');
      const d = ApiServiceException(code: 'c');
      expect(a, isNot(b));
      expect(c, d);
    });
  });
}

import 'package:api_request_helper_flutter/src/request_functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RequestFunctions', () {
    group('getMultipartRequest', () {
      // Tests go here
    });

    group('getResponse', () {
      // Tests go here
    });

    group('getException', () {
      const defaultDisplayMessageKey = 'display-message-key';

      group('301', () {
        const defaultCode = 'invalid-credentials';
        const defaultMessage = 'Credentials are invalid';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 301,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 301,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('400', () {
        const defaultCode = 'bad-request';
        const defaultMessage = 'The server could not process the request';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 400,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 400,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('401', () {
        const defaultCode = 'unauthorized';
        const defaultMessage = 'Could not authorize user';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 401,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 401,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('403', () {
        const defaultCode = 'insufficient-permission';
        const defaultMessage = 'User do not have permission';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 403,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 403,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('404', () {
        const defaultCode = 'not-found';
        const defaultMessage = 'Could not retrieve resource';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 404,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 404,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('405', () {
        const defaultCode = 'method-not-allowed';
        const defaultMessage = 'Could not perform action';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 405,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 405,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('406', () {
        const defaultCode = 'not-acceptable';
        const defaultMessage = 'Could not perform action';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 406,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 406,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('408', () {
        const defaultCode = 'request-timeout';
        const defaultMessage = 'Request has timed out';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 408,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 408,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('422', () {
        const defaultCode = 'unprocessable-entity';
        const defaultMessage =
            'Could not process due to possible semantic errors';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 422,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 422,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('428', () {
        const defaultCode = 'security-rejections';
        const defaultMessage = 'Security Rejections';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 428,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 428,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('429', () {
        const defaultCode = 'too-many-requests';
        const defaultMessage = 'Too many requests';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 429,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 429,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('500', () {
        const defaultCode = 'internal-server-error';
        const defaultMessage = 'Server has encountered issue';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 500,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 500,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('502', () {
        const defaultCode = 'bad-gateway';
        const defaultMessage = 'Server received invalid response';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 502,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 502,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('503', () {
        const defaultCode = 'server-unavailable';
        const defaultMessage = 'Server is not available';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 503,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 503,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('504', () {
        const defaultCode = 'gateway-timeout';
        const defaultMessage = 'Server has timed out';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 504,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 504,
            displayMessageKey: defaultDisplayMessageKey,
          );
          expect(exception.code, defaultCode);
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });

      group('default handling', () {
        const defaultMessage = 'unknown error';

        test('w/o displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 999,
            errorMessage: defaultMessage,
          );
          expect(exception.code, '999');
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, isNull);
        });
        test('w/ displayMessageKey', () {
          final exception = RequestFunctions.getException(
            statusCode: 999,
            displayMessageKey: defaultDisplayMessageKey,
            errorMessage: defaultMessage,
          );
          expect(exception.code, '999');
          expect(exception.message, defaultMessage);
          expect(exception.displayMessageKey, defaultDisplayMessageKey);
        });
      });
    });
  });
}

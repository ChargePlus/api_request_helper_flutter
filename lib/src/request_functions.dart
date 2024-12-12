import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:http/http.dart' as http;

/// Class to handle HTTP response and exceptions
class RequestFunctions {
  /// Uploads a multipart form to the specified URI.
  ///
  /// Parameters:
  /// - [uri] The URI to upload the form to.
  /// - [data] The form data to be uploaded.
  /// - [method] The HTTP method to use for the upload.
  /// - [headers] The HTTP headers to include in the upload.
  /// - [fileData] The file data to be uploaded. If not provided, a
  /// ServiceException will be thrown.
  ///
  /// Returns:
  /// - A Future that completes when the upload is finished.
  ///
  /// Throws:
  /// - A ServiceException if the file data is empty.
  static Future<http.MultipartRequest> getMultipartRequest({
    required Uri uri,
    required Map<String, dynamic> data,
    required String method,
    required Map<String, String> headers,
    Map<String, String>? fileData,
  }) async {
    final files = fileData?.entries ?? [];
    final body = data.map((key, value) => MapEntry(key, value.toString()));

    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(headers);
    request.fields.addAll(body);

    for (final file in files) {
      final field = file.key;
      final fieldPath = file.value;

      request.files.add(await http.MultipartFile.fromPath(field, fieldPath));
    }

    return request;
  }

  /// Handles the HTTP response and emits the status code to the status
  /// controller
  ///
  /// Throws a [ServiceException] if the status code is not 200
  ///
  /// Parameters:
  /// - [responseBody] The body of the HTTP response
  /// - [statusCode] The status code of the HTTP response
  /// - [uri] The requested URI
  /// - [statusController] The status controller to emit the status code
  /// - [isResult] Whether to return the 'result' field from the response body
  static dynamic getResponse({
    required String responseBody,
    required num statusCode,
    required Uri uri,
    required StreamController<num> statusController,
    Map<String, dynamic> data = const {},
    bool isResult = true,
  }) {
    /// Decode the response body to a map
    final mappedResponse = json.decode(responseBody) as Map<String, dynamic>;

    /// If the status code is 200 but the 'status' field in the response body
    /// is not 200, update the status code
    if (statusCode == 200 && mappedResponse['status'] != 200) {
      statusCode = num.parse(mappedResponse['status'].toString());
    }

    /// Emit the status code to the status controller
    statusController.add(statusCode);

    /// Log the status code and the URI
    final emoji = switch (statusCode) {
      != null && >= 200 && < 300 => '✅', // Log a success emoji
      != null && >= 300 && < 400 => '🟠', // Log a warning emoji
      _ => '❌' // Log an error emoji
    };
    log('$emoji $statusCode $emoji -- $uri, data: $data');

    /// Log the response body and the status code in the response body
    log('$emoji body $emoji -- json: $mappedResponse, statusCode: '
        '${mappedResponse['status']}');

    /// Switch on the status code and return the appropriate response
    switch (statusCode) {
      case 200:
      case 203:
      case 204:
      case 214:
        if (isResult) {
          return mappedResponse['result'];
        } else {
          return mappedResponse;
        }
      default:

        /// Throw a ServiceException based on the status code
        /// and the 'message' field in the response body
        /// and the 'displayMessageKey' field in the response body (if any)
        final result = mappedResponse['result'] as Map<String, dynamic>;
        final displayMessageKey = result['display_message_key'] as String?;

        final exception = getException(
          statusCode: statusCode,
          errorMessage: mappedResponse['message'].toString(),
          displayMessageKey: displayMessageKey,
          stackTrace: StackTrace.current,
        );
        throw exception;
    }
  }

  /// Returns a [ServiceException] based on the status code and error message
  ///
  /// Parameters:
  /// - [statusCode] The status code
  /// - [errorMessage] The error message
  static ServiceException getException({
    required num statusCode,
    String? errorMessage,
    String? displayMessageKey,
    StackTrace? stackTrace,
  }) {
    /// Switch on the status code and return a corresponding [ServiceException]
    switch (statusCode) {
      case 301:
        return ServiceException(
          code: 'invalid-credentials',
          message: 'Credentials are invalid',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 400:
        return ServiceException(
          code: 'bad-request',
          message: 'The server could not process the request',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 401:
        return ServiceException(
          code: 'unauthorized',
          message: 'Could not authorize user',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 403:
        return ServiceException(
          code: 'insufficient-permission',
          message: 'User do not have permission',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 404:
        return ServiceException(
          code: 'not-found',
          message: 'Could not retrieve resource',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 405:
        return ServiceException(
          code: 'method-not-allowed',
          message: 'Could not perform action',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 406:
        return ServiceException(
          code: 'not-acceptable',
          message: 'Could not perform action',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 408:
        return ServiceException(
          code: 'request-timeout',
          message: 'Request has timed out',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 422:
        return ServiceException(
          code: 'unprocessable-entity',
          message: 'Could not process due to possible semantic errors',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 428:
        return ServiceException(
          code: 'security-rejections',
          message: 'Security Rejections',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 429:
        return ServiceException(
          code: 'too-many-requests',
          message: 'Too many requests',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 500:
        return ServiceException(
          code: 'internal-server-error',
          message: 'Server has encountered issue',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 502:
        return ServiceException(
          code: 'bad-gateway',
          message: 'Server received invalid response',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 503:
        return ServiceException(
          code: 'server-unavailable',
          message: 'Server is not available',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      case 504:
        return ServiceException(
          code: 'gateway-timeout',
          message: 'Server has timed out',
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
      default:
        return ServiceException(
          code: statusCode.toString(),
          message: errorMessage,
          displayMessageKey: displayMessageKey,
          stackTrace: stackTrace,
        );
    }
  }
}

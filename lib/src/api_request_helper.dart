import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:hashids2/hashids2.dart';
import 'package:http/http.dart' as http;

/// {@template api_request_helper_flutter}
/// Api Request Helper Flutter is a repository that handles http calls such as
/// GET, POST, PUT, DELETE
/// {@endtemplate}
class ApiRequestHelper {
  /// {@macro api_request_helper_flutter}
  ApiRequestHelper();

  final _controller = StreamController<num>();

  /// X-API key
  final xApiKey = const String.fromEnvironment('XAPI_KEY');

  /// Convenient getter for status code
  Stream<num> get statusCode async* {
    yield* _controller.stream;
  }

  /// Convenient getter for encrypted date time
  String get xApiToken {
    const encryptionKey = String.fromEnvironment('XAPITOKEN_ENCRYPTION_KEY');

    final hashIds = HashIds(
      // ignore: avoid_redundant_argument_values
      salt: encryptionKey,
      minHashLength: 16,
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    return hashIds.encode(timestamp);
  }

  /// Calls GET api which will emit [Future] Map<String, dynamic>
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> get({
    required Uri uri,
    String? userToken,
    bool isResult = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    final response = await http
        .get(
          uri,
          headers: headers,
        )
        .timeout(const Duration(minutes: 1));
    return _returnResponse(response: response, isResult: isResult, uri: uri);
  }

  /// Calls POST api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> post({
    required Uri uri,
    required Map<String, dynamic> data,
    String? userToken,
    bool isResult = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));
    return _returnResponse(response: response, isResult: isResult, uri: uri);
  }

  /// Calls PATCH api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> patch({
    required Uri uri,
    required Map<String, dynamic> data,
    String? userToken,
    bool isResult = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    final response = await http
        .patch(
          uri,
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));
    return _returnResponse(response: response, isResult: isResult, uri: uri);
  }

  /// Calls PUT api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> put({
    required Uri uri,
    required Map<String, dynamic> data,
    String? userToken,
    bool isResult = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    final response = await http
        .put(
          uri,
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));
    return _returnResponse(response: response, isResult: isResult, uri: uri);
  }

  /// Calls DELETE api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> delete({
    required Uri uri,
    Map<String, dynamic>? data,
    String? userToken,
    bool isResult = true,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    final response = await http
        .delete(
          uri,
          headers: headers,
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));

    return _returnResponse(response: response, isResult: isResult, uri: uri);
  }

  /// Calls GET api which will emit [Future] of Uint8List
  ///
  /// Throws a ClientException if an error occurs
  Future<Uint8List> readBytes({
    required Uri uri,
    String? userToken,
  }) async {
    final byteFile = await http.readBytes(
      uri,
      headers: userToken != null
          ? {
              'Authorization': userToken,
            }
          : null,
    );
    return byteFile;
  }

  dynamic _returnResponse({
    required http.Response response,
    required Uri uri,
    bool isResult = true,
  }) {
    num statusCode = response.statusCode;
    final mappedResponse = json.decode(response.body) as Map<String, dynamic>;

    if (statusCode == 200 && mappedResponse['status'] != 200) {
      statusCode = num.parse(mappedResponse['status'].toString());
    }

    _controller.add(statusCode);

    final emoji = switch (statusCode) {
      != null && >= 200 && < 300 => '✅',
      != null && >= 300 && < 400 => '🟠',
      _ => '❌'
    };

    log('$emoji $statusCode $emoji -- $uri');
    log('$emoji body $emoji -- json: $mappedResponse, statusCode: '
        '${mappedResponse['status']}');

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
        final exception = _getException(
          statusCode: statusCode,
          errorMessage: mappedResponse['message'].toString(),
        );
        throw exception;
    }
  }

  ServiceException _getException({
    required num statusCode,
    String? errorMessage,
  }) {
    switch (statusCode) {
      case 301:
        return const ServiceException(
          code: 'invalid-credentials',
          message: 'Credentials are invalid',
        );
      case 400:
        return const ServiceException(
          code: 'bad-request',
          message: 'The server could not process the request',
        );
      case 401:
        return const ServiceException(
          code: 'unauthorized',
          message: 'Could not authorize user',
        );
      case 403:
        return const ServiceException(
          code: 'insufficient-permission',
          message: 'User do not have permission',
        );
      case 404:
        return const ServiceException(
          code: 'not-found',
          message: 'Could not retrieve resource',
        );
      case 405:
        return const ServiceException(
          code: 'method-not-allowed',
          message: 'Could not perform action',
        );
      case 406:
        return const ServiceException(
          code: 'not-acceptable',
          message: 'Could not perform action',
        );
      case 408:
        return const ServiceException(
          code: 'request-timeout',
          message: 'Request has timed out',
        );
      case 422:
        return const ServiceException(
          code: 'unprocessable-entity',
          message: 'Could not process due to possible semantic errors',
        );
      case 428:
        return const ServiceException(
          code: 'security-rejections',
          message: 'Security Rejections',
        );
      case 429:
        return const ServiceException(
          code: 'too-many-requests',
          message: 'Too many requests',
        );
      case 500:
        return const ServiceException(
          code: 'internal-server-error',
          message: 'Server has encountered issue',
        );
      case 502:
        return const ServiceException(
          code: 'bad-gateway',
          message: 'Server received invalid response',
        );
      case 503:
        return const ServiceException(
          code: 'server-unavailable',
          message: 'Server is not available',
        );
      case 504:
        return const ServiceException(
          code: 'gateway-timeout',
          message: 'Server has timed out',
        );
      default:
        throw ServiceException(
          code: statusCode.toString(),
          message: errorMessage,
        );
    }
  }

  /// Disposes status code stream controller
  void dispose() => _controller.close();
}

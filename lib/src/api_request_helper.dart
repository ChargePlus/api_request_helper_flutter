import 'dart:convert';

import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:http/http.dart' as http;

/// {@template api_request_helper_flutter}
/// Api Request Helper Flutter is a repository that handles http calls such as
/// GET, POST, PUT, DELETE
/// {@endtemplate}
class ApiRequestHelper {
  /// {@macro api_request_helper_flutter}
  const ApiRequestHelper();

  /// Calls GET api which will emit [Future] Map<String, dynamic>
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> get({
    required Uri uri,
    required String userToken,
  }) async {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': userToken,
      },
    ).timeout(const Duration(minutes: 1));
    return _returnResponse(response);
  }

  /// Calls POST api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> post({
    required Uri uri,
    required Map<String, dynamic> data,
    String? userToken,
  }) async {
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': userToken.toString(),
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));
    return _returnResponse(response);
  }

  /// Calls PUT api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> put({
    required Uri uri,
    required String userToken,
    required Map<String, dynamic> data,
  }) async {
    final response = await http
        .put(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': userToken,
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));
    return _returnResponse(response);
  }

  /// Calls DELETE api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> delete({
    required Uri uri,
    Map<String, dynamic>? data,
    required String userToken,
  }) async {
    final response = await http
        .delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': userToken,
          },
          body: jsonEncode(data),
        )
        .timeout(const Duration(minutes: 1));

    return _returnResponse(response);
  }

  dynamic _returnResponse(http.Response response) {
    num statusCode = response.statusCode;
    final mappedResponse = json.decode(response.body) as Map<String, dynamic>;

    if (statusCode == 200 && mappedResponse['status'] != 200) {
      statusCode = num.parse(mappedResponse['status'].toString());
    }

    switch (statusCode) {
      case 200:
      case 204:
        return mappedResponse['result'];
      case 301:
        throw const ServiceException(
          code: 'invalid-credentials',
          message: 'Credentials are invalid',
        );
      case 400:
        throw const ServiceException(
          code: 'bad-request',
          message: 'The server could not process the request',
        );
      case 401:
        throw const ServiceException(
          code: 'unauthorized',
          message: 'Could not authorize user',
        );
      case 403:
        throw const ServiceException(
          code: 'insufficient-permission',
          message: 'User do not have permission',
        );
      case 404:
        throw const ServiceException(
          code: 'not-found',
          message: 'Could not retrieve resource',
        );
      case 405:
        throw const ServiceException(
          code: 'method-not-allowed',
          message: 'Could not perform action',
        );
      case 408:
        throw const ServiceException(
          code: 'request-timeout',
          message: 'Request has timed out',
        );
      case 500:
        throw const ServiceException(
          code: 'internal-server-error',
          message: 'Server has encountered issue',
        );
      case 502:
        throw const ServiceException(
          code: 'bad-gateway',
          message: 'Server received invalid response',
        );
      case 503:
        throw const ServiceException(
          code: 'server-unavailable',
          message: 'Server is not available',
        );
      case 504:
        throw const ServiceException(
          code: 'gateway-timeout',
          message: 'Server has timed out',
        );
      default:
        throw ServiceException(
          code: response.statusCode.toString(),
          message: mappedResponse['message'].toString(),
        );
    }
  }
}

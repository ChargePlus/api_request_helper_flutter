import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:eventsource/eventsource.dart';
import 'package:exceptions_flutter/exceptions_flutter.dart';
import 'package:http/http.dart' as http;

/// {@template api_request_helper_flutter}
/// Api Request Helper Flutter is a repository that handles http calls such as
/// GET, POST, PUT, DELETE
/// {@endtemplate}
class ApiRequestHelper {
  /// {@macro api_request_helper_flutter}
  ApiRequestHelper();

  final _controller = StreamController<num>();

  /// Convenient getter for status code
  Stream<num>? get statusCode async* {
    yield* _controller.stream;
  }

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

  /// Connects to EventSource which emit [Future] EventSource
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<EventSource> eventSource({
    required Uri uri,
    required String userToken,
  }) async {
    try {
      final eventsource = await EventSource.connect(
        uri,
        headers: {
          'Authorization': userToken,
        },
      );

      return eventsource;
    } on EventSourceSubscriptionException catch (error) {
      final errorMessage = json.decode(error.message) as Map<String, dynamic>;
      final exception = _getException(
        statusCode: error.statusCode,
        errorMessage: errorMessage['message'] as String,
      );

      throw exception;
    }
  }

  dynamic _returnResponse(http.Response response) {
    num statusCode = response.statusCode;
    final mappedResponse = json.decode(response.body) as Map<String, dynamic>;

    log('ApiRequestHelper -- response status code: $statusCode');
    log('ApiRequestHelper -- body: $mappedResponse');

    if (statusCode == 200 && mappedResponse['status'] != 200) {
      statusCode = num.parse(mappedResponse['status'].toString());
    }

    log('ApiRequestHelper -- body status code: $statusCode');

    _controller.add(statusCode);

    switch (statusCode) {
      case 200:
      case 204:
        return mappedResponse['result'];
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

  /// Disposes authentication status stream controller
  void dispose() => _controller.close();
}

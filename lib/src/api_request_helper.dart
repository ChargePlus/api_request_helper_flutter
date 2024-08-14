import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:api_request_helper_flutter/api_request_helper_flutter.dart';
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
    ContentType contentType = ContentType.json,
  }) async {
    String responseBody;
    num statusCode;
    final headers = {
      'Content-Type': contentType.value,
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

    responseBody = response.body;
    statusCode = response.statusCode;

    log('Finish GET');

    return RequestFunctions.getResponse(
      responseBody: responseBody,
      statusCode: statusCode,
      isResult: isResult,
      uri: uri,
      statusController: _controller,
    );
  }

  /// Calls POST api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> post({
    required Uri uri,
    required Map<String, dynamic> data,
    Map<String, String>? fileData,
    String? userToken,
    bool isResult = true,
    ContentType contentType = ContentType.json,
  }) async {
    String responseBody;
    num statusCode;
    final headers = {
      'Content-Type': contentType.value,
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    if (contentType == ContentType.formData) {
      final request = await RequestFunctions.getMultipartRequest(
        uri: uri,
        data: data,
        method: 'POST',
        headers: headers,
        fileData: fileData,
      );

      final response = await request.send().timeout(const Duration(minutes: 1));

      statusCode = response.statusCode;
      responseBody = await response.stream.bytesToString();
    } else {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(minutes: 1));

      statusCode = response.statusCode;
      responseBody = response.body;
    }

    log('Finish POST');

    return RequestFunctions.getResponse(
      responseBody: responseBody,
      statusCode: statusCode,
      isResult: isResult,
      uri: uri,
      statusController: _controller,
    );
  }

  /// Calls PATCH api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> patch({
    required Uri uri,
    required Map<String, dynamic> data,
    Map<String, String>? fileData,
    String? userToken,
    bool isResult = true,
    ContentType contentType = ContentType.json,
  }) async {
    String responseBody;
    num statusCode;
    final headers = {
      'Content-Type': contentType.value,
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    if (contentType == ContentType.formData) {
      final request = await RequestFunctions.getMultipartRequest(
        uri: uri,
        data: data,
        method: 'PATCH',
        headers: headers,
        fileData: fileData,
      );

      final response = await request.send().timeout(const Duration(minutes: 1));

      statusCode = response.statusCode;
      responseBody = await response.stream.bytesToString();
    } else {
      final response = await http
          .patch(
            uri,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(minutes: 1));

      statusCode = response.statusCode;
      responseBody = response.body;
    }

    return RequestFunctions.getResponse(
      responseBody: responseBody,
      statusCode: statusCode,
      isResult: isResult,
      uri: uri,
      statusController: _controller,
    );
  }

  /// Calls PUT api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> put({
    required Uri uri,
    required Map<String, dynamic> data,
    Map<String, String>? fileData,
    String? userToken,
    bool isResult = true,
    ContentType contentType = ContentType.json,
  }) async {
    String responseBody;
    num statusCode;
    final headers = {
      'Content-Type': contentType.value,
      'x-api-token': xApiToken,
      'x-api-key': xApiKey,
    };

    if (userToken != null) {
      headers.addAll({'Authorization': userToken});
    }

    if (contentType == ContentType.formData) {
      final request = await RequestFunctions.getMultipartRequest(
        uri: uri,
        data: data,
        method: 'PUT',
        headers: headers,
        fileData: fileData,
      );

      final response = await request.send().timeout(const Duration(minutes: 1));

      statusCode = response.statusCode;
      responseBody = await response.stream.bytesToString();
    } else {
      final response = await http
          .put(
            uri,
            headers: headers,
            body: jsonEncode(data),
          )
          .timeout(const Duration(minutes: 1));

      statusCode = response.statusCode;
      responseBody = response.body;
    }

    return RequestFunctions.getResponse(
      responseBody: responseBody,
      statusCode: statusCode,
      isResult: isResult,
      uri: uri,
      statusController: _controller,
    );
  }

  /// Calls DELETE api which will emit [Future] dynamic
  ///
  /// Throws a [ServiceException] if response status code is not 200
  Future<dynamic> delete({
    required Uri uri,
    Map<String, dynamic>? data,
    String? userToken,
    bool isResult = true,
    ContentType contentType = ContentType.json,
  }) async {
    String responseBody;
    num statusCode;
    final headers = {
      'Content-Type': contentType.value,
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

    statusCode = response.statusCode;
    responseBody = response.body;

    return RequestFunctions.getResponse(
      responseBody: responseBody,
      statusCode: statusCode,
      isResult: isResult,
      uri: uri,
      statusController: _controller,
    );
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

  /// Disposes status code stream controller
  void dispose() => _controller.close();
}

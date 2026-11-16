import 'package:exceptions_flutter/exceptions_flutter.dart';

/// {@template api_service_exception}
/// A [ServiceException] that also carries the text the server sent.
///
/// For a 400 or 422 response the helper keeps the fixed [code] and [message]
/// every app already shows, and exposes the server's own text, for example a
/// validation message, in [serverMessage].
///
/// [serverMessage] is only set when the response body has a non-blank string
/// `message` (or `msg`). A missing, blank, map or list value leaves it null.
/// {@endtemplate}
class ApiServiceException extends ServiceException {
  /// {@macro api_service_exception}
  const ApiServiceException({
    super.code,
    super.message,
    super.displayMessageKey,
    super.stackTrace,
    this.serverMessage,
  });

  /// The message the server sent, or null when the body had none usable.
  final String? serverMessage;

  @override
  List<Object?> get props => [...super.props, serverMessage];
}

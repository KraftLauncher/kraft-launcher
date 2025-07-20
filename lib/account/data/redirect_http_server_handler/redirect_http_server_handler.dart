import 'package:kraft_launcher/account/data/redirect_http_server_handler/redirect_http_server_handler_failures.dart';
import 'package:kraft_launcher/common/models/result.dart';

/// Starts a temporary HTTP server that handles a single request, and then the
/// server will be closed.
///
/// This server only receives the redirect, it doesn't perform it.
/// The OAuth provider (e.g., Microsoft or GitHub) is responsible for
/// redirecting the user's browser to this local server.
///
/// Used to receive OAuth redirect responses from Microsoft
/// when implementing the Microsoft auth code flow.
///
/// During login via Microsoft auth code, the user signs in through the browser,
/// and Microsoft then redirects the success or failure result to this
/// temporary HTTP server with the query parameters.
///
/// ```dart
/// final RedirectHttpServerHandler handler = ...;
/// final result = await handler.start(port: ...);
/// if (result.isFailure) {
///   // Failed to launch the server.
///   return;
/// }
/// final queryParams = await handler.waitForRequest();
/// if (queryParams == null) {
///   // Server was closed before the first request is received.
///   return;
/// }
///
/// // Build the HTML content from the received query parameters.
/// final String html = ...;
///
/// await handler.respondAndClose();
/// ```
abstract interface class RedirectHttpServerHandler {
  /// Whether the HTTP server is currently running.
  bool get isRunning;

  /// Starts the HTTP server on the given [port].
  ///
  /// Returns a [Result] that contains a [StartServerFailure] if the
  /// server fails to start.
  ///
  /// Throws a [StateError] if called when the server is already running.
  Future<EmptyResult<StartServerFailure>> start({required int port});

  /// Waits for the first incoming HTTP request.
  ///
  /// This method should only be called after the server has been started:
  ///
  /// ```dart
  /// final started = (await start(port: ...)).isSuccess;
  /// if (started) {
  ///   waitForRequest();
  /// }
  /// ```
  ///
  /// Throws a [StateError] if:
  ///
  /// * the server is not running, either because
  /// [start] was not called successfully, or it was closed via [respondAndClose].
  /// * it is called more than once without closing the server or responding with [respondAndClose].
  ///
  /// Also, throws a [StateError] is called twice without closing the server
  /// or responding with [respondAndClose].
  ///
  /// Returns the query parameters from the request, or `null` if the server
  /// is closed before receiving a request.
  Future<Map<String, String>?> waitForRequest();

  /// Sends an HTML response to the received request and closes the server.
  ///
  /// Must only be called after [waitForRequest] returns a non-null value:
  ///
  /// ```dart
  /// final queryParams = await waitForRequest();
  /// if (queryParams == null) {
  ///   // Server was closed before the first request is received.
  ///   return;
  /// }
  ///
  /// respondAndClose(...);
  /// ```
  ///
  /// Throws a [StateError] if called before a successful call to [waitForRequest],
  /// or if it returned `null` (i.e., no request was received).
  Future<void> respondAndClose(String html);

  /// Closes the HTTP server **without sending any HTTP response**.
  ///
  /// This aborts any ongoing requests by closing the server socket.
  /// No HTTP response will be sent to the client for any pending requests.
  ///
  /// This method aborts any ongoing requests by closing the server without responding.
  /// If the server is not running, this method completes immediately with no effect (no-op).
  ///
  /// **Note:** This performs a graceful shutdown of the server, not a forceful termination.
  Future<void> close();
}

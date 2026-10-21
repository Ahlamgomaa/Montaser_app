import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_failure.dart';
import 'token_store.dart';

/// The one place that talks to the server.
///
/// Every call in the app goes through here, and this is the only file that
/// knows what the server's replies look like. That is the point: the API
/// answers everything in one envelope —
///
///     { "success": true, "message": null, "data": ..., "meta": ..., "errors": ... }
///
/// — and the day that changes, it changes here rather than in forty callers.
/// Repositories above this line receive `data` already unwrapped, or an
/// [ApiFailure] already sorted into a kind they can act on.
class ApiClient {
  ApiClient({http.Client? over, TokenStore? tokens})
    : _http = over ?? http.Client(),
      _tokens = tokens ?? TokenStore.instance;

  final http.Client _http;
  final TokenStore _tokens;

  /// How long to wait before giving up.
  ///
  /// Short enough that a customer on a bad connection sees a message rather
  /// than a spinner that never resolves; long enough that a slow first request
  /// against a cold server is not called a failure.
  static const _patience = Duration(seconds: 20);

  /// Called when the server says the token is no longer good.
  ///
  /// Set once by the session store. The client cannot sign anybody out itself —
  /// it has no idea what a session is — but it is the only thing that sees the
  /// 401, so it reports it and lets whoever owns the session decide.
  void Function()? onTokenRejected;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) =>
      _send('DELETE', path, body: body);

  /// A paged call, handing back the rows and the page position together.
  Future<Paged> page(String path, {Map<String, dynamic>? query}) async {
    final envelope = await _send('GET', path, query: query, whole: true);

    if (envelope is! Map<String, dynamic>) {
      throw const ApiFailure(
        kind: FailureKind.unknown,
        message: 'رد غير متوقع من السيرفر.',
      );
    }

    return Paged(
      rows: (envelope['data'] as List<dynamic>? ?? const []),
      meta: (envelope['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }

  /// The whole envelope, for the two calls that need something beside `data` —
  /// the token on sign-in, and `available` on a stock refusal.
  Future<Map<String, dynamic>> envelope(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    final result = await _send(method, path, body: body, query: query, whole: true);

    return result is Map<String, dynamic> ? result : <String, dynamic>{};
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool whole = false,
  }) async {
    final base = ApiConfig.instance.baseUrl;

    if (base == null) {
      throw const ApiFailure(
        kind: FailureKind.notConfigured,
        message: 'لم يُضبط عنوان السيرفر بعد.',
      );
    }

    final url = Uri.parse('$base/$path').replace(
      queryParameters: _asStrings(query),
    );

    http.Response reply;

    try {
      final request = http.Request(method, url)
        ..headers.addAll(await _headers(sending: body != null));

      if (body != null) {
        request.body = jsonEncode(body);
      }

      final streamed = await _http.send(request).timeout(_patience);
      reply = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiFailure(
        kind: FailureKind.timeout,
        message: 'السيرفر تأخّر في الرد. حاول مرة أخرى.',
      );
    } on SocketException {
      throw const ApiFailure(
        kind: FailureKind.offline,
        message: 'لا يوجد اتصال بالإنترنت.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        kind: FailureKind.offline,
        message: 'تعذّر الوصول إلى السيرفر.',
      );
    }

    return _read(reply, whole: whole);
  }

  dynamic _read(http.Response reply, {required bool whole}) {
    Map<String, dynamic> envelope;

    try {
      final decoded = jsonDecode(utf8.decode(reply.bodyBytes));

      envelope = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      /*
       * The body was not JSON at all. In practice this is a proxy error page or
       * a PHP fatal rendered as HTML — which is a server fault however it is
       * dressed, and saying so is more use than showing the customer the first
       * hundred characters of an HTML document.
       */
      throw ApiFailure(
        kind: reply.statusCode >= 500 ? FailureKind.server : FailureKind.unknown,
        status: reply.statusCode,
        message: 'رد غير مفهوم من السيرفر.',
      );
    }

    final ok = envelope['success'] == true && reply.statusCode < 400;

    if (ok) {
      return whole ? envelope : envelope['data'];
    }

    throw _failureFrom(reply.statusCode, envelope);
  }

  ApiFailure _failureFrom(int status, Map<String, dynamic> envelope) {
    final said = envelope['message'];
    final message = said is String && said.trim().isNotEmpty
        ? said
        : _wordsFor(status);

    if (status == 401) {
      /*
       * Reported rather than acted on. The client has no idea what a session
       * is; it only knows the server stopped honouring the token, and the
       * thing that owns the session decides what that means.
       */
      onTokenRejected?.call();
    }

    return ApiFailure(
      kind: _kindFor(status),
      status: status,
      message: message,
      errors: _complaints(envelope['errors']),
      extra: {
        for (final entry in envelope.entries)
          if (!const {'success', 'message', 'data', 'errors'}.contains(entry.key))
            entry.key: entry.value,
      },
    );
  }

  static FailureKind _kindFor(int status) {
    return switch (status) {
      401 => FailureKind.unauthenticated,
      403 => FailureKind.forbidden,
      404 => FailureKind.missing,
      409 => FailureKind.conflict,
      422 => FailureKind.validation,
      429 => FailureKind.throttled,
      >= 500 => FailureKind.server,
      _ => FailureKind.unknown,
    };
  }

  /// Only for the case where the server said nothing — which should not happen,
  /// because every refusal it makes carries a sentence.
  static String _wordsFor(int status) {
    return switch (status) {
      401 => 'سجّل الدخول أولاً.',
      403 => 'لا تملك صلاحية هذا الإجراء.',
      404 => 'غير موجود.',
      409 => 'تغيّرت السلة. راجعها ثم أعد المحاولة.',
      429 => 'محاولات كثيرة. حاول بعد قليل.',
      >= 500 => 'عطل في السيرفر. حاول بعد قليل.',
      _ => 'تعذّر إتمام الطلب.',
    };
  }

  /// Laravel keys its complaints by field and sends a list per field. An empty
  /// object arrives as `{}` and a missing one as null; both mean the same
  /// thing here.
  static Map<String, List<String>> _complaints(dynamic raw) {
    if (raw is! Map) {
      return const {};
    }

    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value is List
            ? (entry.value as List).map((one) => one.toString()).toList()
            : [entry.value.toString()],
    };
  }

  Future<Map<String, String>> _headers({required bool sending}) async {
    final token = await _tokens.read();

    return {
      'Accept': 'application/json',
      /*
       * Sent on every request. Laravel reads it, so the validation messages and
       * the refusals come back in Arabic from the one place the shop keeps its
       * words — the app never writes a second copy of a sentence the website
       * already says.
       */
      'Accept-Language': 'ar',
      if (sending) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Query values go on the wire as text. Nulls are dropped rather than sent as
  /// the string "null", which is what `toString()` would do and what would make
  /// a filter for nothing filter for something.
  static Map<String, String>? _asStrings(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) {
      return null;
    }

    final pairs = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };

    return pairs.isEmpty ? null : pairs;
  }

  void close() => _http.close();
}

/// A page of rows, and where in the list it sits.
class Paged {
  const Paged({required this.rows, required this.meta});

  final List<dynamic> rows;
  final Map<String, dynamic> meta;

  int get currentPage => (meta['current_page'] as num?)?.toInt() ?? 1;

  int get lastPage => (meta['last_page'] as num?)?.toInt() ?? 1;

  int get total => (meta['total'] as num?)?.toInt() ?? rows.length;

  bool get hasMore => meta['has_more'] == true || currentPage < lastPage;
}

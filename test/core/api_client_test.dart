import 'dart:convert';
import 'dart:typed_data';

import 'package:dcpl_admin/core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}

/// A Dio adapter that returns whatever [handler] produces — no real network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);
}

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late MockAuthService auth;
  late Dio dio;

  setUp(() {
    auth = MockAuthService();
    when(() => auth.idToken()).thenAnswer((_) async => 'tok');
    dio = Dio(BaseOptions(baseUrl: 'http://test.local'));
  });

  ApiClient client() => ApiClient(auth, dio: dio);

  test('get() returns the decoded body and attaches the bearer token', () async {
    RequestOptions? sent;
    dio.httpClientAdapter = _FakeAdapter((options) async {
      sent = options;
      return _json({'ok': true}, 200);
    });

    final res = await client().get('/health');

    expect(res, {'ok': true});
    expect(sent!.headers['Authorization'], 'Bearer tok');
  });

  test('post() returns the decoded body', () async {
    dio.httpClientAdapter = _FakeAdapter((options) async => _json({'id': '1'}, 201));

    final res = await client().post('/projects', body: {'particular': 'Lobby'});

    expect(res, {'id': '1'});
  });

  test('maps the backend error envelope to ApiException', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (options) async => _json({
        'error': {'message': 'bad input'},
      }, 400),
    );

    await expectLater(
      client().get('/x'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.message, 'message', 'bad input')),
    );
  });

  test('maps a connection error to a friendly ApiException', () async {
    dio.httpClientAdapter = _FakeAdapter(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      client().get('/x'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 0)
          .having(
            (e) => e.message,
            'message',
            'Cannot reach the server. Is the backend running?',
          )),
    );
  });
}

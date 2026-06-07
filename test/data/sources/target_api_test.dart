import 'dart:convert';

import 'package:beacon_app/data/models/target.dart';
import 'package:beacon_app/data/sources/target_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final endpoint = Uri.parse('https://example.test/target.json');

  TargetApi apiReturning(http.Response Function(http.Request request) handler) =>
      TargetApi(
        client: MockClient((req) async => handler(req)),
        endpoint: endpoint,
      );

  test('parses a 200 response into a Target', () async {
    final api = apiReturning(
      (_) => http.Response(
        jsonEncode({'id': '001', 'target_lat': 1.265, 'target_lng': 103.695}),
        200,
      ),
    );
    expect(
      await api.fetchTarget(),
      const Target(id: '001', latitude: 1.265, longitude: 103.695),
    );
  });

  test('throws on a non-200 status', () {
    final api = apiReturning((_) => http.Response('not found', 404));
    expect(api.fetchTarget(), throwsA(isA<TargetApiException>()));
  });

  test('throws on malformed JSON', () {
    final api = apiReturning((_) => http.Response('{not json', 200));
    expect(api.fetchTarget(), throwsA(isA<TargetApiException>()));
  });

  test('throws when the payload is missing fields', () {
    final api =
        apiReturning((_) => http.Response(jsonEncode({'id': '001'}), 200));
    expect(api.fetchTarget(), throwsA(isA<TargetApiException>()));
  });

  test('throws when the payload is a JSON array, not an object', () {
    final api = apiReturning((_) => http.Response(jsonEncode([1, 2, 3]), 200));
    expect(api.fetchTarget(), throwsA(isA<TargetApiException>()));
  });

  test('wraps network errors', () {
    final api = TargetApi(
      client: MockClient((_) async => throw http.ClientException('boom')),
      endpoint: endpoint,
    );
    expect(api.fetchTarget(), throwsA(isA<TargetApiException>()));
  });
}

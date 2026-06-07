import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/target.dart';

/// Default mock endpoint — the target JSON hosted on the project's GitHub repo.
/// Pass `endpoint` to [TargetApi] to point at a local server or another mock.
const String defaultTargetEndpoint =
    'https://raw.githubusercontent.com/kulotski321/Beacon-app/main/mock/target.json';

/// Thrown when the target cannot be fetched or parsed.
class TargetApiException implements Exception {
  const TargetApiException(this.message);

  final String message;

  @override
  String toString() => 'TargetApiException: $message';
}

/// Fetches the tracking [Target] from the mock backend (FR-1).
class TargetApi {
  TargetApi({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _endpoint = endpoint ?? Uri.parse(defaultTargetEndpoint);

  final http.Client _client;
  final Uri _endpoint;
  final Duration timeout;

  Future<Target> fetchTarget() async {
    final http.Response response;
    try {
      response = await _client.get(_endpoint).timeout(timeout);
    } on TimeoutException {
      throw const TargetApiException('Request timed out');
    } catch (e) {
      throw TargetApiException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw TargetApiException('Unexpected status code ${response.statusCode}');
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      return Target.fromJson(decoded);
    } on FormatException catch (e) {
      throw TargetApiException('Malformed target payload: ${e.message}');
    }
  }
}

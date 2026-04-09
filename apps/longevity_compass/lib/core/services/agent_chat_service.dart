import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AgentChatException implements Exception {
  const AgentChatException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AgentChatEvent {
  const AgentChatEvent._({
    required this.text,
    required this.isDone,
  });

  const AgentChatEvent.delta(String text)
      : this._(
          text: text,
          isDone: false,
        );

  const AgentChatEvent.done()
      : this._(
          text: '',
          isDone: true,
        );

  final String text;
  final bool isDone;
}

class AgentChatService {
  AgentChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    if (AppConfig.agentBaseUrl.trim().isEmpty) {
      throw const AgentChatException(
        'Agent URL is not configured. Set APP_AGENT_BASE_URL.',
      );
    }
    if (AppConfig.agentBaseUrl.endsWith('/')) {
      return AppConfig.agentBaseUrl.substring(
        0,
        AppConfig.agentBaseUrl.length - 1,
      );
    }
    return AppConfig.agentBaseUrl;
  }

  String get _chatPath {
    final value = AppConfig.agentChatPath.trim();
    if (value.isEmpty) {
      return '/chat/stream';
    }
    return value.startsWith('/') ? value : '/$value';
  }

  String get _jsonChatPath => '/chat';

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Future<String> requestReplyText({
    required String message,
    required String patientId,
  }) async {
    late final http.Response response;
    try {
      response = await _client.post(
        _uri(_jsonChatPath),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'patient_id': patientId,
        }),
      );
    } on Exception catch (error) {
      throw AgentChatException(
        'Agent request could not be sent. $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AgentChatException(
        _decodeErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final payload = _decodeJson(response.body);
    final sections = payload['sections'];
    if (sections is Iterable) {
      final items = sections
          .whereType<Object>()
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (items.isNotEmpty) {
        return items.join('\n\n');
      }
    }

    final reply = payload['reply']?.toString().trim() ?? '';
    if (reply.isNotEmpty) {
      return reply;
    }

    throw const AgentChatException(
      'Agent response did not include any visible reply sections.',
    );
  }

  Stream<AgentChatEvent> streamReply({
    required String message,
    String patientId = AppConfig.demoPatientId,
    bool includeEvidenceIndex = false,
  }) async* {
    if (_chatPath == '/health') {
      yield* _streamHealthCheck();
      return;
    }

    final request = http.Request('POST', _uri(_chatPath))
      ..headers.addAll(const {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode({
        'message': message,
        'patient_id': patientId,
        'include_evidence_index': includeEvidenceIndex,
      });

    late final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } on Exception catch (error) {
      throw AgentChatException(
        'Agent request could not be sent. $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw AgentChatException(
        _decodeErrorBody(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    String? currentEvent;
    final dataLines = <String>[];

    await for (final line
        in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('event:')) {
        currentEvent = line.substring(6).trim();
        continue;
      }

      if (line.startsWith('data:')) {
        dataLines.add(line.substring(5).trimLeft());
        continue;
      }

      if (line.isEmpty && dataLines.isNotEmpty) {
        yield* _handleEvent(currentEvent, dataLines.join('\n'));
        currentEvent = null;
        dataLines.clear();
      }
    }

    if (dataLines.isNotEmpty) {
      yield* _handleEvent(currentEvent, dataLines.join('\n'));
    }
  }

  Stream<AgentChatEvent> _streamHealthCheck() async* {
    late final http.Response response;
    try {
      final proxyUri = Uri.parse(
        '${_normalizeBaseUrl(AppConfig.apiBaseUrl)}/agent/health-proxy',
      ).replace(
        queryParameters: {
          'target': _baseUrl,
        },
      );

      response = await _client.get(
        proxyUri,
        headers: const {
          'Accept': 'application/json',
        },
      );
    } on Exception catch (error) {
      throw AgentChatException(
        'Agent health request could not be sent. $error',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AgentChatException(
        _decodeErrorBody(response.body, response.statusCode),
        statusCode: response.statusCode,
      );
    }

    final payload = _decodeJson(response.body);
    final statusCode = payload['status_code']?.toString() ?? '?';
    final body = payload['body'];
    final status = body is Map<String, dynamic>
        ? body['status']?.toString() ?? 'ok'
        : body?.toString() ?? 'ok';
    yield AgentChatEvent.delta(
      'Agent health endpoint responded with status "$status" (HTTP $statusCode).',
    );
    yield const AgentChatEvent.done();
  }

  String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  Stream<AgentChatEvent> _handleEvent(String? eventName, String rawData) async* {
    switch (eventName) {
      case 'delta':
        final payload = _decodeJson(rawData);
        final text = payload['text']?.toString() ?? '';
        if (text.isNotEmpty) {
          yield AgentChatEvent.delta(text);
        }
        break;
      case 'section':
        yield const AgentChatEvent.delta('\n\n');
        break;
      case 'done':
        yield const AgentChatEvent.done();
        break;
      default:
        break;
    }
  }

  Map<String, dynamic> _decodeJson(String rawData) {
    try {
      final dynamic decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed SSE events and fall back to an empty map.
    }
    return const <String, dynamic>{};
  }

  String _decodeErrorBody(String body, int statusCode) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Fall back to a generic message below.
    }
    return 'Agent request failed with status $statusCode.';
  }

  void dispose() {
    _client.close();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class AgentDebugLog {
  static const String _sessionId = '24574d';

  // Provided by debug harness.
  static const String _path = '/ingest/718fbab7-b0f8-4477-b49b-9662ff9017b6';
  static const int _port = 7893;

  static Future<void> log({
    required String location,
    required String message,
    required String runId,
    required String hypothesisId,
    Map<String, Object?> data = const {},
  }) async {
    if (kIsWeb) {
      return;
    }

    final payload = <String, Object?>{
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      'data': data,
      'runId': runId,
      'hypothesisId': hypothesisId,
    };

    // Try both common dev-host routes:
    // - 127.0.0.1 for desktop/iOS sim
    // - 10.0.2.2 for Android emulator host loopback
    final hosts = <String>[
      if (Platform.isAndroid) '10.0.2.2',
      '127.0.0.1',
    ];

    for (final host in hosts) {
      try {
        final client = HttpClient();
        final req = await client.post(host, _port, _path);
        req.headers.contentType = ContentType.json;
        req.headers.set('X-Debug-Session-Id', _sessionId);
        req.add(utf8.encode(jsonEncode(payload)));
        final res = await req.close();
        await res.drain();
        client.close(force: true);
        return; // success
      } catch (_) {
        // try next host
      }
    }
  }
}


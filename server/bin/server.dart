import 'dart:io';

import 'package:mahjong_server/room_manager.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final manager = RoomManager();

  final server = await HttpServer.bind('0.0.0.0', port);
  // ignore: avoid_print
  print('Mahjong server running on port $port');

  await for (final request in server) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      try {
        final ws = await WebSocketTransformer.upgrade(request);
        manager.handleConnection(ws);
      } catch (e) {
        // ignore: avoid_print
        print('WebSocket upgrade error: $e');
      }
    } else {
      // Health check endpoint
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.text
        ..write('mahjong server ok')
        ..close();
    }
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../i18n/strings.dart';
import '../models/table_state.dart';
import '../models/table_action.dart';

// ─── Language provider ─────────────────────────────────────

final langProvider = StateProvider<Lang>((ref) => Lang.zh);

// ─── Connection state ──────────────────────────────────────

enum ConnectionStatus { disconnected, connecting, connected }

class RoomConnection {
  final ConnectionStatus status;
  final String? roomCode;
  final int? mySeat;
  final String? error;

  const RoomConnection({
    this.status = ConnectionStatus.disconnected,
    this.roomCode,
    this.mySeat,
    this.error,
  });

  RoomConnection copyWith({
    ConnectionStatus? status,
    String? Function()? roomCode,
    int? Function()? mySeat,
    String? Function()? error,
  }) {
    return RoomConnection(
      status: status ?? this.status,
      roomCode: roomCode != null ? roomCode() : this.roomCode,
      mySeat: mySeat != null ? mySeat() : this.mySeat,
      error: error != null ? error() : this.error,
    );
  }
}

// ─── Lobby state ───────────────────────────────────────────

class LobbySeat {
  final String nickname;
  final bool isHost;
  const LobbySeat({required this.nickname, required this.isHost});
}

class LobbyState {
  final List<LobbySeat?> seats;
  const LobbyState({this.seats = const [null, null, null, null]});
}

// ─── Objection notification ────────────────────────────────

class ObjectionNotification {
  final int seat;
  final String nickname;
  final String message;
  final DateTime timestamp;

  ObjectionNotification({
    required this.seat,
    required this.nickname,
    required this.message,
  }) : timestamp = DateTime.now();
}

// ─── Multiplayer notifier ──────────────────────────────────

class MultiplayerNotifier extends StateNotifier<RoomConnection> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final Ref _ref;

  MultiplayerNotifier(this._ref) : super(const RoomConnection());

  void connect(String url) {
    disconnect();
    state = state.copyWith(
      status: ConnectionStatus.connecting,
      error: () => null,
    );

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: (e) {
          state = state.copyWith(
            status: ConnectionStatus.disconnected,
            error: () => e.toString(),
          );
        },
        onDone: () {
          state = state.copyWith(
            status: ConnectionStatus.disconnected,
          );
        },
      );
      state = state.copyWith(status: ConnectionStatus.connected);
    } catch (e) {
      state = state.copyWith(
        status: ConnectionStatus.disconnected,
        error: () => e.toString(),
      );
    }
  }

  void createRoom(String nickname) {
    _send(ServerMessage.createRoom(nickname));
  }

  void joinRoom(String code, String nickname) {
    _send(ServerMessage.joinRoom(code, nickname));
  }

  void startGame() {
    _send(ServerMessage.startGame());
  }

  void sendAction(String actionJson) {
    _send(actionJson);
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    state = const RoomConnection();
    _ref.read(lobbyProvider.notifier).state = const LobbyState();
    _ref.read(tableStateProvider.notifier).state = null;
  }

  void _send(String msg) {
    _channel?.sink.add(msg);
  }

  void _onMessage(dynamic data) {
    try {
      final msg = jsonDecode(data as String) as Map<String, dynamic>;
      final type = msg['type'] as String;

      switch (type) {
        case 'joined':
          state = state.copyWith(
            roomCode: () => msg['code'] as String,
            mySeat: () => msg['seat'] as int,
            error: () => null,
          );

        case 'lobby':
          final seats = (msg['seats'] as List).map((s) {
            if (s == null) return null;
            final m = s as Map<String, dynamic>;
            return LobbySeat(
              nickname: m['nickname'] as String,
              isHost: m['isHost'] as bool? ?? false,
            );
          }).toList();
          _ref.read(lobbyProvider.notifier).state =
              LobbyState(seats: seats);

        case 'state':
          final tableState = TableState.fromJson(
              msg['state'] as Map<String, dynamic>);
          _ref.read(tableStateProvider.notifier).state = tableState;

        case 'objection':
          _ref.read(objectionProvider.notifier).state =
              ObjectionNotification(
            seat: msg['seat'] as int,
            nickname: msg['nickname'] as String,
            message: msg['message'] as String? ?? '',
          );

        case 'playerLeft':
          // Lobby update will follow
          break;

        case 'error':
          state = state.copyWith(
            error: () => msg['message'] as String?,
          );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Message parse error: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// ─── Providers ─────────────────────────────────────────────

final multiplayerProvider =
    StateNotifierProvider<MultiplayerNotifier, RoomConnection>(
  (ref) => MultiplayerNotifier(ref),
);

final lobbyProvider = StateProvider<LobbyState>((ref) => const LobbyState());

final tableStateProvider = StateProvider<TableState?>((ref) => null);

final objectionProvider = StateProvider<ObjectionNotification?>((ref) => null);

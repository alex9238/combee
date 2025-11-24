import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// CONFIG
const String signalingServerUrl =
    "wss://walkie.com-mx.com.mx/ws"; // ajusta si hace falta
//const String turnServerIp = "216.238.71.202";
const String turnServerIp = "turn.com-mx.com.mx";
//const String localUserName = "18_20";

// ------------------ Provider ------------------

class WalkieTalkieProvider with ChangeNotifier {
  String localUserName = "xxx";

  WebSocketChannel? _channel;
  MediaStream? _localStream;

  final Map<String, RTCPeerConnection> _pcs = {};
  final Map<String, MediaStream> _remoteStreams = {};

  List<String> _connectedUsers = [];
  String? _selectedUser; // null = Todos
  String? _incomingSpeaker;
  bool _isSpeaking = false;

  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;

  List<String> get connectedUsers => _connectedUsers;
  bool get isSpeaking => _isSpeaking;
  String? get incomingSpeaker => _incomingSpeaker;
  bool get wsConnected => _channel != null;
  int get peerCount => _pcs.length;
  bool get hasActivePeer => _pcs.isNotEmpty;

  List<String> get connectedUsersWithAll => ['Todos'] + _connectedUsers;
  String get selectedUserDisplay =>
      _selectedUser == null ? 'Todos' : _selectedUser!;

  /*final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:$turnServerIp:3478',
        'username': 'testturn',
        'credential': 'turn2025',
      },
    ],
  };*/

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},

      {
        'urls': [
          'turn:$turnServerIp:3478?transport=udp',
          'turn:$turnServerIp:3478?transport=tcp',
          'turns:$turnServerIp:5349',
        ],
        'username': 'testturn',
        'credential': 'turn2025',
      },
    ],
  };

  /*Future<void> _configureAudioForSpeaker() async {
    await Helper.setSpeakerphoneOn(true);

    await Helper.setAppleAudioConfiguration(
      AppleAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.defaultToSpeaker,
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
        },
        appleAudioMode: AppleAudioMode.voiceChat,
      ),
    );
  }*/

  Future<void> _configureAudioForSpeaker() async {
    await Helper.setAppleAudioConfiguration(
      AppleAudioConfiguration(
        appleAudioCategory: AppleAudioCategory.playAndRecord,
        appleAudioCategoryOptions: {
          AppleAudioCategoryOption.defaultToSpeaker,
          AppleAudioCategoryOption.allowBluetooth,
          AppleAudioCategoryOption.allowBluetoothA2DP,
          AppleAudioCategoryOption.mixWithOthers,
        },
        appleAudioMode: AppleAudioMode.voiceChat,
      ),
    );

    // iOS: forzar salida a altavoz
    await Helper.setSpeakerphoneOn(true);
  }


  Future<void> initLocalStream() async {
    
    await _configureAudioForSpeaker();
    await _setupLocalStream();
  }

  // Connect + auto-reconnect
  Future<void> connect(String local_user) async {
    await _configureAudioForSpeaker();
    await _setupLocalStream();

    if (_channel != null) return;

    try {
      _manuallyClosed = false;
      _channel = WebSocketChannel.connect(Uri.parse(signalingServerUrl));

      _channel!.stream.listen(
        _onMessageReceived,
        onDone: () async {
          await _cleanupChannelOnly();
          _autoReconnect();
        },
        onError: (err) async {
          await _cleanupChannelOnly();
          _autoReconnect();
        },
      );
      localUserName = local_user;
      _reconnectAttempts = 0;
      _sendJson({'type': 'register', 'name': localUserName});

      // after reconnect restore peers
      Future.delayed(const Duration(milliseconds: 500), () {
        _restoreSelectedPeerAfterReconnect();
      });

      notifyListeners();
    } catch (e) {
      await _cleanupChannelOnly();
      _autoReconnect();
    }
  }

  Future<void> _autoReconnect() async {
    if (_manuallyClosed) return;
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 30);
    await Future.delayed(Duration(seconds: delaySeconds));
    await connect(localUserName);
  }

  Future<void> reconnectNow() async {
    await _cleanupChannelOnly();
    _reconnectAttempts = 0;
    await connect(localUserName);
  }

  Future<void> _cleanupChannelOnly() async {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    notifyListeners();
  }

  Future<void> _cleanupAll() async {
    await _cleanupChannelOnly();
    await closeAllPeerConnections();
    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    _connectedUsers = [];
    _selectedUser = null;
    notifyListeners();
  }

  void _sendJson(Map<String, dynamic> map) {
    try {
      _channel?.sink.add(jsonEncode(map));
    } catch (e) {
      // ignore
    }
  }

  Future<void> _setupLocalStream() async {
    if (_localStream != null) return;
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (var t in _localStream!.getAudioTracks())
        t.enabled = false; // mute by default
    } catch (e) {
      print('Error obtaining local media: $e');
    }
  }

  // Selection ya funciona
  /*Future<void> setSelectedUserFromDisplay(String display) async {
    if (display == 'Todos') {
      _selectedUser = null;
      notifyListeners();

      // create mesh peers immediately
      for (var peer in _connectedUsers) {
        if (peer == localUserName) continue;
        if (!_pcs.containsKey(peer)) {
          await startPeerWith(peer);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
      return;
    }

    _selectedUser = display;
    notifyListeners();

    if (!_pcs.containsKey(display)) {
      await startPeerWith(display);
    }
  }*/

  // ------------------ Reemplazo: setSelectedUserFromDisplay ------------------
  Future<void> setSelectedUserFromDisplay(String display) async {
    if (display == 'Todos') {
      _selectedUser = null;
      notifyListeners();

      // crear mesh peers inmediatamente (si no existen)
      for (var peer in _connectedUsers) {
        if (peer == localUserName) continue;
        if (!_pcs.containsKey(peer)) {
          await startPeerWith(peer);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
      return;
    }

    // seleccionar usuario concreto: cerrar peers que no sean ese
    _selectedUser = display;
    notifyListeners();

    // cerrar todos excepto el seleccionado (IMPORTANTE)
    await _closeAllExcept(_selectedUser);

    // garantizar peer con el seleccionado
    if (!_pcs.containsKey(display)) {
      await startPeerWith(display);
      // pequeña espera para que se negocie offer/answer (ajusta si necesitas más tiempo)
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /*String peerStatus(String user) {
    /*if (_pcs.containsKey(user)) {
      final pc = _pcs[user];
      if (pc != null) {
        return pc.iceConnectionState.toString().split('.').last;
      }
      return "Connected";
    }
    return "NotConnected";*/
    if (!_pcs.containsKey(user)) return "❌ No conectado";

    switch (_pcs[user]!.iceConnectionState) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        return "🟢 Conectado";
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        return "🟡 Conectando…";
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return "🔴 Desconectado";
      default:
        return "⚪ Esperando";
    }
  }*/

  String peerStatus(String user) {
    if (!_pcs.containsKey(user)) {
      return "❌ No conectado";
    }

    final state = _pcs[user]!.iceConnectionState;

    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        return "🟢 Conectado";

      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        return "🟡 Conectando…";

      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return "🔴 Desconectado";

      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        return "⚠️ Error";

      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        return "⚫ Cerrado";

      default:
        return "⚪ Esperando";
    }
  }

  // Create peer
  Future<RTCPeerConnection> _createPeer(
    String peerName, {
    bool isInitiator = false,
  }) async {
    final pc = await createPeerConnection(_iceServers);

    // add local tracks
    final tracks = _localStream?.getTracks() ?? [];
    for (var t in tracks) {
      try {
        await pc.addTrack(t, _localStream!);
      } catch (e) {
        // ignore
      }
    }

    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendJson({
          'to': peerName,
          'from': localUserName,
          'type': 'candidate',
          'data': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[peerName] = event.streams[0];
        _incomingSpeaker = peerName;
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          if (_incomingSpeaker == peerName && !_isSpeaking) {
            _incomingSpeaker = null;
            notifyListeners();
          }
        });
      }
    };

    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        closePeerConnection(peerName);
      }
    };

    _pcs[peerName] = pc;
    notifyListeners();
    return pc;
  }

  Future<void> startPeerWith(String peerName) async {
    if (_pcs.containsKey(peerName)) return;
    try {
      final pc = await _createPeer(peerName, isInitiator: true);
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _sendJson({
        'to': peerName,
        'from': localUserName,
        'type': 'offer',
        'data': offer.toMap(),
      });
    } catch (e) {
      await closePeerConnection(peerName);
    }
  }

  Future<void> closePeerConnection(String peerName) async {
    try {
      final pc = _pcs[peerName];
      if (pc != null) await pc.close();
    } catch (_) {}
    _pcs.remove(peerName);
    _remoteStreams.remove(peerName);
    if (_incomingSpeaker == peerName) _incomingSpeaker = null;
    notifyListeners();
  }

  Future<void> closeAllPeerConnections() async {
    final keys = List<String>.from(_pcs.keys);
    for (var k in keys) await closePeerConnection(k);
  }

  Future<void> _handleOffer(Map<String, dynamic> data, String fromUser) async {
    if (_localStream == null) await _setupLocalStream();

    try {
      // recreate peer if exists
      if (_pcs.containsKey(fromUser)) {
        await closePeerConnection(fromUser);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final pc = await _createPeer(fromUser, isInitiator: false);
      final sdp = (data['sdp'] is String)
          ? data['sdp']
          : (data['data']?['sdp']);
      final type = (data['type'] is String)
          ? data['type']
          : (data['data']?['type']);
      if (sdp == null) return;

      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _sendJson({
        'to': fromUser,
        'from': localUserName,
        'type': 'answer',
        'data': answer.toMap(),
      });
    } catch (e) {
      await closePeerConnection(fromUser);
    }
  }

  // Message handling
  void _onMessageReceived(dynamic event) async {
    try {
      final message = jsonDecode(event as String) as Map<String, dynamic>;
      final type = message['type'] as String?;
      final fromUser = message['from'] as String?;

      switch (type) {
        case 'users':
          final list = (message['list'] as List<dynamic>).cast<String>();
          _connectedUsers = list.where((n) => n != localUserName).toList();
          notifyListeners();

          // Restore peers if needed
          Future.delayed(const Duration(milliseconds: 300), () {
            _restoreSelectedPeerAfterReconnect();
          });
          break;

        case 'offer':
          if (message['data'] is Map && fromUser != null) {
            await _handleOffer(
              Map<String, dynamic>.from(message['data']),
              fromUser,
            );
          }
          break;

        case 'answer':
          if (message['data'] is Map && fromUser != null) {
            final data = Map<String, dynamic>.from(message['data']);
            final sdp = data['sdp'] as String?;
            final typeStr = data['type'] as String?;
            if (sdp != null && typeStr != null) {
              var pc = _pcs[fromUser];
              if (pc == null)
                pc = await _createPeer(fromUser, isInitiator: false);
              await pc.setRemoteDescription(
                RTCSessionDescription(sdp, typeStr),
              );
            }
          }
          break;

        case 'candidate':
          if (message['data'] is Map && fromUser != null) {
            final cand = Map<String, dynamic>.from(message['data']);
            try {
              final candidate = RTCIceCandidate(
                cand['candidate'],
                cand['sdpMid'],
                cand['sdpMLineIndex'],
              );
              final pc = _pcs[fromUser];
              if (pc != null) await pc.addCandidate(candidate);
            } catch (e) {
              // ignore
            }
          }
          break;

        case 'broadcast':
          final action = message['action'] as String?;
          final from = message['from'] as String?;
          if (action == 'start' && from != null) {
            _incomingSpeaker = from;
            notifyListeners();
          } else if (action == 'stop' && from != null) {
            if (_incomingSpeaker == from) {
              _incomingSpeaker = null;
              notifyListeners();
            }
          }
          break;
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _restoreSelectedPeerAfterReconnect() async {
    if (_selectedUser == null) {
      if (_isSpeaking) {
        for (var peer in _connectedUsers) {
          if (peer == localUserName) continue;
          if (!_pcs.containsKey(peer)) {
            await startPeerWith(peer);
            await Future.delayed(const Duration(milliseconds: 30));
          }
        }
      }
      return;
    }

    final peer = _selectedUser!;
    if (!_pcs.containsKey(peer)) await startPeerWith(peer);
  }

  // PTT ya funciona 
  /*void startSpeaking() async {
    if (_localStream == null) await _setupLocalStream();
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (var t in audioTracks) t.enabled = true;
    _isSpeaking = true;
    _incomingSpeaker = null;
    notifyListeners();

    if (_selectedUser == null) {
      for (var peer in _connectedUsers) {
        if (peer == localUserName) continue;
        if (!_pcs.containsKey(peer)) {
          await startPeerWith(peer);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    } else {
      if (!_pcs.containsKey(_selectedUser)) await startPeerWith(_selectedUser!);
    }
  }*/

  // ------------------ Reemplazo: startSpeaking ------------------
  void startSpeaking() async {
    if (_localStream == null) await _setupLocalStream();

    // DEBUG: ver con quién están los peers justo antes de hablar
    print("DEBUG: peers antes de hablar -> ${_pcs.keys.toList()}  selected=$_selectedUser");

    // Si hay un usuario seleccionado -> asegurarnos de que SOLO exista ese peer
    if (_selectedUser != null) {
      // cerrar todos menos el seleccionado (si quedan abiertos)
      await _closeAllExcept(_selectedUser);

      // crear peer con el seleccionado si hace falta
      if (!_pcs.containsKey(_selectedUser)) {
        await startPeerWith(_selectedUser!);
        // esperar un poco a que el ICE/SDP comience (puedes ajustar)
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } else {
      // modo "Todos": asegurarnos tener peers con todos los usuarios
      for (var peer in _connectedUsers) {
        if (peer == localUserName) continue;
        if (!_pcs.containsKey(peer)) {
          await startPeerWith(peer);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    }

    // DEBUG: ver con quién está realmente antes de habilitar tracks
    print("DEBUG: peers justo ANTES de enable tracks -> ${_pcs.keys.toList()}  selected=$_selectedUser");

    // Finalmente habilitar mic (una vez creados/cerrados peers)
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (var t in audioTracks) t.enabled = true;
    _isSpeaking = true;
    _incomingSpeaker = null;
    notifyListeners();

    // opcional: notificar al servidor que iniciaste PTT
    // _sendJson({'type': 'broadcast', 'action': 'start', 'from': localUserName});
  }

  // ------------------ Helper: cerrar todos excepto uno ------------------
  Future<void> _closeAllExcept(String? keep) async {
    if (keep == null) return; // keep == null => modo "Todos", no cerramos nada
    final keys = List<String>.from(_pcs.keys);
    for (var k in keys) {
      if (k != keep) {
        await closePeerConnection(k);
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }


  // funciona
  /*void stopSpeaking() {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (var t in audioTracks) t.enabled = false;
    _isSpeaking = false;
    notifyListeners();

    if (_selectedUser == null) {
      // optional: keep peers open to reduce reconnections
      // closeAllPeerConnections();
    }
  }*/

   // ------------------ Reemplazo leve: stopSpeaking (mantener simple) ------------------
  void stopSpeaking() {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (var t in audioTracks) t.enabled = false;
    _isSpeaking = false;
    notifyListeners();

    // Nota: no cerramos peers automáticamente aquí para evitar reconexiones
    // si quieres cerrar tras hablar, añade closeAllPeerConnections() (pero genera overhead).
  }

  // Dispose
  Future<void> disposeAsync() async {
    _manuallyClosed = true;
    await _cleanupAll();
  }

  @override
  void dispose() {
    disposeAsync();
    super.dispose();
  }

  
}



// ------------------ FIN ------------------

// ------------------ Provider ------------------
/*

class WalkieTalkieProvider with ChangeNotifier {
  WebSocketChannel? _channel;
  MediaStream? _localStream;

  final Map<String, RTCPeerConnection> _pcs = {};
  final Map<String, MediaStream> _remoteStreams = {};

  List<String> _connectedUsers = [];
  String? _selectedUser; // null = Todos
  String? _incomingSpeaker;
  bool _isSpeaking = false;

  int _reconnectAttempts = 0;
  bool _manuallyClosed = false;

  List<String> get connectedUsers => _connectedUsers;
  bool get isSpeaking => _isSpeaking;
  String? get incomingSpeaker => _incomingSpeaker;
  bool get wsConnected => _channel != null;
  int get peerCount => _pcs.length;
  bool get hasActivePeer => _pcs.isNotEmpty;

  List<String> get connectedUsersWithAll => ['Todos'] + _connectedUsers;
  String get selectedUserDisplay =>
      _selectedUser == null ? 'Todos' : _selectedUser!;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:$turnServerIp:3478',
        'username': 'testturn',
        'credential': 'turn2025',
      },
    ],
  };

  // Connect + auto-reconnect
  Future<void> connect() async {
    if (_channel != null) return;

    try {
      _manuallyClosed = false;
      _channel = WebSocketChannel.connect(Uri.parse(signalingServerUrl));

      _channel!.stream.listen(
        _onMessageReceived,
        onDone: () async {
          await _cleanupChannelOnly();
          _autoReconnect();
        },
        onError: (err) async {
          await _cleanupChannelOnly();
          _autoReconnect();
        },
      );

      _reconnectAttempts = 0;
      _sendJson({'type': 'register', 'name': localUserName});

      // after reconnect restore peers
      Future.delayed(const Duration(milliseconds: 500), () {
        _restoreSelectedPeerAfterReconnect();
      });

      notifyListeners();
    } catch (e) {
      await _cleanupChannelOnly();
      _autoReconnect();
    }
  }

  Future<void> _autoReconnect() async {
    if (_manuallyClosed) return;
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 2).clamp(2, 30);
    await Future.delayed(Duration(seconds: delaySeconds));
    await connect();
  }

  Future<void> reconnectNow() async {
    await _cleanupChannelOnly();
    _reconnectAttempts = 0;
    await connect();
  }

  Future<void> _cleanupChannelOnly() async {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    notifyListeners();
  }

  Future<void> _cleanupAll() async {
    await _cleanupChannelOnly();
    await closeAllPeerConnections();
    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    _connectedUsers = [];
    _selectedUser = null;
    notifyListeners();
  }

  void _sendJson(Map<String, dynamic> map) {
    try {
      _channel?.sink.add(jsonEncode(map));
    } catch (e) {
      // ignore
    }
  }

  Future<void> _setupLocalStream() async {
    if (_localStream != null) return;
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (var t in _localStream!.getAudioTracks())
        t.enabled = false; // mute by default
    } catch (e) {
      print('Error obtaining local media: $e');
    }
  }

  // Selection
  Future<void> setSelectedUserFromDisplay(String display) async {
    if (display == 'Todos') {
      _selectedUser = null;
      notifyListeners();

      // create mesh peers immediately
      for (var peer in _connectedUsers) {
        if (peer == localUserName) continue;
        if (!_pcs.containsKey(peer)) {
          await startPeerWith(peer);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
      return;
    }

    _selectedUser = display;
    notifyListeners();

    if (!_pcs.containsKey(display)) {
      await startPeerWith(display);
    }
  }

  String peerStatus(String user) {
    if (!_pcs.containsKey(user)) {
      return "❌ No conectado";
    }

    final state = _pcs[user]!.iceConnectionState;

    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
        return "🟢 Conectado";

      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        return "🟡 Conectando…";

      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        return "🔴 Desconectado";

      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        return "⚠️ Error";

      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        return "⚫ Cerrado";

      default:
        return "⚪ Esperando";
    }
  }

  // Create peer
  Future<RTCPeerConnection> _createPeer(
    String peerName, {
    bool isInitiator = false,
  }) async {
    final pc = await createPeerConnection(_iceServers);

    // add local tracks
    if (_localStream != null) {
      final tracks = _localStream!.getTracks();
      for (var t in tracks) {
        try {
          await pc.addTrack(t, _localStream!);
        } catch (e) {
          // ignore
        }
      }
    }

    pc.onIceCandidate = (candidate) {
      if (candidate != null) {
        _sendJson({
          'to': peerName,
          'from': localUserName,
          'type': 'candidate',
          'data': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[peerName] = event.streams[0];
        _incomingSpeaker = peerName;
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          if (_incomingSpeaker == peerName && !_isSpeaking) {
            _incomingSpeaker = null;
            notifyListeners();
          }
        });
      }
    };

    pc.onIceConnectionState = (state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        closePeerConnection(peerName);
      }
    };

    _pcs[peerName] = pc;
    notifyListeners();
    return pc;
  }

  Future<void> startPeerWith(String peerName) async {
    if (_pcs.containsKey(peerName)) return;
    try {
      // Asegurarse de que el stream local esté disponible
      if (_localStream == null) {
        await _setupLocalStream();
      }

      final pc = await _createPeer(peerName, isInitiator: true);
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      _sendJson({
        'to': peerName,
        'from': localUserName,
        'type': 'offer',
        'data': offer.toMap(),
      });
    } catch (e) {
      await closePeerConnection(peerName);
    }
  }

  Future<void> closePeerConnection(String peerName) async {
    try {
      final pc = _pcs[peerName];
      if (pc != null) await pc.close();
    } catch (_) {}
    _pcs.remove(peerName);
    _remoteStreams.remove(peerName);
    if (_incomingSpeaker == peerName) _incomingSpeaker = null;
    notifyListeners();
  }

  Future<void> closeAllPeerConnections() async {
    final keys = List<String>.from(_pcs.keys);
    for (var k in keys) await closePeerConnection(k);
  }

  Future<void> _handleOffer(Map<String, dynamic> data, String fromUser) async {
    // En iOS, inicializar el stream solo cuando sea necesario
    if (_localStream == null) {
      await _setupLocalStream();
    }

    try {
      // recreate peer if exists
      if (_pcs.containsKey(fromUser)) {
        await closePeerConnection(fromUser);
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final pc = await _createPeer(fromUser, isInitiator: false);
      final sdp = (data['sdp'] is String)
          ? data['sdp']
          : (data['data']?['sdp']);
      final type = (data['type'] is String)
          ? data['type']
          : (data['data']?['type']);
      if (sdp == null) return;

      await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _sendJson({
        'to': fromUser,
        'from': localUserName,
        'type': 'answer',
        'data': answer.toMap(),
      });
    } catch (e) {
      await closePeerConnection(fromUser);
    }
  }

  // Message handling
  void _onMessageReceived(dynamic event) async {
    try {
      final message = jsonDecode(event as String) as Map<String, dynamic>;
      final type = message['type'] as String?;
      final fromUser = message['from'] as String?;

      switch (type) {
        case 'users':
          final list = (message['list'] as List<dynamic>).cast<String>();
          _connectedUsers = list.where((n) => n != localUserName).toList();
          notifyListeners();

          // Restore peers if needed
          Future.delayed(const Duration(milliseconds: 300), () {
            _restoreSelectedPeerAfterReconnect();
          });
          break;

        case 'offer':
          if (message['data'] is Map && fromUser != null) {
            await _handleOffer(
              Map<String, dynamic>.from(message['data']),
              fromUser,
            );
          }
          break;

        case 'answer':
          if (message['data'] is Map && fromUser != null) {
            final data = Map<String, dynamic>.from(message['data']);
            final sdp = data['sdp'] as String?;
            final typeStr = data['type'] as String?;
            if (sdp != null && typeStr != null) {
              var pc = _pcs[fromUser];
              if (pc == null)
                pc = await _createPeer(fromUser, isInitiator: false);
              await pc.setRemoteDescription(
                RTCSessionDescription(sdp, typeStr),
              );
            }
          }
          break;

        case 'candidate':
          if (message['data'] is Map && fromUser != null) {
            final cand = Map<String, dynamic>.from(message['data']);
            try {
              final candidate = RTCIceCandidate(
                cand['candidate'],
                cand['sdpMid'],
                cand['sdpMLineIndex'],
              );
              final pc = _pcs[fromUser];
              if (pc != null) await pc.addCandidate(candidate);
            } catch (e) {
              // ignore
            }
          }
          break;

        case 'broadcast':
          final action = message['action'] as String?;
          final from = message['from'] as String?;
          if (action == 'start' && from != null) {
            _incomingSpeaker = from;
            notifyListeners();
          } else if (action == 'stop' && from != null) {
            if (_incomingSpeaker == from) {
              _incomingSpeaker = null;
              notifyListeners();
            }
          }
          break;
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _restoreSelectedPeerAfterReconnect() async {
    if (_selectedUser == null) {
      if (_isSpeaking) {
        for (var peer in _connectedUsers) {
          if (peer == localUserName) continue;
          if (!_pcs.containsKey(peer)) {
            await startPeerWith(peer);
            await Future.delayed(const Duration(milliseconds: 30));
          }
        }
      }
      return;
    }

    final peer = _selectedUser!;
    if (!_pcs.containsKey(peer)) await startPeerWith(peer);
  }

  // PTT
  void startSpeaking() async {
    // En iOS, inicializar el stream solo cuando sea necesario
    if (_localStream == null) {
      await _setupLocalStream();
    }

    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (var t in audioTracks) t.enabled = true;
    _isSpeaking = true;
    _incomingSpeaker = null;
    notifyListeners();

    if (_selectedUser == null) {
      for (var peer in _connectedUsers) {
        if (peer == localUserName) continue;
        if (!_pcs.containsKey(peer)) {
          await startPeerWith(peer);
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }
    } else {
      if (!_pcs.containsKey(_selectedUser)) await startPeerWith(_selectedUser!);
    }
  }

  void stopSpeaking() {
    final audioTracks = _localStream?.getAudioTracks() ?? [];
    for (var t in audioTracks) t.enabled = false;
    _isSpeaking = false;
    notifyListeners();

    if (_selectedUser == null) {
      // optional: keep peers open to reduce reconnections
      // closeAllPeerConnections();
    }
  }

  // Dispose
  Future<void> disposeAsync() async {
    _manuallyClosed = true;
    await _cleanupAll();
  }

  @override
  void dispose() {
    disposeAsync();
    super.dispose();
  }
}
*/
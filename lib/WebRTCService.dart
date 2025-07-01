import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_app/SignalingService.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  List<MediaStream> _remoteStreams = [];
  bool _isMuted = false;
  bool _isVideoOn = true;
  final SignalingService _signaling = SignalingService();
  final _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {
        'urls': 'turn:turn.anyfirewall.com:443?transport=tcp',
        'username': 'webrtc',
        'credential': 'webrtc'
      }, // Replace with your TURN server
    ]
  };
  RTCSessionDescription? _localDescription;
  final List<RTCIceCandidate> _pendingCandidates = [];

  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStreamAdded;
  Function(String)? onRoomCreated;
  Function()? onHangUp;
  Function(RTCIceConnectionState)? onConnectionState;

  Future<void> initialize() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
      print('Local stream initialized: ${_localStream!.id}');
      onLocalStream?.call(_localStream!);
    } catch (e) {
      print('Initialize error: $e');
      throw Exception('Failed to initialize local stream: $e');
    }
  }

  Future<void> createRoom() async {
    try {
      await _initializePeerConnection();
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(offer);
      _localDescription = offer;
      final roomId = await _signaling.createRoom(offer);
      print('Room created: $roomId');
      onRoomCreated?.call(roomId);
      _signalingRoomId = roomId;
      _flushPendingCandidates();
      _listenForAnswer(roomId);
      _listenForCalleeCandidates(roomId);
    } catch (e) {
      print('Create room error: $e');
      throw Exception('Failed to create room: $e');
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      // Reset peer connection if rejoining
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
        _remoteStreams.clear();
        print('Reset peer connection for rejoin');
      }
      await _initializePeerConnection();
      final offer = await _signaling.getRoomOffer(roomId);
      if (offer == null) throw Exception('Room does not exist');
      await _peerConnection!.setRemoteDescription(offer);
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(answer);
      _localDescription = answer;
      await _signaling.setAnswer(roomId, answer);
      print('Joined room: $roomId');
      _signalingRoomId = roomId;
      _flushPendingCandidates();
      _listenForCallerCandidates(roomId);
    } catch (e) {
      print('Join room error: $e');
      throw Exception('Failed to join room: $e');
    }
  }

  Future<void> _initializePeerConnection() async {
    if (_localStream == null) {
      throw Exception('Local stream is not initialized. Call initialize() first.');
    }
    _peerConnection = await createPeerConnection(_configuration);
    print('Peer connection created');
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        print('Remote stream received: ${stream.id}');
        _remoteStreams.add(stream);
        onRemoteStreamAdded?.call(stream);
      }
    };
    _peerConnection!.onIceCandidate = (candidate) {
      if (_peerConnection!.signalingState != RTCSignalingState.RTCSignalingStateClosed) {
        if (_signalingRoomId != null) {
          print('Sending ICE candidate: ${candidate.candidate}');
          _signaling.addCandidateToRoom(
            roomId: _signalingRoomId!,
            candidate: candidate,
            isCaller: _localDescription?.type == 'offer',
          );
        } else {
          print('Buffering ICE candidate: ${candidate.candidate}');
          _pendingCandidates.add(candidate);
        }
      }
    };
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state: $state');
      onConnectionState?.call(state);
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('ICE connection failed, attempting to restart');
        _peerConnection?.restartIce();
      }
    };
    _peerConnection!.onSignalingState = (RTCSignalingState state) {
      print('Signaling state: $state');
    };
    _localStream!.getTracks().forEach((track) {
      print('Adding track: ${track.kind} (enabled: ${track.enabled})');
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  void _flushPendingCandidates() {
    if (_signalingRoomId != null) {
      print('Flushing ${_pendingCandidates.length} pending candidates');
      for (var candidate in _pendingCandidates) {
        _signaling.addCandidateToRoom(
          roomId: _signalingRoomId!,
          candidate: candidate,
          isCaller: _localDescription?.type == 'offer',
        );
      }
      _pendingCandidates.clear();
    }
  }

  void _listenForAnswer(String roomId) {
    _signaling.listenForAnswer(roomId).listen((answer) {
      if (answer != null && _peerConnection != null) {
        print('Setting remote answer');
        _peerConnection!.setRemoteDescription(answer);
      }
    });
  }

  void _listenForCalleeCandidates(String roomId) {
    _signaling.getCandidatesStream(roomId, true).listen((candidates) {
      for (var candidate in candidates) {
        print('Adding callee ICE candidate: ${candidate.candidate}');
        _peerConnection?.addCandidate(candidate);
      }
    });
  }

  void _listenForCallerCandidates(String roomId) {
    _signaling.getCandidatesStream(roomId, false).listen((candidates) {
      for (var candidate in candidates) {
        print('Adding caller ICE candidate: ${candidate.candidate}');
        _peerConnection?.addCandidate(candidate);
      }
    });
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
      print('Audio track enabled: ${track.enabled}');
    });
  }

  void toggleVideo() {
    _isVideoOn = !_isVideoOn;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = _isVideoOn;
      print('Video track enabled: ${track.enabled}');
    });
  }

  Future<void> hangUp(String? roomId, {bool deleteRoom = false}) async {
    print('Hanging up ${roomId ?? 'no room'} (deleteRoom: $deleteRoom)');
    _localStream?.getTracks().forEach((track) => track.stop());
    _remoteStreams.forEach((stream) => stream.getTracks().forEach((track) => track.stop()));
    await _peerConnection?.close();
    if (deleteRoom && roomId != null && roomId.isNotEmpty) {
      await _signaling.deleteRoom(roomId);
    }
    _localStream = null;
    _remoteStreams.clear();
    _peerConnection = null;
    _localDescription = null;
    _signalingRoomId = null;
    _pendingCandidates.clear();
    onHangUp?.call();
  }

  MediaStream? get localStream => _localStream;
  List<MediaStream> get remoteStreams => _remoteStreams;
  bool get isMuted => _isMuted;
  bool get isVideoOn => _isVideoOn;

  String? _signalingRoomId;
  void setRoomId(String roomId) {
    _signalingRoomId = roomId;
    print('Room ID set: $roomId');
    _flushPendingCandidates();
  }
}
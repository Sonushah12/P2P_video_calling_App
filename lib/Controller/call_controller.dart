import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart';
import 'package:webrtc_app/WebRTCService.dart';

class CallController extends GetxController {
  final WebRTCService _webRTCService = WebRTCService();
  final _roomId = ''.obs;
  final _localRenderer = RTCVideoRenderer().obs;
  final _remoteRenderers = <RTCVideoRenderer>[].obs;
  final _isInitialized = false.obs;
  final _connectionState = RTCIceConnectionState.RTCIceConnectionStateNew.obs;
  final _isCreator = false.obs;

  String get roomId => _roomId.value;
  RTCVideoRenderer get localRenderer => _localRenderer.value;
  List<RTCVideoRenderer> get remoteRenderers => _remoteRenderers;
  bool get isInitialized => _isInitialized.value;
  RTCIceConnectionState get connectionState => _connectionState.value;
  bool get isCreator => _isCreator.value;

  @override
  void onInit() async {
    super.onInit();
    try {
      await _localRenderer.value.initialize();
      _webRTCService.onLocalStream = (stream) {
        print('Local stream set: ${stream.id}');
        _localRenderer.value.srcObject = stream;
        update();
      };
      _webRTCService.onRemoteStreamAdded = (stream) async {
        print('Remote stream added: ${stream.id}');
        final renderer = RTCVideoRenderer();
        await renderer.initialize();
        renderer.srcObject = stream;
        _remoteRenderers.add(renderer);
        update();
      };
      _webRTCService.onRoomCreated = (roomId) {
        print('Room created with ID: $roomId');
        _roomId.value = roomId;
        _webRTCService.setRoomId(roomId);
        _isCreator.value = true;
        update();
      };
      _webRTCService.onHangUp = () {
        print('Hang up triggered');
        Get.back();
      };
      _webRTCService.onConnectionState = (state) {
        print('Connection state updated: $state');
        _connectionState.value = state;
        update();
      };
      await _webRTCService.initialize();
      _isInitialized.value = true;
      print('Initialization complete');
      update();
    } catch (e) {
      print('Initialization error: $e');
      Get.snackbar('Error', 'Failed to initialize: $e');
    }
  }

  Future<void> createRoom() async {
    if (!_isInitialized.value) {
      print('Waiting for initialization');
      Get.snackbar('Error', 'Please wait, initialization in progress');
      return;
    }
    try {
      if (_webRTCService.localStream == null) {
        await _webRTCService.initialize();
      }
      print('Starting room creation');
      await _webRTCService.createRoom();
    } catch (e) {
      print('Create room error: $e');
      Get.snackbar('Error', 'Failed to create room: $e');
    }
  }

  Future<void> joinRoom(String roomId) async {
    if (!_isInitialized.value) {
      print('Waiting for initialization');
      Get.snackbar('Error', 'Please wait, initialization in progress');
      return;
    }
    try {
      // Clear existing renderers for rejoin
      for (var renderer in _remoteRenderers) {
        renderer.dispose();
      }
      _remoteRenderers.clear();
      print('Cleared remote renderers for rejoin');
      if (_webRTCService.localStream == null) {
        await _webRTCService.initialize();
      }
      print('Joining room: $roomId');
      _webRTCService.setRoomId(roomId);
      await _webRTCService.joinRoom(roomId);
      _roomId.value = roomId;
      _isCreator.value = false;
      update();
    } catch (e) {
      print('Join room error: $e');
      Get.snackbar('Error', 'Failed to join room: $e');
    }
  }

  void toggleMute() {
    _webRTCService.toggleMute();
    update();
  }

  void toggleVideo() {
    _webRTCService.toggleVideo();
    update();
  }

  Future<void> hangUp() async {
    if (_roomId.value.isNotEmpty) {
      print('Hanging up room: ${_roomId.value}');
      // Only delete room if creator
      await _webRTCService.hangUp(_roomId.value, deleteRoom: _isCreator.value);
      _remoteRenderers.clear();
      _roomId.value = '';
      _connectionState.value = RTCIceConnectionState.RTCIceConnectionStateNew;
      _isCreator.value = false;
      update();
    } else {
      print('Hanging up with no roomId');
      _webRTCService.hangUp(null);
      _remoteRenderers.clear();
      _roomId.value = '';
      _connectionState.value = RTCIceConnectionState.RTCIceConnectionStateNew;
      _isCreator.value = false;
      update();
    }
  }

  @override
  void onClose() {
    print('Closing controller');
    _localRenderer.value.dispose();
    for (var renderer in _remoteRenderers) {
      renderer.dispose();
    }
    super.onClose();
  }

  bool get isMuted => _webRTCService.isMuted;
  bool get isVideoOn => _webRTCService.isVideoOn;
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _roomsCollection = 'rooms';

  Future<String> createRoom(RTCSessionDescription offer) async {
    final roomRef = _db.collection(_roomsCollection).doc();
    final roomWithOffer = {'offer': offer.toMap(), 'createdAt': FieldValue.serverTimestamp()};
    await roomRef.set(roomWithOffer);
    return roomRef.id;
  }

  Future<RTCSessionDescription?> getRoomOffer(String roomId) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    final roomSnapshot = await roomRef.get();
    if (roomSnapshot.exists) {
      final data = roomSnapshot.data();
      if (data != null && data['offer'] != null) {
        return RTCSessionDescription(
          data['offer']['sdp'],
          data['offer']['type'],
        );
      }
    }
    return null;
  }

  Future<void> setAnswer(String roomId, RTCSessionDescription answer) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    await roomRef.update({'answer': answer.toMap()});
  }

  Stream<RTCSessionDescription?> listenForAnswer(String roomId) {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    return roomRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['answer'] != null) {
          return RTCSessionDescription(
            data['answer']['sdp'],
            data['answer']['type'],
          );
        }
      }
      return null;
    });
  }

  Future<void> addCandidateToRoom({
    required String roomId,
    required RTCIceCandidate candidate,
    required bool isCaller,
  }) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    final candidatesCollection = roomRef.collection(isCaller ? 'callerCandidates' : 'calleeCandidates');
    await candidatesCollection.add(candidate.toMap());
  }

  Stream<List<RTCIceCandidate>> getCandidatesStream(String roomId, bool isCaller) {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    final candidatesCollection = roomRef.collection(isCaller ? 'calleeCandidates' : 'callerCandidates');
    return candidatesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => RTCIceCandidate(
        doc['candidate'],
        doc['sdpMid'],
        doc['sdpMLineIndex'],
      ))
          .toList();
    });
  }

  Future<void> deleteRoom(String roomId) async {
    final roomRef = _db.collection(_roomsCollection).doc(roomId);
    final callerCandidates = await roomRef.collection('callerCandidates').get();
    for (var candidate in callerCandidates.docs) {
      await candidate.reference.delete();
    }
    final calleeCandidates = await roomRef.collection('calleeCandidates').get();
    for (var candidate in calleeCandidates.docs) {
      await candidate.reference.delete();
    }
    await roomRef.delete();
    print('Room deleted: $roomId');
  }
}
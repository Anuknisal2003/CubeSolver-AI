// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cube_model.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Auth ───────────────────────────────────────────────────────────────────

  static Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Cube Sessions ──────────────────────────────────────────────────────────

  static Future<String> saveCubeState(CubeState cube) async {
    final uid = currentUser?.uid ?? 'anonymous';
    final data = cube.toJson()
      ..['uid'] = uid
      ..['savedAt'] = FieldValue.serverTimestamp();

    final ref = await _db.collection('cube_sessions').add(data);
    return ref.id;
  }

  static Future<List<CubeState>> getPastSessions() async {
    final uid = currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('cube_sessions')
        .where('uid', isEqualTo: uid)
        .orderBy('savedAt', descending: true)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) {
          try {
            final data = doc.data()..['id'] = doc.id;
            return CubeState.fromJson(data);
          } catch (_) {
            return null;
          }
        })
        .whereType<CubeState>()
        .toList();
  }

  // ─── Solutions ──────────────────────────────────────────────────────────────

  static Future<void> saveSolution({
    required String sessionId,
    required SolveSolution solution,
  }) async {
    final uid = currentUser?.uid ?? 'anonymous';
    await _db.collection('solutions').add({
      'sessionId': sessionId,
      'uid': uid,
      'notation': solution.rawNotation,
      'moveCount': solution.totalMoves,
      'solveTimeMs': solution.solveTime.inMilliseconds,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Leaderboard ────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final snapshot = await _db
        .collection('solutions')
        .orderBy('moveCount')
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // ─── Stats ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getUserStats() async {
    final uid = currentUser?.uid;
    if (uid == null) return {};

    final solutions = await _db
        .collection('solutions')
        .where('uid', isEqualTo: uid)
        .get();

    if (solutions.docs.isEmpty) return {'total': 0};

    final moveCounts = solutions.docs
        .map((d) => d.data()['moveCount'] as int? ?? 0)
        .toList();

    return {
      'total': solutions.docs.length,
      'bestMoves': moveCounts.reduce((a, b) => a < b ? a : b),
      'avgMoves': (moveCounts.reduce((a, b) => a + b) / moveCounts.length)
          .toStringAsFixed(1),
    };
  }
}

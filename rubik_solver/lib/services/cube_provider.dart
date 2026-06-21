// lib/services/cube_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cube_model.dart';
import 'cube_solver.dart';
import 'firebase_service.dart';

// ─── Cube State Notifier ─────────────────────────────────────────────────────

class CubeNotifier extends StateNotifier<CubeState> {
  CubeNotifier() : super(CubeState.empty());

  void updateFace(CubeFace face, List<CubeColor> colors) {
    state = state.withFace(face, colors);
  }

  void reset() {
    state = CubeState.empty();
  }

  void setColor(CubeFace face, int index, CubeColor color) {
    final colors = List<CubeColor>.from(state.faces[face]!);
    colors[index] = color;
    state = state.withFace(face, colors);
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final cubeProvider = StateNotifierProvider<CubeNotifier, CubeState>(
  (ref) => CubeNotifier(),
);

final currentFaceProvider = StateProvider<CubeFace>((ref) => CubeFace.up);

final scannedFacesProvider = StateProvider<Set<CubeFace>>((ref) => {});

final solutionProvider = StateProvider<SolveSolution?>((ref) => null);

final isSolvingProvider = StateProvider<bool>((ref) => false);

// ─── Solve Action ─────────────────────────────────────────────────────────────

class SolveController {
  final Ref _ref;
  SolveController(this._ref);

  Future<SolveSolution?> solve() async {
    final cube = _ref.read(cubeProvider);
    if (!cube.isComplete) return null;

    _ref.read(isSolvingProvider.notifier).state = true;
    try {
      final solution = await CubeSolver.solve(cube);

      // Save to Firebase
      final sessionId = await FirebaseService.saveCubeState(cube);
      await FirebaseService.saveSolution(
        sessionId: sessionId,
        solution: solution,
      );

      _ref.read(solutionProvider.notifier).state = solution;
      return solution;
    } finally {
      _ref.read(isSolvingProvider.notifier).state = false;
    }
  }
}

final solveControllerProvider = Provider((ref) => SolveController(ref));

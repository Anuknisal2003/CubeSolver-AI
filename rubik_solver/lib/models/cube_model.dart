// lib/models/cube_model.dart

enum CubeColor { white, yellow, red, orange, blue, green, unknown }

extension CubeColorExtension on CubeColor {
  String get name {
    switch (this) {
      case CubeColor.white:  return 'White';
      case CubeColor.yellow: return 'Yellow';
      case CubeColor.red:    return 'Red';
      case CubeColor.orange: return 'Orange';
      case CubeColor.blue:   return 'Blue';
      case CubeColor.green:  return 'Green';
      case CubeColor.unknown: return 'Unknown';
    }
  }

  int get colorValue {
    switch (this) {
      case CubeColor.white:  return 0xFFFFFFFF;
      case CubeColor.yellow: return 0xFFFFD700;
      case CubeColor.red:    return 0xFFCC0000;
      case CubeColor.orange: return 0xFFFF6600;
      case CubeColor.blue:   return 0xFF0055CC;
      case CubeColor.green:  return 0xFF009900;
      case CubeColor.unknown: return 0xFF888888;
    }
  }

  String get notation {
    switch (this) {
      case CubeColor.white:  return 'U';
      case CubeColor.yellow: return 'D';
      case CubeColor.red:    return 'F';
      case CubeColor.orange: return 'B';
      case CubeColor.blue:   return 'R';
      case CubeColor.green:  return 'L';
      case CubeColor.unknown: return '?';
    }
  }
}

enum CubeFace { up, down, front, back, left, right }

extension CubeFaceExtension on CubeFace {
  String get displayName {
    switch (this) {
      case CubeFace.up:    return 'Top (White)';
      case CubeFace.down:  return 'Bottom (Yellow)';
      case CubeFace.front: return 'Front (Red)';
      case CubeFace.back:  return 'Back (Orange)';
      case CubeFace.left:  return 'Left (Green)';
      case CubeFace.right: return 'Right (Blue)';
    }
  }

  String get shortName {
    switch (this) {
      case CubeFace.up:    return 'U';
      case CubeFace.down:  return 'D';
      case CubeFace.front: return 'F';
      case CubeFace.back:  return 'B';
      case CubeFace.left:  return 'L';
      case CubeFace.right: return 'R';
    }
  }

  CubeColor get expectedCenterColor {
    switch (this) {
      case CubeFace.up:    return CubeColor.white;
      case CubeFace.down:  return CubeColor.yellow;
      case CubeFace.front: return CubeColor.red;
      case CubeFace.back:  return CubeColor.orange;
      case CubeFace.left:  return CubeColor.green;
      case CubeFace.right: return CubeColor.blue;
    }
  }

  String get emoji {
    switch (this) {
      case CubeFace.up:    return '⬆️';
      case CubeFace.down:  return '⬇️';
      case CubeFace.front: return '🔴';
      case CubeFace.back:  return '🟠';
      case CubeFace.left:  return '🟢';
      case CubeFace.right: return '🔵';
    }
  }
}

class CubeState {
  // Each face has 9 stickers [0..8], index 4 is center
  final Map<CubeFace, List<CubeColor>> faces;
  final DateTime? capturedAt;
  final String? id;

  CubeState({
    required this.faces,
    this.capturedAt,
    this.id,
  });

  factory CubeState.empty() {
    final faces = <CubeFace, List<CubeColor>>{};
    for (final face in CubeFace.values) {
      faces[face] = List.filled(9, CubeColor.unknown);
    }
    return CubeState(faces: faces);
  }

  factory CubeState.solved() {
    final faces = <CubeFace, List<CubeColor>>{};
    for (final face in CubeFace.values) {
      faces[face] = List.filled(9, face.expectedCenterColor);
    }
    return CubeState(faces: faces, capturedAt: DateTime.now());
  }

  bool get isComplete {
    for (final face in CubeFace.values) {
      if (faces[face]!.any((c) => c == CubeColor.unknown)) return false;
    }
    return true;
  }

  bool get isValid {
    if (!isComplete) return false;
    final colorCounts = <CubeColor, int>{};
    for (final face in CubeFace.values) {
      for (final color in faces[face]!) {
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
      }
    }
    // Each color must appear exactly 9 times
    for (final color in CubeColor.values) {
      if (color == CubeColor.unknown) continue;
      if ((colorCounts[color] ?? 0) != 9) return false;
    }
    return true;
  }

  CubeState copyWith({Map<CubeFace, List<CubeColor>>? faces}) {
    return CubeState(
      faces: faces ?? Map.from(this.faces),
      capturedAt: capturedAt,
      id: id,
    );
  }

  CubeState withFace(CubeFace face, List<CubeColor> colors) {
    final newFaces = Map<CubeFace, List<CubeColor>>.from(faces);
    newFaces[face] = colors;
    return CubeState(faces: newFaces, capturedAt: DateTime.now());
  }

  // Convert to Kociemba string notation (URFDLB order)
  String toKociembaString() {
    // Face order for Kociemba: U R F D L B
    const faceOrder = [
      CubeFace.up, CubeFace.right, CubeFace.front,
      CubeFace.down, CubeFace.left, CubeFace.back
    ];

    final sb = StringBuffer();
    for (final face in faceOrder) {
      for (final color in faces[face]!) {
        sb.write(color.notation);
      }
    }
    return sb.toString();
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'capturedAt': capturedAt?.toIso8601String(),
      'id': id,
    };
    for (final face in CubeFace.values) {
      json[face.shortName] = faces[face]!.map((c) => c.index).toList();
    }
    return json;
  }

  factory CubeState.fromJson(Map<String, dynamic> json) {
    final faces = <CubeFace, List<CubeColor>>{};
    for (final face in CubeFace.values) {
      final colorIndices = (json[face.shortName] as List).cast<int>();
      faces[face] = colorIndices.map((i) => CubeColor.values[i]).toList();
    }
    return CubeState(
      faces: faces,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'])
          : null,
      id: json['id'],
    );
  }
}

class SolveStep {
  final String move;
  final String description;
  final int stepNumber;

  SolveStep({
    required this.move,
    required this.description,
    required this.stepNumber,
  });

  factory SolveStep.fromNotation(String move, int stepNumber) {
    return SolveStep(
      move: move,
      description: _describeMove(move),
      stepNumber: stepNumber,
    );
  }

  static String _describeMove(String move) {
    final base = move.replaceAll("'", "").replaceAll("2", "");
    final isPrime = move.contains("'");
    final isDouble = move.contains("2");

    String face = '';
    switch (base) {
      case 'U': face = 'Top';    break;
      case 'D': face = 'Bottom'; break;
      case 'F': face = 'Front';  break;
      case 'B': face = 'Back';   break;
      case 'L': face = 'Left';   break;
      case 'R': face = 'Right';  break;
    }

    if (isDouble) return 'Rotate $face face 180°';
    if (isPrime)  return 'Rotate $face face counter-clockwise';
    return 'Rotate $face face clockwise';
  }
}

class SolveSolution {
  final List<SolveStep> steps;
  final int totalMoves;
  final Duration solveTime;
  final String rawNotation;

  SolveSolution({
    required this.steps,
    required this.totalMoves,
    required this.solveTime,
    required this.rawNotation,
  });

  factory SolveSolution.fromNotation(String notation, Duration solveTime) {
    final moves = notation.trim().split(' ').where((m) => m.isNotEmpty).toList();
    final steps = moves.asMap().entries
        .map((e) => SolveStep.fromNotation(e.value, e.key + 1))
        .toList();

    return SolveSolution(
      steps: steps,
      totalMoves: moves.length,
      solveTime: solveTime,
      rawNotation: notation,
    );
  }
}

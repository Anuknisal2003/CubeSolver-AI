// lib/widgets/cube_3d_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/cube_model.dart';

class Cube3DWidget extends StatefulWidget {
  final CubeState cubeState;
  final double size;
  final bool autoRotate;
  final String? highlightMove;

  const Cube3DWidget({
    super.key,
    required this.cubeState,
    this.size = 200,
    this.autoRotate = false,
    this.highlightMove,
  });

  @override
  State<Cube3DWidget> createState() => _Cube3DWidgetState();
}

class _Cube3DWidgetState extends State<Cube3DWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotController;
  late AnimationController _moveController;
  late Animation<double> _rotY;

  double _baseRotX = -0.4;
  double _baseRotY = 0.6;
  double _dragStartX = 0;
  double _dragStartY = 0;
  double _tempRotX = 0;
  double _tempRotY = 0;

  @override
  void initState() {
    super.initState();
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotY = Tween(begin: 0.0, end: pi * 2).animate(_rotController);
  }

  @override
  void didUpdateWidget(Cube3DWidget old) {
    super.didUpdateWidget(old);
    if (widget.highlightMove != old.highlightMove &&
        widget.highlightMove != null) {
      _moveController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _rotController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) {
        _rotController.stop();
        _dragStartX = d.globalPosition.dx;
        _dragStartY = d.globalPosition.dy;
        _tempRotX = _baseRotX;
        _tempRotY = _baseRotY;
      },
      onPanUpdate: (d) {
        setState(() {
          _baseRotY = _tempRotY + (d.globalPosition.dx - _dragStartX) * 0.01;
          _baseRotX = _tempRotX - (d.globalPosition.dy - _dragStartY) * 0.01;
        });
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotController, _moveController]),
        builder: (context, _) {
          final autoRotY = widget.autoRotate ? _rotY.value : 0.0;
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _Cube3DPainter(
              cubeState: widget.cubeState,
              rotX: _baseRotX,
              rotY: _baseRotY + autoRotY,
              highlightMove: widget.highlightMove,
              highlightProgress: _moveController.value,
            ),
          );
        },
      ),
    );
  }
}

class _Cube3DPainter extends CustomPainter {
  final CubeState cubeState;
  final double rotX;
  final double rotY;
  final String? highlightMove;
  final double highlightProgress;

  _Cube3DPainter({
    required this.cubeState,
    required this.rotX,
    required this.rotY,
    this.highlightMove,
    this.highlightProgress = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final s = size.width * 0.35; // cube half-size

    // 8 corners of the unit cube
    final List<List<double>> verts = [
      [-1, -1, -1],
      [1, -1, -1],
      [1, 1, -1],
      [-1, 1, -1],
      [-1, -1, 1],
      [1, -1, 1],
      [1, 1, 1],
      [-1, 1, 1],
    ];

    // Apply rotation
    final rotated = verts.map((v) => _rotate(v, rotX, rotY)).toList();

    // Project to 2D (simple perspective)
    Offset project(List<double> v) {
      const fov = 3.5;
      final z = v[2] + fov;
      return Offset(cx + v[0] / z * s * fov, cy + v[1] / z * s * fov);
    }

    // 6 faces: indices into verts, face enum
    final faceDefs = [
      // face index, vertex indices, normal direction
      {
        'face': CubeFace.front,
        'vi': [4, 5, 6, 7]
      }, // +Z
      {
        'face': CubeFace.back,
        'vi': [0, 1, 2, 3]
      }, // -Z (back-culled usually)
      {
        'face': CubeFace.left,
        'vi': [0, 4, 7, 3]
      }, // -X
      {
        'face': CubeFace.right,
        'vi': [1, 5, 6, 2]
      }, // +X
      {
        'face': CubeFace.up,
        'vi': [3, 2, 6, 7]
      }, // +Y (up in cube = top)
      {
        'face': CubeFace.down,
        'vi': [0, 1, 5, 4]
      }, // -Y
    ];

    // Sort faces by average Z (painter's algorithm)
    final facesSorted = List.from(faceDefs)
      ..sort((a, b) {
        final vi = a['vi'] as List;
        final vi2 = b['vi'] as List;
        final zA = vi.map((i) => rotated[i][2]).reduce((x, y) => x + y) / 4;
        final zB = vi2.map((i) => rotated[i][2]).reduce((x, y) => x + y) / 4;
        return zB.compareTo(zA);
      });

    for (final fd in facesSorted) {
      final face = fd['face'] as CubeFace;
      final vi = fd['vi'] as List;

      // Compute face normal to cull back faces
      final v0 = rotated[vi[0]];
      final v1 = rotated[vi[1]];
      final v2 = rotated[vi[2]];
      final nz =
          (v1[0] - v0[0]) * (v2[1] - v0[1]) - (v1[1] - v0[1]) * (v2[0] - v0[0]);

      // Back-face culling
      if (nz > 0) continue;

      // Project face corners
      final pts = vi.map((i) => project(rotated[i])).toList();

      // Compute the 3x3 grid for each sticker
      _drawFaceStickers(canvas, pts, face, nz);
    }
  }

  void _drawFaceStickers(
      Canvas canvas, List<Offset> corners, CubeFace face, double lighting) {
    final colors = cubeState.faces[face]!;

    // Bilinear interpolation for sticker grid
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final t0 = col / 3;
        final t1 = (col + 1) / 3;
        final s0 = row / 3;
        final s1 = (row + 1) / 3;

        // Face corners: tl, tr, br, bl
        final tl = corners[0]; // top-left
        final tr = corners[1]; // top-right
        final br = corners[2]; // bottom-right
        final bl = corners[3]; // bottom-left

        Offset lerp2D(
            Offset a, Offset b, Offset c, Offset d, double t, double s) {
          final top = Offset.lerp(a, b, t)!;
          final bot = Offset.lerp(d, c, t)!;
          return Offset.lerp(top, bot, s)!;
        }

        final p00 = lerp2D(tl, tr, br, bl, t0, s0);
        final p10 = lerp2D(tl, tr, br, bl, t1, s0);
        final p11 = lerp2D(tl, tr, br, bl, t1, s1);
        final p01 = lerp2D(tl, tr, br, bl, t0, s1);

        final stickerIdx = row * 3 + col;
        final cubeColor = colors[stickerIdx];

        // Light shade
        final shade = ((-lighting + 0.3) / 1.3).clamp(0.0, 1.0);
        final baseColor = Color(cubeColor.colorValue);
        final shadedColor =
            Color.lerp(Colors.black, baseColor, 0.3 + shade * 0.7)!;

        final path = Path()
          ..moveTo(p00.dx, p00.dy)
          ..lineTo(p10.dx, p10.dy)
          ..lineTo(p11.dx, p11.dy)
          ..lineTo(p01.dx, p01.dy)
          ..close();

        // Shrink sticker slightly for gap
        final center = Offset(
          (p00.dx + p10.dx + p11.dx + p01.dx) / 4,
          (p00.dy + p10.dy + p11.dy + p01.dy) / 4,
        );
        final shrunkenPath = Path();
        const gap = 0.88;
        for (final pt in [p00, p10, p11, p01]) {
          final shrunk = Offset.lerp(center, pt, gap)!;
          if (pt == p00) {
            shrunkenPath.moveTo(shrunk.dx, shrunk.dy);
          } else {
            shrunkenPath.lineTo(shrunk.dx, shrunk.dy);
          }
        }
        shrunkenPath.close();

        // Background (black gap)
        canvas.drawPath(
            path,
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.fill);

        // Sticker
        canvas.drawPath(
          shrunkenPath,
          Paint()
            ..color = shadedColor
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  List<double> _rotate(List<double> v, double rx, double ry) {
    // Rotate Y
    double x1 = v[0] * cos(ry) + v[2] * sin(ry);
    double y1 = v[1];
    double z1 = -v[0] * sin(ry) + v[2] * cos(ry);

    // Rotate X
    double x2 = x1;
    double y2 = y1 * cos(rx) - z1 * sin(rx);
    double z2 = y1 * sin(rx) + z1 * cos(rx);

    return [x2, y2, z2];
  }

  @override
  bool shouldRepaint(_Cube3DPainter old) => true;
}

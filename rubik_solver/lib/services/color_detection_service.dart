// lib/services/color_detection_service.dart

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/cube_model.dart';

class ColorDetectionService {
  // Detect cube colors from raw pixel data
  // Grid layout: 3x3 stickers in the captured region
  static List<CubeColor> detectColorsFromPixels({
    required Uint8List pixels,
    required int width,
    required int height,
    required Rect detectionRect,
  }) {
    final colors = <CubeColor>[];
    final cellW = detectionRect.width / 3;
    final cellH = detectionRect.height / 3;
    final samplePad = 0.25; // sample inner 50% of each cell

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        // Sample center area of each cell
        final cellLeft = detectionRect.left + col * cellW;
        final cellTop = detectionRect.top + row * cellH;

        final sampleLeft   = (cellLeft + cellW * samplePad).round();
        final sampleTop    = (cellTop  + cellH * samplePad).round();
        final sampleRight  = (cellLeft + cellW * (1 - samplePad)).round();
        final sampleBottom = (cellTop  + cellH * (1 - samplePad)).round();

        int rSum = 0, gSum = 0, bSum = 0, count = 0;

        for (int y = sampleTop; y < sampleBottom && y < height; y++) {
          for (int x = sampleLeft; x < sampleRight && x < width; x++) {
            final idx = (y * width + x) * 4;
            if (idx + 3 < pixels.length) {
              rSum += pixels[idx];
              gSum += pixels[idx + 1];
              bSum += pixels[idx + 2];
              count++;
            }
          }
        }

        if (count == 0) {
          colors.add(CubeColor.unknown);
          continue;
        }

        final r = rSum ~/ count;
        final g = gSum ~/ count;
        final b = bSum ~/ count;
        colors.add(_classifyColor(r, g, b));
      }
    }

    return colors;
  }

  // Classify an RGB value to a Rubik's cube color
  static CubeColor _classifyColor(int r, int g, int b) {
    // Convert to HSV for better color classification
    final hsv = _rgbToHsv(r, g, b);
    final h = hsv[0]; // 0-360
    final s = hsv[1]; // 0-1
    final v = hsv[2]; // 0-1

    // White: low saturation, high value
    if (s < 0.20 && v > 0.75) return CubeColor.white;

    // Yellow: hue 40-70, good saturation
    if (h >= 40 && h <= 70 && s > 0.5 && v > 0.5) return CubeColor.yellow;

    // Orange: hue 15-40
    if (h >= 15 && h <= 40 && s > 0.5 && v > 0.3) return CubeColor.orange;

    // Red: hue 0-15 or 340-360
    if ((h >= 340 || h <= 15) && s > 0.5 && v > 0.3) return CubeColor.red;

    // Green: hue 90-170
    if (h >= 90 && h <= 170 && s > 0.3 && v > 0.2) return CubeColor.green;

    // Blue: hue 180-270
    if (h >= 180 && h <= 270 && s > 0.3 && v > 0.2) return CubeColor.blue;

    return CubeColor.unknown;
  }

  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final maxC = [rf, gf, bf].reduce(max);
    final minC = [rf, gf, bf].reduce(min);
    final delta = maxC - minC;

    double h = 0;
    if (delta != 0) {
      if (maxC == rf) {
        h = 60 * (((gf - bf) / delta) % 6);
      } else if (maxC == gf) {
        h = 60 * (((bf - rf) / delta) + 2);
      } else {
        h = 60 * (((rf - gf) / delta) + 4);
      }
    }
    if (h < 0) h += 360;

    final s = maxC == 0 ? 0.0 : delta / maxC;
    final v = maxC;

    return [h, s, v];
  }

  // Simulate detection for testing (returns plausible colors)
  static List<CubeColor> simulateDetection(CubeFace face) {
    final center = face.expectedCenterColor;
    // Center is always the face color; edges/corners may vary
    return [
      _randomNeighbor(face, 0), _randomNeighbor(face, 1), _randomNeighbor(face, 2),
      _randomNeighbor(face, 3), center,                   _randomNeighbor(face, 5),
      _randomNeighbor(face, 6), _randomNeighbor(face, 7), _randomNeighbor(face, 8),
    ];
  }

  static final _faceNeighbors = <CubeFace, List<CubeColor>>{
    CubeFace.up:    [CubeColor.white, CubeColor.red, CubeColor.blue, CubeColor.orange, CubeColor.green],
    CubeFace.down:  [CubeColor.yellow, CubeColor.red, CubeColor.blue, CubeColor.orange, CubeColor.green],
    CubeFace.front: [CubeColor.red, CubeColor.white, CubeColor.blue, CubeColor.yellow, CubeColor.green],
    CubeFace.back:  [CubeColor.orange, CubeColor.white, CubeColor.blue, CubeColor.yellow, CubeColor.green],
    CubeFace.left:  [CubeColor.green, CubeColor.white, CubeColor.red, CubeColor.yellow, CubeColor.orange],
    CubeFace.right: [CubeColor.blue, CubeColor.white, CubeColor.red, CubeColor.yellow, CubeColor.orange],
  };

  static CubeColor _randomNeighbor(CubeFace face, int idx) {
    final neighbors = _faceNeighbors[face]!;
    // Use deterministic pseudo-random based on face + position
    final i = (face.index * 9 + idx) % neighbors.length;
    return neighbors[i];
  }
}

// Overlay painter for the camera scan grid
class ScanGridPainter extends CustomPainter {
  final Color gridColor;
  final bool isScanning;
  final double animationValue;

  ScanGridPainter({
    required this.gridColor,
    this.isScanning = false,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer border
    final borderPaint = Paint()
      ..color = gridColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Corner markers
    const cornerSize = 20.0;
    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (final corner in corners) {
      final dx = corner.dx == 0 ? 1.0 : -1.0;
      final dy = corner.dy == 0 ? 1.0 : -1.0;
      canvas.drawLine(corner, corner + Offset(cornerSize * dx, 0), borderPaint);
      canvas.drawLine(corner, corner + Offset(0, cornerSize * dy), borderPaint);
    }

    // Inner 3x3 grid
    final cellW = size.width / 3;
    final cellH = size.height / 3;

    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(cellW * i, 0),
        Offset(cellW * i, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, cellH * i),
        Offset(size.width, cellH * i),
        paint,
      );
    }

    // Scan line animation
    if (isScanning) {
      final scanPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final scanY = size.height * animationValue;
      canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
    }
  }

  @override
  bool shouldRepaint(ScanGridPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isScanning != isScanning;
}

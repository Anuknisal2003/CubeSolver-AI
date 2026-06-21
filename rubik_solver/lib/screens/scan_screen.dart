// lib/screens/scan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../models/cube_model.dart';
import '../services/color_detection_service.dart';
import '../services/cube_provider.dart';
import '../widgets/face_preview_widget.dart';
import 'solution_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with TickerProviderStateMixin {
  CameraController? _camController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _isScanning = false;
  bool _showSuccess = false;

  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late Animation<double> _scanLine;
  late Animation<double> _pulse;

  static const _faceOrder = [
    CubeFace.up,
    CubeFace.front,
    CubeFace.right,
    CubeFace.back,
    CubeFace.left,
    CubeFace.down,
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
  }

  void _initAnimations() {
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scanLine = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );
    _pulse = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _useDemoMode();
        return;
      }
      _camController = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _camController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      _useDemoMode();
    }
  }

  void _useDemoMode() {
    if (mounted) setState(() => _cameraReady = true);
  }

  Future<void> _captureAndDetect() async {
    if (_isScanning) return;
    final face = _currentFace;
    if (face == null) return;

    setState(() => _isScanning = true);
    _scanLineController.repeat();
    _pulseController.repeat(reverse: true);

    // Simulate scan delay for UX
    await Future.delayed(const Duration(milliseconds: 1200));

    List<CubeColor> detectedColors;

    if (_camController != null && _cameraReady) {
      try {
        await _camController!.takePicture();
        // In production: use image bytes + ColorDetectionService.detectColorsFromPixels
        // For now, use simulation (integrating real detection needs native plugin)
        detectedColors = ColorDetectionService.simulateDetection(face);
      } catch (_) {
        detectedColors = ColorDetectionService.simulateDetection(face);
      }
    } else {
      detectedColors = ColorDetectionService.simulateDetection(face);
    }

    if (mounted) {
      ref.read(cubeProvider.notifier).updateFace(face, detectedColors);
      final scanned = Set<CubeFace>.from(ref.read(scannedFacesProvider));
      scanned.add(face);
      ref.read(scannedFacesProvider.notifier).state = scanned;

      // Move to next face
      final nextIdx = _faceOrder.indexOf(face) + 1;
      if (nextIdx < _faceOrder.length) {
        ref.read(currentFaceProvider.notifier).state = _faceOrder[nextIdx];
      }

      _scanLineController.stop();
      _pulseController.stop();
      setState(() {
        _isScanning = false;
        _showSuccess = true;
      });

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _showSuccess = false);
    }
  }

  CubeFace? get _currentFace {
    final scanned = ref.read(scannedFacesProvider);
    if (scanned.length >= 6) return null;
    return ref.read(currentFaceProvider);
  }

  @override
  void dispose() {
    _camController?.dispose();
    _scanLineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubeState = ref.watch(cubeProvider);
    final scanned = ref.watch(scannedFacesProvider);
    final currentFace = ref.watch(currentFaceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scanned.length),
            Expanded(child: _buildCameraArea(currentFace, scanned)),
            _buildFaceSelector(cubeState, scanned, currentFace),
            _buildBottomBar(scanned, currentFace),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int scannedCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scan Your Cube',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$scannedCount / 6 faces scanned',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          // Progress indicator
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: scannedCount / 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Colors.cyanAccent),
                  strokeWidth: 3,
                ),
                Text(
                  '$scannedCount/6',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea(CubeFace currentFace, Set<CubeFace> scanned) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Camera preview or placeholder
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.black,
          ),
          clipBehavior: Clip.antiAlias,
          child: _camController != null && _cameraReady
              ? AspectRatio(
                  aspectRatio: _camController!.value.aspectRatio,
                  child: CameraPreview(_camController!),
                )
              : _buildDemoBackground(currentFace),
        ),

        // Scan grid overlay
        AnimatedBuilder(
          animation: _scanLine,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Center(
                  child: ScaleTransition(
                    scale: _pulse,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.55,
                      height: MediaQuery.of(context).size.width * 0.55,
                      child: CustomPaint(
                        painter: ScanGridPainter(
                          gridColor: _showSuccess
                              ? Colors.greenAccent
                              : Colors.cyanAccent,
                          isScanning: _isScanning,
                          animationValue: _scanLine.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Success overlay
        if (_showSuccess)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.greenAccent.withValues(alpha: 0.15),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 64),
                  SizedBox(height: 8),
                  Text(
                    'Face Captured!',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Face instruction banner
        if (!_showSuccess)
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentFace.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    'Point at ${currentFace.displayName} face',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDemoBackground(CubeFace face) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Color(face.expectedCenterColor.colorValue).withValues(alpha: 0.3),
            const Color(0xFF0A0A1A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt,
              color: Colors.white24,
              size: 48,
            ),
            const SizedBox(height: 8),
            const Text(
              'Demo Mode\n(Camera not available)',
              style: TextStyle(color: Colors.white30, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaceSelector(
      CubeState cube, Set<CubeFace> scanned, CubeFace current) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _faceOrder.length,
        itemBuilder: (context, i) {
          final face = _faceOrder[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FaceTile(
              face: face,
              colors: cube.faces[face]!,
              isScanned: scanned.contains(face),
              isActive: face == current,
              onTap: () {
                ref.read(currentFaceProvider.notifier).state = face;
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(Set<CubeFace> scanned, CubeFace currentFace) {
    final allDone = scanned.length >= 6;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Manual adjust hint
          if (!allDone)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Tap a face tile to switch • Tap stickers to correct colors',
                style: TextStyle(color: Colors.white38, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),

          if (!allDone)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _captureAndDetect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isScanning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          ),
                          SizedBox(width: 10),
                          Text('Scanning...', style: TextStyle(fontSize: 16)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera),
                          const SizedBox(width: 8),
                          Text(
                            'Scan ${currentFace.displayName}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),

          if (allDone) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.greenAccent),
                  SizedBox(width: 8),
                  Text(
                    'All 6 faces scanned! Ready to solve.',
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SolutionScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_fix_high),
                    SizedBox(width: 8),
                    Text('Solve Cube!',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

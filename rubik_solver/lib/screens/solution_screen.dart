// lib/screens/solution_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/cube_model.dart';
import '../services/cube_provider.dart';
import '../widgets/cube_3d_widget.dart';

class SolutionScreen extends ConsumerStatefulWidget {
  const SolutionScreen({super.key});

  @override
  ConsumerState<SolutionScreen> createState() => _SolutionScreenState();
}

class _SolutionScreenState extends ConsumerState<SolutionScreen>
    with TickerProviderStateMixin {
  late AnimationController _solveAnimController;
  int _currentStep = 0;
  bool _isAnimating = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _solveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSolving());
  }

  Future<void> _startSolving() async {
    final controller = ref.read(solveControllerProvider);
    await controller.solve();
  }

  @override
  void dispose() {
    _solveAnimController.dispose();
    super.dispose();
  }

  Future<void> _playAll() async {
    final solution = ref.read(solutionProvider);
    if (solution == null) return;

    setState(() => _isPlaying = true);
    for (int i = _currentStep; i < solution.steps.length; i++) {
      if (!_isPlaying || !mounted) break;
      setState(() => _currentStep = i);
      await Future.delayed(const Duration(milliseconds: 900));
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  void _stopPlay() => setState(() => _isPlaying = false);

  void _nextStep() {
    final solution = ref.read(solutionProvider);
    if (solution == null) return;
    if (_currentStep < solution.steps.length - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final solution = ref.watch(solutionProvider);
    final isSolving = ref.watch(isSolvingProvider);
    final cubeState = ref.watch(cubeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: isSolving
            ? _buildSolvingLoader()
            : solution == null
                ? _buildError()
                : _buildSolutionView(solution, cubeState),
      ),
    );
  }

  Widget _buildSolvingLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.cyanAccent),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Computing solution...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Running Two-Phase Algorithm',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ]
            .animate(interval: 200.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.3, end: 0),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          const Text('Could not generate solution',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back',
                style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionView(SolveSolution solution, CubeState cubeState) {
    final currentStep = solution.steps.isNotEmpty &&
            _currentStep < solution.steps.length
        ? solution.steps[_currentStep]
        : null;

    return Column(
      children: [
        _buildHeader(solution),
        // 3D Cube + current move display
        Container(
          height: 260,
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Cube3DWidget(
                cubeState: cubeState,
                size: 220,
                animate: _isPlaying,
                highlightMove: currentStep?.move,
              ),
              if (currentStep != null)
                Positioned(
                  bottom: 0,
                  child: _buildMoveLabel(currentStep),
                ),
            ],
          ),
        ),

        // Stats row
        _buildStatsRow(solution),

        // Step-by-step moves
        Expanded(
          child: _buildStepsList(solution),
        ),

        // Playback controls
        _buildPlaybackControls(solution),
      ],
    );
  }

  Widget _buildHeader(SolveSolution solution) {
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
                  'Solution Found!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${solution.totalMoves} moves • ${solution.solveTime.inMilliseconds}ms',
                  style:
                      const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Colors.greenAccent, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${solution.totalMoves} moves',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveLabel(SolveStep step) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyanAccent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              step.move,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            step.description,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(SolveSolution solution) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statChip(Icons.list_alt, '${solution.totalMoves}', 'Moves'),
          const SizedBox(width: 8),
          _statChip(Icons.timer, '${solution.solveTime.inMilliseconds}ms', 'Solve Time'),
          const SizedBox(width: 8),
          _statChip(
              Icons.navigate_next,
              '${_currentStep + 1}/${solution.steps.length}',
              'Progress'),
        ].map((w) => Expanded(child: w)).toList(),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStepsList(SolveSolution solution) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: solution.steps.length,
        itemBuilder: (context, i) {
          final step = solution.steps[i];
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;

          return GestureDetector(
            onTap: () => setState(() => _currentStep = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.cyanAccent.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? Colors.cyanAccent.withOpacity(0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Step number
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        color: isDone
                            ? Colors.greenAccent
                            : isActive
                                ? Colors.cyanAccent
                                : Colors.white30,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Move badge
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.cyanAccent
                          : isDone
                              ? Colors.greenAccent.withOpacity(0.2)
                              : Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      step.move,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Description
                  Expanded(
                    child: Text(
                      step.description,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Done check
                  if (isDone)
                    const Icon(Icons.check,
                        color: Colors.greenAccent, size: 16),
                  if (isActive)
                    const Icon(Icons.play_arrow,
                        color: Colors.cyanAccent, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaybackControls(SolveSolution solution) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Prev
          _controlButton(
            icon: Icons.skip_previous,
            onTap: _currentStep > 0 ? _prevStep : null,
            tooltip: 'Previous',
          ),
          const SizedBox(width: 8),

          // Play/Pause
          Expanded(
            child: ElevatedButton(
              onPressed: _isPlaying ? _stopPlay : _playAll,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isPlaying ? Colors.orangeAccent : Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  const SizedBox(width: 6),
                  Text(
                    _isPlaying ? 'Pause' : 'Play All Steps',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Next
          _controlButton(
            icon: Icons.skip_next,
            onTap: _currentStep < solution.steps.length - 1
                ? _nextStep
                : null,
            tooltip: 'Next',
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: onTap != null
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(
            icon,
            color: onTap != null ? Colors.white70 : Colors.white20,
            size: 22,
          ),
        ),
      ),
    );
  }
}

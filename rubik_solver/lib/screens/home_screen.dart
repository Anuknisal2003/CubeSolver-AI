// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/cube_provider.dart';
import '../services/firebase_service.dart';
import '../models/cube_model.dart';
import '../widgets/cube_3d_widget.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await FirebaseService.getUserStats();
    if (mounted) setState(() { _stats = stats; _loadingStats = false; });
  }

  @override
  Widget build(BuildContext context) {
    final cube = ref.watch(cubeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildHero(cube)),
            SliverToBoxAdapter(child: _buildStatsRow()),
            SliverToBoxAdapter(child: _buildQuickActions()),
            SliverToBoxAdapter(child: _buildHowItWorks()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0A0A1A),
      floating: true,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFFF), Color(0xFF9B59B6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.view_in_ar, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'CubeSolver AI',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.white70),
          onPressed: _showHistory,
        ),
        IconButton(
          icon: const Icon(Icons.leaderboard, color: Colors.white70),
          onPressed: _showLeaderboard,
        ),
      ],
    );
  }

  Widget _buildHero(CubeState cube) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A3E),
            const Color(0xFF0D0D2B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Cube3DWidget(
            cubeState: cube,
            size: 180,
            animate: true,
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 20),
          const Text(
            'Scan · Solve · Learn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          const Text(
            'Point your camera at each face of your\nRubik\'s cube and get an instant solution',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Start Scanning',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_loadingStats) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.cyanAccent, strokeWidth: 2),
        ),
      );
    }

    final total = _stats['total'] ?? 0;
    final best = _stats['bestMoves'];
    final avg = _stats['avgMoves'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard('Solves', '$total', Icons.check_circle_outline,
              Colors.greenAccent),
          const SizedBox(width: 10),
          _buildStatCard('Best', best != null ? '$best moves' : '-',
              Icons.emoji_events, Colors.amberAccent),
          const SizedBox(width: 10),
          _buildStatCard(
              'Average', avg != null ? '$avg' : '-', Icons.bar_chart, Colors.purpleAccent),
        ].map((w) => Expanded(child: w)).toList(),
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(label,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              _actionTile(
                icon: Icons.camera,
                label: 'New Scan',
                subtitle: 'Scan all 6 faces',
                color: Colors.cyanAccent,
                onTap: _startScan,
              ),
              const SizedBox(width: 10),
              _actionTile(
                icon: Icons.touch_app,
                label: 'Manual Input',
                subtitle: 'Tap to set colors',
                color: Colors.orangeAccent,
                onTap: _startManual,
              ),
            ].map((w) => Expanded(child: w)).toList(),
          ),
        ],
      ).animate().fadeIn(delay: 300.ms),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    final steps = [
      ('1', Icons.camera_alt, Colors.cyanAccent,
          'Scan', 'Point camera at each face'),
      ('2', Icons.auto_fix_high, Colors.purpleAccent,
          'Solve', 'AI computes optimal solution'),
      ('3', Icons.view_in_ar, Colors.greenAccent,
          'Follow', 'Follow 3D animated steps'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'How It Works',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...steps.asMap().entries.map((e) {
            final (num, icon, color, title, desc) = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(desc,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ).animate().fadeIn(delay: 400.ms),
    );
  }

  void _startScan() {
    ref.read(cubeProvider.notifier).reset();
    ref.read(scannedFacesProvider.notifier).state = {};
    ref.read(currentFaceProvider.notifier).state = CubeFace.up;
    ref.read(solutionProvider.notifier).state = null;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  void _startManual() {
    ref.read(cubeProvider.notifier).reset();
    ref.read(scannedFacesProvider.notifier).state = {};
    ref.read(currentFaceProvider.notifier).state = CubeFace.up;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('History',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: FirebaseService.getPastSessions(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.cyanAccent));
                    }
                    final sessions = snap.data ?? [];
                    if (sessions.isEmpty) {
                      return const Center(
                        child: Text('No past sessions yet.',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: sessions.length,
                      itemBuilder: (_, i) {
                        final s = sessions[i];
                        return ListTile(
                          leading: const Icon(Icons.view_in_ar,
                              color: Colors.cyanAccent),
                          title: Text('Session ${i + 1}',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                              s.capturedAt?.toString().split('.')[0] ?? '',
                              style:
                                  const TextStyle(color: Colors.white54)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLeaderboard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.emoji_events, color: Colors.amberAccent),
                SizedBox(width: 8),
                Text('Leaderboard',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder(
                  future: FirebaseService.getLeaderboard(),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.amberAccent));
                    }
                    final board = snap.data ?? [];
                    if (board.isEmpty) {
                      return const Center(
                          child: Text('No scores yet!',
                              style: TextStyle(color: Colors.white38)));
                    }
                    return ListView.builder(
                      controller: sc,
                      itemCount: board.length,
                      itemBuilder: (_, i) {
                        final entry = board[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? Colors.amberAccent.withOpacity(0.1)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: i == 0
                                    ? Colors.amberAccent.withOpacity(0.3)
                                    : Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '#${i + 1}',
                                style: TextStyle(
                                  color: i == 0
                                      ? Colors.amberAccent
                                      : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${entry['moveCount'] ?? '?'} moves',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                '${entry['solveTimeMs'] ?? '?'}ms',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

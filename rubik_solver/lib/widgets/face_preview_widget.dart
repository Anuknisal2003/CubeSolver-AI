// lib/widgets/face_preview_widget.dart

import 'package:flutter/material.dart';
import '../models/cube_model.dart';

class FacePreviewWidget extends StatelessWidget {
  final CubeFace face;
  final List<CubeColor> colors;
  final double size;
  final bool interactive;
  final Function(int index, CubeColor color)? onStickerTap;
  final bool showLabel;
  final bool isActive;

  const FacePreviewWidget({
    super.key,
    required this.face,
    required this.colors,
    this.size = 100,
    this.interactive = false,
    this.onStickerTap,
    this.showLabel = true,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size / 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(face.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  face.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.cyanAccent : Colors.white30,
              width: isActive ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1.5,
                crossAxisSpacing: 1.5,
              ),
              itemCount: 9,
              itemBuilder: (context, i) {
                final color = colors.length > i ? colors[i] : CubeColor.unknown;
                final isCenter = i == 4;

                return GestureDetector(
                  onTap: interactive && onStickerTap != null
                      ? () => _showColorPicker(context, i)
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: Color(color.colorValue),
                    child: isCenter
                        ? Center(
                            child: Container(
                              width: cellSize * 0.3,
                              height: cellSize * 0.3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Color',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: CubeColor.values
                    .where((c) => c != CubeColor.unknown)
                    .map((color) {
                  return GestureDetector(
                    onTap: () {
                      onStickerTap?.call(index, color);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(color.colorValue),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          color.name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// Mini face tile used in navigation
class FaceTile extends StatelessWidget {
  final CubeFace face;
  final List<CubeColor> colors;
  final bool isScanned;
  final bool isActive;
  final VoidCallback? onTap;

  const FaceTile({
    super.key,
    required this.face,
    required this.colors,
    required this.isScanned,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.cyanAccent.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? Colors.cyanAccent
                : isScanned
                    ? Colors.greenAccent.withOpacity(0.5)
                    : Colors.white12,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FacePreviewWidget(
              face: face,
              colors: colors,
              size: 52,
              showLabel: false,
            ),
            const SizedBox(height: 4),
            Text(
              face.shortName,
              style: TextStyle(
                color: isActive ? Colors.cyanAccent : Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isScanned)
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 12)
            else
              const Icon(Icons.circle_outlined, color: Colors.white30, size: 12),
          ],
        ),
      ),
    );
  }
}

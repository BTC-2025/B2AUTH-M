import 'package:flutter/material.dart';

class ViewfinderBracketPainter extends CustomPainter {
  final Color bracketColor;
  final double strokeWidth;
  final double cornerLength;
  final double padding;

  const ViewfinderBracketPainter({
    this.bracketColor = const Color(0xFF6366F1),
    this.strokeWidth = 3.5,
    this.cornerLength = 20.0,
    this.padding = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = bracketColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top Left
    canvas.drawLine(Offset(padding, padding + cornerLength), Offset(padding, padding), paint);
    canvas.drawLine(Offset(padding, padding), Offset(padding + cornerLength, padding), paint);

    // Top Right
    canvas.drawLine(Offset(size.width - padding - cornerLength, padding), Offset(size.width - padding, padding), paint);
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding, padding + cornerLength), paint);

    // Bottom Left
    canvas.drawLine(Offset(padding, size.height - padding - cornerLength), Offset(padding, size.height - padding), paint);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding + cornerLength, size.height - padding), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width - padding - cornerLength, size.height - padding), Offset(size.width - padding, size.height - padding), paint);
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding, size.height - padding - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanningLaserViewfinder extends StatefulWidget {
  final double height;
  final Color laserColor;
  final Widget? centerChild;

  const ScanningLaserViewfinder({
    super.key,
    this.height = 150.0,
    this.laserColor = const Color(0xFF6366F1),
    this.centerChild,
  });

  @override
  State<ScanningLaserViewfinder> createState() => _ScanningLaserViewfinderState();
}

class _ScanningLaserViewfinderState extends State<ScanningLaserViewfinder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double totalHeight = widget.height;
    const double minY = 16.0;
    final double maxY = totalHeight - 20.0;
    final double travelDistance = maxY - minY;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final scanProgress = _animation.value;
          final currentY = minY + (travelDistance * scanProgress);
          final isMovingDown = _controller.status != AnimationStatus.reverse;

          // Subtle pulse when laser crosses the center
          final distanceFromCenter = (scanProgress - 0.5).abs();
          final centerProximity = (1.0 - (distanceFromCenter * 2.2)).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Subtle HUD ambient background scan bloom
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: RadialGradient(
                        center: Alignment(0, (scanProgress - 0.5) * 1.6),
                        radius: 0.85,
                        colors: [
                          widget.laserColor.withValues(alpha: 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Viewfinder corner brackets
              CustomPaint(
                size: Size(double.infinity, totalHeight),
                painter: ViewfinderBracketPainter(bracketColor: widget.laserColor),
              ),

              // Center QR Icon / child with reactive laser highlight
              Opacity(
                opacity: 0.85 + (0.15 * centerProximity),
                child: Transform.scale(
                  scale: 1.0 + (0.05 * centerProximity),
                  child: widget.centerChild ??
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 54,
                        color: Color.lerp(
                          widget.laserColor,
                          const Color(0xFF4338CA),
                          centerProximity,
                        ),
                      ),
                ),
              ),

              // Trailing Volumetric Laser Aura / Gradient Sheet
              Positioned(
                top: isMovingDown ? (currentY - 26) : currentY,
                left: 20,
                right: 20,
                child: Container(
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isMovingDown ? Alignment.topCenter : Alignment.bottomCenter,
                      end: isMovingDown ? Alignment.bottomCenter : Alignment.topCenter,
                      colors: [
                        Colors.transparent,
                        widget.laserColor.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Glowing Laser Beam
              Positioned(
                top: currentY,
                left: 18,
                right: 18,
                child: Container(
                  height: 2.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0x33818CF8),
                        Color(0xFF818CF8),
                        Color(0xFFFFFFFF),
                        Color(0xFF818CF8),
                        Color(0x33818CF8),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.12, 0.32, 0.5, 0.68, 0.88, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.laserColor.withValues(alpha: 0.95),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF818CF8).withValues(alpha: 0.65),
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyGameApp());
}

class StudyGameApp extends StatelessWidget {
  const StudyGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameSplashScreen(),
    );
  }
}

class GameSplashScreen extends StatefulWidget {
  const GameSplashScreen({Key? key}) : super(key: key);

  @override
  State<GameSplashScreen> createState() => _GameSplashScreenState();
}

class _GameSplashScreenState extends State<GameSplashScreen>
    with TickerProviderStateMixin {
  double _progress = 0.0;
  Timer? _finishTimer;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _loadingController;
  late final Animation<double> _loadingAnimation;

  bool _ready = false;

  static const Color _neonGreen = Color(0xFF00FF38);
  static const Color _limeGreen = Color(0xFFADFF2F);
  static const Color _darkGreen = Color(0xFF006400);

  @override
  void initState() {
    super.initState();

    // Smooth neon pulse. The original visual timing is preserved.
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // 3.45 seconds total, matching the original approximate loading time,
    // but rendered by Flutter's animation ticker instead of a 30 ms timer.
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 3450),
      vsync: this,
    );

    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.linear,
    )..addListener(() {
        if (!mounted) return;

        final t = _loadingAnimation.value;

        // Same non-linear loading idea:
        // 0–60% fast, 60–88% slow, 88–100% very fast.
        double p;
        if (t < 0.349) {
          p = (t / 0.349) * 0.60;
        } else if (t < 0.959) {
          p = 0.60 + ((t - 0.349) / 0.610) * 0.28;
        } else {
          p = 0.88 + ((t - 0.959) / 0.041) * 0.12;
        }

        setState(() {
          _progress = p.clamp(0.0, 1.0);
        });
      });

    _startUltraSmoothLoading();
  }

  void _startUltraSmoothLoading() {
    _loadingController.forward(from: 0.0);

    _finishTimer = Timer(
      const Duration(milliseconds: 3500),
      () {
        if (!mounted) return;

        setState(() {
          _progress = 1.0;
          _ready = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. MAIN WARRIOR BACKGROUND
          // Put the generated 4K-style artwork at:
          // assets/images/archer_hero.png
          Image.asset(
            'assets/images/archer_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF050A05),
                child: const Center(
                  child: Icon(
                    Icons.flash_on,
                    size: 100,
                    color: _neonGreen,
                  ),
                ),
              );
            },
          ),

          // 2. DARK VIGNETTE
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.42, 0.72, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.30),
                    Colors.transparent,
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.90),
                  ],
                ),
              ),
            ),
          ),

          // 3. SUBTLE NEON ATMOSPHERE AT THE BOTTOM
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 210,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.8),
                    radius: 1.0,
                    colors: [
                      _neonGreen.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. BOTTOM NEON GREEN LOADING SECTION
          Positioned(
            bottom: 40,
            left: 25,
            right: 25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PULSING LOADING TEXT
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Text(
                      _ready
                          ? '🏹 TAP TO UNLEASH BATTLE 🏹'
                          : 'LOADING... ${(_progress * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: _neonGreen,
                        shadows: [
                          Shadow(
                            color: _neonGreen.withOpacity(
                              _pulseAnimation.value,
                            ),
                            blurRadius: 20,
                          ),
                          Shadow(
                            color: _neonGreen.withOpacity(0.35),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                // ARROW-SHAPED NEON PROGRESS BAR
                RepaintBoundary(
                  child: SizedBox(
                    height: 30,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _NeonArrowProgressPainter(
                        progress: _progress,
                        neonGreen: _neonGreen,
                        limeGreen: _limeGreen,
                        darkGreen: _darkGreen,
                        pulse: _pulseAnimation.value,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonArrowProgressPainter extends CustomPainter {
  final double progress;
  final Color neonGreen;
  final Color limeGreen;
  final Color darkGreen;
  final double pulse;

  const _NeonArrowProgressPainter({
    required this.progress,
    required this.neonGreen,
    required this.limeGreen,
    required this.darkGreen,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = 2.0;
    final double right = size.width - 2.0;
    final double centerY = size.height / 2;
    final double barTop = 5.0;
    final double barBottom = size.height - 5.0;
    final double radius = 10.0;

    final RRect outer = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, barTop, right, barBottom),
      Radius.circular(radius),
    );

    // Outer neon glow.
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = neonGreen.withOpacity(0.30 + (0.25 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawRRect(outer, glowPaint);

    // Crisp outer border.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = neonGreen;

    canvas.drawRRect(outer, borderPaint);

    // Inner dark track.
    final track = RRect.fromRectAndRadius(
      Rect.fromLTRB(
        left + 3,
        barTop + 3,
        right - 3,
        barBottom - 3,
      ),
      Radius.circular(7),
    );

    final trackPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(0.58);

    canvas.drawRRect(track, trackPaint);

    if (progress <= 0.0) return;

    // Reserve space for the arrow head.
    final arrowSpace = 25.0;
    final fillStart = left + 4;
    final fillEnd = left +
        4 +
        math.max(
          0.0,
          (right - left - 8 - arrowSpace) * progress,
        );

    final fillRect = Rect.fromLTRB(
      fillStart,
      barTop + 4,
      math.max(fillStart, fillEnd),
      barBottom - 4,
    );

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [
          darkGreen,
          neonGreen,
          limeGreen,
        ],
      ).createShader(fillRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        fillRect,
        const Radius.circular(6),
      ),
      fillPaint,
    );

    // Bright fill glow.
    final glowFillPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = neonGreen.withOpacity(0.42 + (pulse * 0.25))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    if (fillRect.width > 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          fillRect,
          const Radius.circular(6),
        ),
        glowFillPaint,
      );
    }

    // Moving arrow tip.
    final arrowX = math.min(
      right - 3,
      fillEnd + 5,
    );

    final Path arrow = Path()
      ..moveTo(arrowX - 11, centerY - 8)
      ..lineTo(arrowX + 5, centerY)
      ..lineTo(arrowX - 11, centerY + 8)
      ..lineTo(arrowX - 6, centerY)
      ..close();

    final arrowGlow = Paint()
      ..style = PaintingStyle.fill
      ..color = limeGreen.withOpacity(0.45 + pulse * 0.25)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        7,
      );

    canvas.drawPath(arrow, arrowGlow);

    final arrowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = limeGreen;

    canvas.drawPath(arrow, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _NeonArrowProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse;
  }
}

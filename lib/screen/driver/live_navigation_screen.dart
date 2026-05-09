// ════════════════════════════════════════════════════════════
//  live_navigation_screen.dart
//  مطابق بالكامل لـ LiveNavigation.tsx (React Native / Framer Motion)
//
//  الـ animations المنقولة:
//  • Simulated map: gradient bg + grid overlay + animated SVG route
//  • Route path draw: pathLength 0 → 0.65 في 1.5s easeOut
//  • Driver dot: scale [1,1.3,1] + opacity [1,0.8,1] 2s ∞
//  • Nav icon bounce: y [0,−10,0] 2s easeInOut ∞
//  • Next Turn Card: y:−20→0 + opacity:0→1 على mount
//  • Bottom Info Card: y:100→0 + opacity:0→1 spring على mount
//  • End Trip Modal: backdrop opacity 0→1 + card scale 0.9→1 + opacity 0→1
//  • Buttons: scale 0.95 on press (active:scale-95)
//
//  لا تحتاج أي package خارجي — كل حاجة بـ Flutter animations المدمجة
// ════════════════════════════════════════════════════════════
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─── Trip Constants ──────────────────────────────────────
const _kShipmentId       = 'SHP-4521';
const _kTo               = 'New Cairo Tech Hub';
const _kEta              = '38 min';
const _kDistance         = '12.4 mi';
const _kNextTurn         = 'Turn right on Ring Road';
const _kNextTurnDistance = '0.5 mi';

// ─── Colors (RN palette) ─────────────────────────────────
const _kCyan    = Color(0xFF00D5BE);
const _kCyan2   = Color(0xFF00BBA7);
const _kRed     = Color(0xFFFF6B6B);   // RN: #ff6b6b
const _kRedDark = Color(0xFFEE5A52);   // RN: #ee5a52
const _kBg      = Color(0xFF0F2334);
const _kMuted   = Color(0xFFCBFBF1);

// ════════════════════════════════════════════════════════════
//  PRESS SCALE  (RN: active:scale-95 transition-transform)
// ════════════════════════════════════════════════════════════
class _PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressScale({required this.child, required this.onTap});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) {
          _c.reverse();
          widget.onTap();
        },
        onTapCancel: () => _c.reverse(),
        child: AnimatedBuilder(
          animation: _s,
          builder: (_, child) =>
              Transform.scale(scale: _s.value, child: child),
          child: widget.child,
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  GRID PAINTER  (RN: 8 cols × 12 rows, cyan opacity 10%)
// ════════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _kCyan
      ..strokeWidth = 0.5;
    for (int c = 0; c <= 8; c++) {
      final x = size.width * c / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (int r = 0; r <= 12; r++) {
      final y = size.height * r / 12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ════════════════════════════════════════════════════════════
//  ROUTE PAINTER  (RN SVG pathLength 0 → 0.65 easeOut 1.5s)
//  path: M 100 600 Q 150 400, 200 350 T 280 200
// ════════════════════════════════════════════════════════════
class _RoutePainter extends CustomPainter {
  final double progress;
  const _RoutePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 375.0;
    final sy = size.height / 667.0;

    final path = Path()
      ..moveTo(100 * sx, 600 * sy)
      ..quadraticBezierTo(150 * sx, 400 * sy, 200 * sx, 350 * sy)
      ..quadraticBezierTo(250 * sx, 300 * sy, 280 * sx, 200 * sy);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final totalLen = metrics.fold(0.0, (s, m) => s + m.length);
    final drawLen = totalLen * progress;

    final paint = Paint()
      ..color = _kCyan
      ..strokeWidth = 6 * math.min(sx, sy)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double drawn = 0;
    for (final m in metrics) {
      final rem = drawLen - drawn;
      if (rem <= 0) break;
      canvas.drawPath(m.extractPath(0, math.min(rem, m.length)), paint);
      drawn += m.length;
    }
  }

  @override
  bool shouldRepaint(_RoutePainter o) => o.progress != progress;
}

// ════════════════════════════════════════════════════════════
//  SIMULATED MAP
//  RN: gradient bg + grid overlay + SVG animated route +
//      driver dot scale/opacity loop + nav icon bounce
// ════════════════════════════════════════════════════════════
class _SimulatedMap extends StatefulWidget {
  const _SimulatedMap();

  @override
  State<_SimulatedMap> createState() => _SimulatedMapState();
}

class _SimulatedMapState extends State<_SimulatedMap>
    with TickerProviderStateMixin {
  late final AnimationController _pathCtrl;
  late final Animation<double> _pathProg;

  late final AnimationController _dotCtrl;
  late final Animation<double> _dotScale;
  late final Animation<double> _dotOpacity;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceY;

  @override
  void initState() {
    super.initState();

    // Route draw: pathLength 0 → 0.65, 1500ms easeOut
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _pathProg = Tween<double>(begin: 0.0, end: 0.65)
        .animate(CurvedAnimation(parent: _pathCtrl, curve: Curves.easeOut));

    // Driver dot: scale [1,1.3,1] opacity [1,0.8,1] 2s ∞
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _dotScale = Tween<double>(begin: 1.0, end: 1.3)
        .animate(CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));
    _dotOpacity = Tween<double>(begin: 1.0, end: 0.8)
        .animate(CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));

    // Nav icon: y [0,−10,0] 2s easeInOut ∞
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _bounceY = Tween<double>(begin: 0.0, end: -10.0)
        .animate(
            CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _dotCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;
      final sx = w / 375.0;
      final sy = h / 667.0;

      final dotX = 280 * sx;
      final dotY = 200 * sy;
      final destX = 200 * sx;
      final destY = 350 * sy;
      final iconX = w / 2;
      final iconY = h * 0.33;

      return Stack(children: [
        // ── gradient background ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A2F42),
                Color(0xFF0F2334),
                Color(0xFF162838),
              ],
            ),
          ),
        ),

        // ── grid overlay 10% ──
        Opacity(
          opacity: 0.10,
          child: CustomPaint(size: Size(w, h), painter: _GridPainter()),
        ),

        // ── animated route path ──
        AnimatedBuilder(
          animation: _pathProg,
          builder: (_, __) => CustomPaint(
            size: Size(w, h),
            painter: _RoutePainter(_pathProg.value),
          ),
        ),

        // ── destination marker ──
        Positioned(
          left: destX - 12,
          top: destY - 12,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFFFF6B6B).withOpacity(0.5),
                    width: 2),
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6B6B).withOpacity(0.8),
              ),
            ),
          ]),
        ),

        // ── driver dot: scale + opacity loop ──
        Positioned(
          left: dotX - 18,
          top: dotY - 18,
          child: AnimatedBuilder(
            animation: _dotCtrl,
            builder: (_, __) => Transform.scale(
              scale: _dotScale.value,
              child: Opacity(
                opacity: _dotOpacity.value,
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _kCyan.withOpacity(0.3), width: 2),
                    ),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: _kCyan),
                  ),
                ]),
              ),
            ),
          ),
        ),

        // ── nav icon: y bounce −10px loop ──
        Positioned(
          left: iconX - 20,
          top: iconY - 20,
          child: AnimatedBuilder(
            animation: _bounceY,
            builder: (_, child) => Transform.translate(
                offset: Offset(0, _bounceY.value), child: child),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kCyan, _kCyan2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: _kCyan.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2)
                ],
              ),
              child: const Icon(Icons.navigation,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ]);
    });
  }
}

// ════════════════════════════════════════════════════════════
//  NEXT TURN CARD  (RN: y:−20→0, opacity:0→1 on mount)
// ════════════════════════════════════════════════════════════
class _NextTurnCard extends StatefulWidget {
  const _NextTurnCard();

  @override
  State<_NextTurnCard> createState() => _NextTurnCardState();
}

class _NextTurnCardState extends State<_NextTurnCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward();
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kBg.withOpacity(0.98),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kCyan.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kCyan, _kCyan2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.turn_right_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(_kNextTurn,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('in $_kNextTurnDistance',
                        style: TextStyle(
                            color: _kCyan.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  BOTTOM INFO CARD  (RN: y:100→0, opacity:0→1 spring)
// ════════════════════════════════════════════════════════════
class _BottomInfoCard extends StatefulWidget {
  final VoidCallback onContact;
  final VoidCallback onEndTrip;
  const _BottomInfoCard(
      {required this.onContact, required this.onEndTrip});

  @override
  State<_BottomInfoCard> createState() => _BottomInfoCardState();
}

class _BottomInfoCardState extends State<_BottomInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide =
        Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.25, 1.0],
                colors: [Colors.transparent, _kBg, _kBg],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kBg.withOpacity(0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kCyan.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ETA + Distance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ETA',
                            style: TextStyle(
                                color: _kMuted.withOpacity(0.5),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text(_kEta,
                            style: TextStyle(
                                color: _kCyan,
                                fontSize: 24,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Distance',
                            style: TextStyle(
                                color: _kMuted.withOpacity(0.5),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text(_kDistance,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: _kCyan.withOpacity(0.15)),
                const SizedBox(height: 16),

                // Destination
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Destination',
                          style: TextStyle(
                              color: _kMuted.withOpacity(0.5),
                              fontSize: 12)),
                      const SizedBox(height: 8),
                      const Text(_kTo,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4)),
                      const SizedBox(height: 4),
                      Text(_kShipmentId,
                          style: TextStyle(
                              color: _kMuted.withOpacity(0.5),
                              fontSize: 12,
                              fontFamily: 'monospace')),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Buttons
                Row(children: [
                  Expanded(
                    child: _PressScale(
                      onTap: widget.onContact,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _kCyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: _kCyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_outlined,
                                color: _kCyan, size: 16),
                            const SizedBox(width: 8),
                            Text('Contact',
                                style: TextStyle(
                                    color: _kCyan,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PressScale(
                      onTap: widget.onEndTrip,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [_kRed, _kRedDark]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: _kRed.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text('End Trip',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  END TRIP MODAL
//  RN: backdrop opacity 0→1  +  card scale 0.9→1 + opacity 0→1
//      tap outside = dismiss
// ════════════════════════════════════════════════════════════
class _EndTripModal extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  const _EndTripModal({required this.onConfirm, required this.onCancel});

  @override
  State<_EndTripModal> createState() => _EndTripModalState();
}

class _EndTripModalState extends State<_EndTripModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _backdrop;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..forward();
    _backdrop = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _cardScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => GestureDetector(
          onTap: widget.onCancel,
          child: Container(
            color: Colors.black.withOpacity(0.8 * _backdrop.value),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () {},
              child: Transform.scale(
                scale: _cardScale.value,
                child: Opacity(
                  opacity: _cardFade.value,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 384),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(24),
                      border:
                          Border.all(color: _kCyan.withOpacity(0.3)),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black38,
                            blurRadius: 32,
                            offset: Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Red alert icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [_kRed, _kRedDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                          ),
                          child: const Icon(Icons.error_outline_rounded,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 16),

                        const Text('Complete Trip?',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),

                        Text(
                          'Confirm that you have successfully delivered the shipment to $_kTo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _kMuted.withOpacity(0.6),
                              fontSize: 14,
                              height: 1.5),
                        ),
                        const SizedBox(height: 20),

                        // Yes button
                        _PressScale(
                          onTap: widget.onConfirm,
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_kCyan, _kCyan2]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: _kCyan.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text('Yes, Complete Trip',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cancel button
                        _PressScale(
                          onTap: widget.onCancel,
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF8E8E93).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF8E8E93)
                                      .withOpacity(0.3)),
                            ),
                            alignment: Alignment.center,
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: _kMuted.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

// ════════════════════════════════════════════════════════════
//  LIVE NAVIGATION SCREEN
// ════════════════════════════════════════════════════════════
class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({super.key});

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen> {
  bool _showModal = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // ── full screen content ──
        SafeArea(
          child: Stack(children: [
            // Simulated map
            const Positioned.fill(child: _SimulatedMap()),

            // Top controls row
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PressScale(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBg.withOpacity(0.95),
                        border:
                            Border.all(color: _kCyan.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  _PressScale(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kBg.withOpacity(0.95),
                        border:
                            Border.all(color: _kCyan.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.open_in_full_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Next Turn Card
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: _NextTurnCard(),
            ),

            // Bottom Info Card
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomInfoCard(
                onContact: () {},
                onEndTrip: () => setState(() => _showModal = true),
              ),
            ),
          ]),
        ),

        // ── End Trip Modal overlay ──
        if (_showModal)
          Positioned.fill(
            child: _EndTripModal(
              onConfirm: () {
                setState(() => _showModal = false);
                Navigator.pop(context);
              },
              onCancel: () => setState(() => _showModal = false),
            ),
          ),
      ]),
    );
  }
}
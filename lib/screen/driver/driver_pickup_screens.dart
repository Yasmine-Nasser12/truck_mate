// ════════════════════════════════════════════════════════════
//  driver_pickup_screens.dart  — Full Animations
//  1. PickupScreen              — Heading to Pickup
//  2. ArrivedAtPickupScreen     — You've Arrived
//  3. PickupConfirmationScreen  — Pickup Confirmed
//  4. InTransitScreen           — On the Way
//  5. DeliverySuccessScreen     — Delivered Successfully
// ════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ── Shared Palette ──
const Color _kTeal  = Color(0xFF00C9A7);
const Color _kAmber = Color(0xFFFFC107);
const Color _kGreen = Color(0xFF00E676);
const Color _kRed   = Color(0xFFEF4444);

// ── Theme helpers ──
Color _bg(bool d)     => d ? const Color(0xFF101D28) : const Color(0xFFF8FAFB);
Color _card(bool d)   => d ? const Color(0xFF162532) : Colors.white;
Color _text(bool d)   => d ? Colors.white             : const Color(0xFF1E272E);
Color _muted(bool d)  => d ? const Color(0xFF90A4AE)  : const Color(0xFF808E9B);
Color _border(bool d) => d ? const Color(0xFF2C3E50)  : const Color(0xFFE5E7EB);
Color _chipBg(bool d) => d ? const Color(0xFF142B2B)  : const Color(0xFFE9FFFB);


// ══════════════════════════════════════════════════════
//  SHARED: GRADIENT BUTTON with shimmer
// ══════════════════════════════════════════════════════
class _GradBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradBtn({required this.label, required this.icon, required this.onTap});
  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimCtrl;
  late Animation<double> _shimAnim;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimCtrl, curve: Curves.linear));
  }

  @override
  void dispose() { _shimCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [BoxShadow(
            color: _kTeal.withOpacity(0.4),
            blurRadius: 20, spreadRadius: 1, offset: const Offset(0, 5),
          )],
        ),
        child: Stack(alignment: Alignment.center, children: [
          // Shimmer sweep
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AnimatedBuilder(
              animation: _shimAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(_shimAnim.value * 200, 0),
                child: Container(
                  width: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white24, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(widget.label, style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: PULSING RINGS around icon
// ══════════════════════════════════════════════════════
class _PulsingRings extends StatefulWidget {
  final Color color;
  final Widget child;
  final double size;
  final int ringCount;
  const _PulsingRings({
    required this.color,
    required this.child,
    this.size = 80,
    this.ringCount = 2,
  });
  @override
  State<_PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<_PulsingRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _scales;
  late List<Animation<double>> _opacities;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    _scales = List.generate(widget.ringCount, (i) {
      final delay = i * (0.5 / widget.ringCount);
      return Tween<double>(begin: 1.0, end: 1.5).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
        ),
      );
    });

    _opacities = List.generate(widget.ringCount, (i) {
      final delay = i * (0.5 / widget.ringCount);
      return Tween<double>(begin: 0.5, end: 0.0).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
        ),
      );
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size, height: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        ...List.generate(widget.ringCount, (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.scale(
            scale: _scales[i].value,
            child: Container(
              width: widget.size, height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withOpacity(_opacities[i].value),
                  width: 2,
                ),
              ),
            ),
          ),
        )),
        widget.child,
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: MAP PAINTER
// ══════════════════════════════════════════════════════
class _MapPainter extends CustomPainter {
  final Color teal;
  final bool isDark;
  final double pathProgress;
  const _MapPainter(this.teal, {this.isDark = true, this.pathProgress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : teal).withOpacity(isDark ? 0.04 : 0.08)
      ..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 25) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 25) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Route path
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.7)
      ..cubicTo(
        size.width * 0.35, size.height * 0.2,
        size.width * 0.65, size.height * 0.9,
        size.width * 0.85, size.height * 0.2,
      );

    // Measure path for animation
    final pathMetrics = path.computeMetrics().first;
    final animPath = pathMetrics.extractPath(0, pathMetrics.length * pathProgress);

    canvas.drawPath(
      animPath,
      Paint()
        ..color = teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Start dot
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.7), 6, Paint()..color = teal);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.7), 3, Paint()..color = Colors.white);
    // End dot
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 8, Paint()..color = Colors.orange);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.pathProgress != pathProgress;
}

// ══════════════════════════════════════════════════════
//  SHARED: STATUS BADGE
// ══════════════════════════════════════════════════════
Widget _statusBadge(String label, Color teal, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: _chipBg(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: teal)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(
          color: teal, fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

// ══════════════════════════════════════════════════════
//  SHARED: GLOWING NAV ICON (rotating)
// ══════════════════════════════════════════════════════
class _RotatingNavIcon extends StatefulWidget {
  final Color teal;
  final bool continuous; // true = linear 360, false = rock back/forth
  const _RotatingNavIcon({required this.teal, this.continuous = false});
  @override
  State<_RotatingNavIcon> createState() => _RotatingNavIconState();
}

class _RotatingNavIconState extends State<_RotatingNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    if (widget.continuous) {
      _ctrl = AnimationController(
          vsync: this, duration: const Duration(seconds: 20))
        ..repeat();
      _anim = Tween<double>(begin: 0, end: 2 * pi).animate(_ctrl);
    } else {
      _ctrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 3000))
        ..repeat(reverse: true);
      _anim = Tween<double>(begin: -0.18, end: 0.18)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Transform.rotate(angle: _anim.value, child: child),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: widget.teal.withOpacity(0.4),
              blurRadius: 20, spreadRadius: 2)],
        ),
        child: CircleAvatar(
          radius: 26, backgroundColor: widget.teal,
          child: const Icon(Icons.near_me_outlined, color: Colors.white, size: 28)),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════
//  1. PICKUP SCREEN — Heading to Pickup
// ══════════════════════════════════════════════════════
class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key});
  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen>
    with TickerProviderStateMixin {

  // Entrance stagger
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  // Route path draw
  late AnimationController _pathCtrl;
  late Animation<double> _pathAnim;

  // Destination pulse (boxShadow)
  late AnimationController _destPulseCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _items = List.generate(7, (i) {
      final s = (i * 0.08).clamp(0.0, 0.7);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    // Route path: 0 → 1 in 1.5s
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _pathAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _pathCtrl, curve: Curves.easeInOut));

    // Destination pulse
    _destPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pathCtrl.dispose();
    _destPulseCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) {
    return AnimatedBuilder(
      animation: _items[i],
      builder: (_, __) => Opacity(
        opacity: _items[i].value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - _items[i].value)),
            child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? _kTeal : const Color(0xFF1ABC9C);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header
            _anim(0, Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusBadge('EN ROUTE', teal, isDark),
                _RotatingNavIcon(teal: teal, continuous: false),
              ],
            )),
            const SizedBox(height: 10),
            _anim(1, Text('Heading to Pickup', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _text(isDark)))),
            const SizedBox(height: 4),
            _anim(1, Text('Navigate to the pickup location',
                style: TextStyle(color: _muted(isDark), fontSize: 14))),
            const SizedBox(height: 15),

            // Distance & ETA chip
            _anim(2, Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF162A38) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark ? [] : [BoxShadow(
                    color: Colors.black.withOpacity(0.03), blurRadius: 10)],
              ),
              child: Row(children: [
                Icon(Icons.location_on_outlined, color: teal, size: 16),
                const SizedBox(width: 5),
                Text('8.5 km away', style: TextStyle(
                    color: _text(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 12),
                Container(width: 1, height: 14,
                    color: isDark ? Colors.white24 : Colors.grey.shade200),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, color: Colors.orange, size: 16),
                const SizedBox(width: 5),
                Text('12 min ETA', style: TextStyle(
                    color: _text(isDark), fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            )),
            const SizedBox(height: 20),

            // Map with animated path
            _anim(3, _buildMap(teal, isDark)),
            const SizedBox(height: 20),

            // Details card
            _anim(4, _buildPickupDetailsCard(teal, isDark)),
            const SizedBox(height: 15),

            // Summary card
            _anim(5, _buildSummaryCard(teal, isDark)),
            const SizedBox(height: 30),

            // Button
            _anim(6, _GradBtn(
              label: "I've Arrived",
              icon: Icons.location_on,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ArrivedAtPickupScreen())),
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildMap(Color teal, bool isDark) {
    return Column(children: [
      Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A161F) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: isDark ? null : Border.all(color: Colors.grey.shade100),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AnimatedBuilder(
            animation: _pathAnim,
            builder: (_, __) => CustomPaint(
              painter: _MapPainter(teal, isDark: isDark, pathProgress: _pathAnim.value),
            ),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: teal,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(children: [
              Icon(Icons.access_time_filled, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Estimated Arrival',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: const [
              Text('12 min', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('8.5 km away',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ],
        ),
      ),
    ]);
  }

  Widget _buildPickupDetailsCard(Color teal, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border(isDark)),
        boxShadow: isDark ? [] : [BoxShadow(
            color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            radius: 22, backgroundColor: Colors.orange.withOpacity(0.1),
            child: const Icon(Icons.location_on, color: Colors.orange, size: 20)),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pickup Location',
                style: TextStyle(color: _muted(isDark), fontSize: 11)),
            Text('Cairo Distribution Hub',
                style: TextStyle(color: _text(isDark), fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text('124 Nasr Road, Cairo',
                style: TextStyle(color: _muted(isDark), fontSize: 12)),
          ]),
        ]),
        Divider(height: 28, color: _border(isDark)),
        Row(children: [
          // Pulsing location icon
          AnimatedBuilder(
            animation: _destPulseCtrl,
            builder: (_, child) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: teal.withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: teal.withOpacity(0.3 * _destPulseCtrl.value),
                  blurRadius: 16,
                  spreadRadius: 4,
                )],
              ),
              child: child,
            ),
            child: Icon(Icons.person, color: teal),
          ),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trader Contact',
                style: TextStyle(color: _muted(isDark), fontSize: 12)),
            Text('Mohamed Hassan', style: TextStyle(
                color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle, color: teal,
              boxShadow: [BoxShadow(
                  color: teal.withOpacity(0.4), blurRadius: 15)]),
            child: const Icon(Icons.phone_in_talk_rounded,
                color: Colors.white, size: 20)),
        ]),
      ]),
    );
  }

  Widget _buildSummaryCard(Color teal, bool isDark) {
    final items = {
      'ID': 'SHP-4522',
      'Type': 'Construction Materials',
      'Weight': '3,200 lbs',
      'Destination': 'Alexandria Port Terminal',
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border(isDark)),
        boxShadow: isDark ? [] : [BoxShadow(
            color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(children: [
        Row(children: [
          Icon(Icons.local_shipping_outlined, color: teal, size: 20),
          const SizedBox(width: 10),
          Text('Shipment Summary', style: TextStyle(
              color: _text(isDark), fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 15),
        ...items.entries.map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(e.key, style: TextStyle(color: _muted(isDark))),
            Text(e.value, style: TextStyle(
                color: _text(isDark), fontWeight: FontWeight.w600)),
          ]),
        )),
      ]),
    );
  }
}


// ══════════════════════════════════════════════════════
//  2. ARRIVED AT PICKUP SCREEN
// ══════════════════════════════════════════════════════
class ArrivedAtPickupScreen extends StatefulWidget {
  const ArrivedAtPickupScreen({super.key});
  @override
  State<ArrivedAtPickupScreen> createState() => _ArrivedAtPickupScreenState();
}

class _ArrivedAtPickupScreenState extends State<ArrivedAtPickupScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  // Icon spring
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;

  // Location card boxShadow pulse
  late AnimationController _shadowPulseCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();
    _items = List.generate(8, (i) {
      final s = (0.1 + i * 0.08).clamp(0.0, 0.8);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    // Icon spring: scale 0 → 1
    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _iconAnim = CurvedAnimation(parent: _iconCtrl,
        curve: Curves.elasticOut);

    // Shadow pulse
    _shadowPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _shadowPulseCtrl.dispose();
    super.dispose();
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i],
    builder: (_, __) => Opacity(
      opacity: _items[i].value,
      child: Transform.translate(
          offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF00E676) : const Color(0xFF22D3C5);
    final amber  = isDark ? _kAmber : const Color(0xFFFFB84D);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const SizedBox(height: 10),

                // Success icon with pulsing rings
                _a(0, AnimatedBuilder(
                  animation: _iconAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _iconAnim.value, child: child),
                  child: _PulsingRings(
                    color: teal, size: 80, ringCount: 2,
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: teal),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                )),
                const SizedBox(height: 20),

                // Status badge
                _a(1, Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _chipBg(isDark), borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, color: teal, size: 8),
                    const SizedBox(width: 8),
                    Text('AT PICKUP LOCATION', style: TextStyle(
                        color: teal, fontSize: 12, fontWeight: FontWeight.bold,
                        letterSpacing: 1.0)),
                  ]),
                )),
                const SizedBox(height: 25),

                _a(2, Text("You've Arrived!", style: TextStyle(
                    color: _text(isDark), fontSize: 28, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                _a(2, Text('Meet with the trader to collect the shipment',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted(isDark), fontSize: 14))),
                const SizedBox(height: 25),

                // Confirmation note
                _a(3, Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132A25) : const Color(0xFFE9FFFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teal.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    Icon(Icons.check_circle_outline_rounded, color: teal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      'Confirm you have arrived at the pickup location',
                      style: TextStyle(color: teal, fontSize: 14))),
                  ]),
                )),
                const SizedBox(height: 15),

                // Location card with shadow pulse
                _a(4, AnimatedBuilder(
                  animation: _shadowPulseCtrl,
                  builder: (_, child) => Container(
                    width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border(isDark)),
                      boxShadow: [BoxShadow(
                        color: teal.withOpacity(
                            0.3 * (0.5 + 0.5 * sin(_shadowPulseCtrl.value * 2 * pi))),
                        blurRadius: 16, spreadRadius: 2,
                      )],
                    ),
                    child: child,
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F323E) : const Color(0xFFE9FFFB),
                        shape: BoxShape.circle),
                      child: Icon(Icons.location_on_outlined, color: teal, size: 22)),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Current Location',
                          style: TextStyle(color: _muted(isDark), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Cairo Distribution Hub', style: TextStyle(
                          color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('124 Nasr Road, Cairo',
                          style: TextStyle(color: _muted(isDark), fontSize: 13)),
                    ]),
                  ]),
                )),
                const SizedBox(height: 15),

                // Contact card
                _a(5, Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border(isDark)),
                    boxShadow: isDark ? [] : [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFFFF6E5),
                        shape: BoxShape.circle),
                      child: Icon(Icons.person_outline_rounded, color: amber, size: 22)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contact Person',
                            style: TextStyle(color: _muted(isDark), fontSize: 12)),
                        Text('Mohamed Hassan', style: TextStyle(
                            color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('+20 100 123 4567',
                            style: TextStyle(color: _muted(isDark), fontSize: 13)),
                      ],
                    )),
                    Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: teal,
                        boxShadow: [BoxShadow(
                            color: teal.withOpacity(0.4), blurRadius: 15)]),
                      child: const Icon(Icons.phone_in_talk_rounded,
                          color: Colors.white, size: 20)),
                  ]),
                )),
                const SizedBox(height: 20),

                // Shipment details
                _a(6, Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _card(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border(isDark)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.inventory_2_outlined, color: teal, size: 20),
                      const SizedBox(width: 10),
                      Text('Shipment to Collect', style: TextStyle(
                          color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 15),
                    Divider(color: _border(isDark).withOpacity(0.5)),
                    const SizedBox(height: 10),
                    ...[
                      ['Shipment ID', 'SHP-4522'],
                      ['Type', 'Construction Materials'],
                      ['Weight', '3,200 lbs'],
                      ['Items', '12 pallets'],
                    ].map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(r[0], style: TextStyle(color: _muted(isDark), fontSize: 14)),
                        Text(r[1], style: TextStyle(
                            color: _text(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
                      ]),
                    )),
                  ]),
                )),
                const SizedBox(height: 15),

                // Special instructions
                _a(7, Container(
                  width: double.infinity, padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF21251A) : const Color(0xFFFFFAED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: amber.withOpacity(0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.local_shipping_outlined, color: amber, size: 18),
                      const SizedBox(width: 8),
                      Text('SPECIAL INSTRUCTIONS', style: TextStyle(
                          color: amber, fontSize: 12, fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                    ]),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 26),
                      child: Text('Handle with care - Fragile items', style: TextStyle(
                          color: _text(isDark), fontSize: 14)),
                    ),
                  ]),
                )),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: _bg(isDark),
            child: _GradBtn(
              label: 'Confirm Pickup',
              icon: Icons.check_circle_outline_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const PickupConfirmationScreen())),
            ),
          ),
        ]),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════
//  3. PICKUP CONFIRMATION SCREEN — Pickup Confirmed
// ══════════════════════════════════════════════════════
class PickupConfirmationScreen extends StatefulWidget {
  const PickupConfirmationScreen({super.key});
  @override
  State<PickupConfirmationScreen> createState() => _PickupConfirmationScreenState();
}

class _PickupConfirmationScreenState extends State<PickupConfirmationScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  // Icon spring
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;

  // Route line scaleY 0 → 1
  late AnimationController _routeLineCtrl;
  late Animation<double> _routeLineAnim;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
    _items = List.generate(8, (i) {
      final s = (i * 0.1).clamp(0.0, 0.8);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _iconAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);

    _routeLineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward(from: 0);
    _routeLineAnim = CurvedAnimation(parent: _routeLineCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _routeLineCtrl.dispose();
    super.dispose();
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i],
    builder: (_, __) => Opacity(
      opacity: _items[i].value,
      child: Transform.translate(
          offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF00E676) : const Color(0xFF22D3C5);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const SizedBox(height: 30),

                // Icon with 3 pulsing rings
                _a(0, AnimatedBuilder(
                  animation: _iconAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _iconAnim.value, child: child),
                  child: _PulsingRings(
                    color: teal, size: 90, ringCount: 3,
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          isDark ? const Color(0xFF69F0AE) : const Color(0xFF38E7D2),
                          teal,
                        ]),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 38),
                    ),
                  ),
                )),
                const SizedBox(height: 30),

                _a(1, Text('Pickup Confirmed!', style: TextStyle(
                    color: _text(isDark), fontSize: 26, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                _a(1, Text('Shipment has been loaded successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted(isDark), fontSize: 14))),
                const SizedBox(height: 20),

                // Badge
                _a(2, Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: _chipBg(isDark), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: teal.withOpacity(0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, color: teal, size: 8),
                    const SizedBox(width: 8),
                    Text('Ready for Delivery', style: TextStyle(
                        color: teal, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                )),
                const SizedBox(height: 30),

                // Delivery route card with animated route line
                _a(3, Container(
                  width: double.infinity, padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card(isDark), borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border(isDark)),
                    boxShadow: isDark ? [] : [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.near_me_outlined, color: teal, size: 18),
                      const SizedBox(width: 10),
                      Text('Delivery Route', style: TextStyle(
                          color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(children: [
                        // From
                        Row(children: [
                          Icon(Icons.circle, color: teal, size: 12),
                          const SizedBox(width: 15),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From (Picked up)', style: TextStyle(
                                  color: _muted(isDark), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Cairo Distribution Hub', style: TextStyle(
                                  color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          )),
                        ]),
                        // Animated route line (scaleY 0→1)
                        AnimatedBuilder(
                          animation: _routeLineAnim,
                          builder: (_, __) => Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(left: 5),
                              width: 3,
                              height: 50 * _routeLineAnim.value,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [teal, const Color(0xFFFFB84D)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // To
                        Row(children: [
                          Container(width: 12, height: 12,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle, color: Color(0xFFFFB84D))),
                          const SizedBox(width: 15),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To (Destination)', style: TextStyle(
                                  color: _muted(isDark), fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Alexandria Port Terminal', style: TextStyle(
                                  color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('45 Port Road, Alexandria', style: TextStyle(
                                  color: _muted(isDark), fontSize: 13)),
                            ],
                          )),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 25),
                    Row(children: [
                      _infoBox(Icons.location_on_outlined, 'Distance', '120 km', teal, isDark),
                      const SizedBox(width: 15),
                      _infoBox(Icons.access_time, 'Est. Time', '2 hr 30 min', teal, isDark),
                    ]),
                  ]),
                )),
                const SizedBox(height: 20),

                // Shipment details
                _a(4, Container(
                  width: double.infinity, padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card(isDark), borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border(isDark)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Icon(Icons.inventory_2_outlined, color: teal, size: 18),
                      const SizedBox(width: 10),
                      Text('Shipment Loaded', style: TextStyle(
                          color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 25),
                    Row(children: [
                      _shipmentBox(Icons.scale_outlined, 'Weight', '3,200 lbs', teal, isDark),
                      const SizedBox(width: 15),
                      _shipmentBox(Icons.inventory_2_outlined, 'Package', 'Materials', teal, isDark),
                    ]),
                    const SizedBox(height: 25),
                    ...[
                      ['Shipment ID', 'SHP-4522'],
                      ['Type', 'Construction Materials'],
                    ].map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(r[0], style: TextStyle(color: _muted(isDark), fontSize: 14)),
                        Text(r[1], style: TextStyle(
                            color: _text(isDark), fontSize: 14, fontWeight: FontWeight.w500)),
                      ]),
                    )),
                  ]),
                )),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: _bg(isDark),
            child: _GradBtn(
              label: 'Start Delivery',
              icon: Icons.play_arrow_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const InTransitScreen())),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, Color teal, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF8FEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: isDark ? _muted(isDark) : teal, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: _muted(isDark), fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              color: _text(isDark), fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ));

  Widget _shipmentBox(IconData icon, String label, String value, Color teal, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF8FEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: teal, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: _muted(isDark), fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
              color: _text(isDark), fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ));
}


// ══════════════════════════════════════════════════════
//  4. IN TRANSIT SCREEN — On the Way
// ══════════════════════════════════════════════════════
class InTransitScreen extends StatefulWidget {
  const InTransitScreen({super.key});
  @override
  State<InTransitScreen> createState() => _InTransitScreenState();
}

class _InTransitScreenState extends State<InTransitScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  // Rotating nav icon (linear 20s)
  late AnimationController _rotateCtrl;

  // Progress bar
  late AnimationController _progressCtrl;
  late Animation<double> _progressAnim;

  // Shimmer on progress bar
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // Path draw
  late AnimationController _pathCtrl;
  late Animation<double> _pathAnim;

  // Moving truck on path
  late AnimationController _truckCtrl;

  // Destination pulse
  late AnimationController _destPulseCtrl;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _items = List.generate(7, (i) {
      final s = (i * 0.09).clamp(0.0, 0.8);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    // Nav icon: linear 360 in 20s
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 20))
      ..repeat();

    // Progress bar: 0 → 62%
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _progressAnim = Tween<double>(begin: 0, end: 0.62)
        .animate(CurvedAnimation(parent: _progressCtrl,
            curve: const Cubic(0.22, 1, 0.36, 1)));

    // Shimmer
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    // Path draw
    _pathCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _pathAnim = Tween<double>(begin: 0, end: 0.62)
        .animate(CurvedAnimation(parent: _pathCtrl, curve: Curves.easeInOut));

    // Truck bounce
    _truckCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);

    // Destination pulse
    _destPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _rotateCtrl.dispose();
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
    _pathCtrl.dispose();
    _truckCtrl.dispose();
    _destPulseCtrl.dispose();
    super.dispose();
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i],
    builder: (_, __) => Opacity(
      opacity: _items[i].value,
      child: Transform.translate(
          offset: Offset(0, 20 * (1 - _items[i].value)), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF19D2B1) : const Color(0xFF22D3C5);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header
            _a(0, Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _statusBadge('IN TRANSIT', teal, isDark),
              // Rotating nav icon (linear)
              AnimatedBuilder(
                animation: _rotateCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _rotateCtrl.value * 2 * pi, child: child),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: teal.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)]),
                  child: CircleAvatar(
                    radius: 26, backgroundColor: teal,
                    child: const Icon(Icons.near_me_outlined, color: Colors.white, size: 28)),
                ),
              ),
            ])),
            const SizedBox(height: 15),
            _a(1, Text('On the Way', style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: _text(isDark)))),
            _a(1, Text('Navigate to the destination',
                style: TextStyle(color: _muted(isDark), fontSize: 14))),
            const SizedBox(height: 20),

            // Map with animated path + progress
            _a(2, _buildMap(teal, isDark)),
            const SizedBox(height: 20),

            // Destination card with pulsing shadow
            _a(3, AnimatedBuilder(
              animation: _destPulseCtrl,
              builder: (_, child) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card(isDark),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _border(isDark)),
                  boxShadow: [BoxShadow(
                    color: Colors.orange.withOpacity(
                        0.3 * (0.5 + 0.5 * sin(_destPulseCtrl.value * 2 * pi))),
                    blurRadius: 16, spreadRadius: 2,
                  )],
                ),
                child: child,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A2A33) : const Color(0xFFFFF6E5),
                    shape: BoxShape.circle),
                  child: Icon(Icons.location_on,
                      color: isDark ? Colors.orangeAccent : const Color(0xFFFFB84D),
                      size: 24)),
                const SizedBox(width: 15),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Destination',
                      style: TextStyle(color: _muted(isDark), fontSize: 12)),
                  Text('Alexandria Port Terminal', style: TextStyle(
                      color: _text(isDark), fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('45 Port Road, Alexandria',
                      style: TextStyle(color: _muted(isDark), fontSize: 13)),
                ]),
              ]),
            )),
            const SizedBox(height: 20),

            // Shipment card
            _a(4, Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card(isDark), borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _border(isDark)),
              ),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.inventory_2_outlined, color: teal, size: 20),
                  const SizedBox(width: 10),
                  Text('Active Shipment', style: TextStyle(
                      color: _text(isDark), fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 15),
                ...[
                  ['ID', 'SHP-4522'],
                  ['Type', 'Construction Materials'],
                  ['Weight', '3,200 lbs'],
                ].map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(r[0], style: TextStyle(color: _muted(isDark))),
                    Text(r[1], style: TextStyle(
                        color: _text(isDark), fontWeight: FontWeight.w500)),
                  ]),
                )),
              ]),
            )),
            const SizedBox(height: 30),

            // Mark as Delivered button
            _a(5, _GradBtn(
              label: 'Mark as Delivered',
              icon: Icons.check_circle_outline,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const DeliverySuccessScreen())),
            )),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildMap(Color teal, bool isDark) {
    return Column(children: [
      Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A161F) : const Color(0xFFF8FEFD),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: isDark ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AnimatedBuilder(
            animation: _pathAnim,
            builder: (_, __) => CustomPaint(
              painter: _MapPainter(teal, isDark: isDark, pathProgress: _pathAnim.value)),
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: teal,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
        child: Column(children: [
          // Progress bar row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Trip Progress',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            AnimatedBuilder(
              animation: _progressAnim,
              builder: (_, __) => Text(
                '${(_progressAnim.value * 100).round()}%',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 8),
          // Animated progress with shimmer
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(
                height: 4,
                color: Colors.white.withOpacity(0.2),
              ),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: _progressAnim.value,
                  child: Stack(children: [
                    Container(height: 4, color: Colors.white),
                    // Shimmer
                    AnimatedBuilder(
                      animation: _shimmerAnim,
                      builder: (_, __) => Transform.translate(
                        offset: Offset(_shimmerAnim.value * 100, 0),
                        child: Container(
                          height: 4, width: 30,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.white54, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Row(children: [
              Icon(Icons.access_time_filled, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text('Estimated Arrival', style: TextStyle(color: Colors.white, fontSize: 16)),
            ]),
            const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('1 hr 15 min', style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('45 km remaining', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ]),
        ]),
      ),
    ]);
  }
}


// ══════════════════════════════════════════════════════
//  5. DELIVERY SUCCESS SCREEN
// ══════════════════════════════════════════════════════
class DeliverySuccessScreen extends StatefulWidget {
  const DeliverySuccessScreen({super.key});
  @override
  State<DeliverySuccessScreen> createState() => _DeliverySuccessScreenState();
}

class _DeliverySuccessScreenState extends State<DeliverySuccessScreen>
    with TickerProviderStateMixin {

  // Main entrance
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  // Icon spring
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;

  // Confetti
  late AnimationController _confettiCtrl;
  final List<_ConfettiParticle> _particles = [];

  // Earnings counter
  late AnimationController _earningsCtrl;
  late Animation<double> _earningsAnim;

  // Star stagger
  late AnimationController _starsCtrl;
  late List<Animation<double>> _starAnims;

  // Earnings card glow
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    // Generate 12 confetti particles
    final rng = Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(_ConfettiParticle(
        color: [const Color(0xFF34C759), const Color(0xFF00D5BE),
            const Color(0xFFF59E0B), const Color(0xFFFBBF24)][i % 4],
        x: 0.2 + i * 0.05,
        delay: i * 0.1,
        drift: i % 2 == 0 ? 1.0 : -1.0,
      ));
    }

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward();
    _items = List.generate(10, (i) {
      final s = (i * 0.09).clamp(0.0, 0.85);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    // Icon spring
    _iconCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700))
      ..forward();
    _iconAnim = CurvedAnimation(parent: _iconCtrl,
        curve: Curves.elasticOut);

    // Confetti: play once
    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..forward();

    // Earnings counter: 0 → 240
    _earningsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _earningsAnim = CurvedAnimation(parent: _earningsCtrl,
        curve: Curves.easeOutCubic);

    // Stars stagger (5 stars, 0.1s apart)
    _starsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _starAnims = List.generate(5, (i) {
      final start = 0.2 + i * 0.12;
      final end   = (start + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(
          parent: _starsCtrl,
          curve: Interval(start.clamp(0.0, 1.0), end, curve: Curves.easeOutBack));
    });

    // Earnings card glow
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _confettiCtrl.dispose();
    _earningsCtrl.dispose();
    _starsCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Widget _a(int i, Widget child) => AnimatedBuilder(
    animation: _items[i.clamp(0, _items.length - 1)],
    builder: (_, __) {
      final v = _items[i.clamp(0, _items.length - 1)].value;
      return Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final teal   = isDark ? const Color(0xFF1ABC9C) : const Color(0xFF22D3C5);
    final amber  = isDark ? _kAmber : const Color(0xFFFFB84D);

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Stack(children: [
            // Confetti particles
            ...List.generate(_particles.length, (i) {
              final p = _particles[i];
              return AnimatedBuilder(
                animation: _confettiCtrl,
                builder: (_, __) {
                  final t = ((_confettiCtrl.value - p.delay).clamp(0.0, 1.0));
                  if (t == 0) return const SizedBox.shrink();
                  return Positioned(
                    left: MediaQuery.of(context).size.width * p.x,
                    top: -120 * t + 30,
                    child: Opacity(
                      opacity: (1 - t).clamp(0, 1),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..translate(p.drift * 40 * t, 0)
                          ..rotateZ(t * 2 * pi),
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: p.color),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            Column(children: [
              const SizedBox(height: 30),

              // Icon with 3 pulsing rings
              _a(0, AnimatedBuilder(
                animation: _iconAnim,
                builder: (_, child) => Transform.scale(
                  scale: _iconAnim.value, child: child),
                child: _PulsingRings(
                  color: teal, size: 100, ringCount: 3,
                  child: Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: teal,
                        boxShadow: [BoxShadow(
                            color: teal.withOpacity(0.5),
                            blurRadius: 24, spreadRadius: 4)]),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                  ),
                ),
              )),
              const SizedBox(height: 30),

              _a(1, Text('Delivered Successfully!', style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: _text(isDark)))),
              const SizedBox(height: 8),
              _a(1, Text('Great work completing this delivery',
                  style: TextStyle(color: _muted(isDark), fontSize: 14))),
              const SizedBox(height: 30),

              // Earnings card with glow
              _a(2, AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, child) => Container(
                  width: double.infinity, padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _card(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: amber, width: 2),
                    boxShadow: [BoxShadow(
                      color: amber.withOpacity(0.15 + 0.1 * _glowCtrl.value),
                      blurRadius: 24, spreadRadius: 4,
                    )],
                  ),
                  child: child,
                ),
                child: Column(children: [
                  Text('Trip Earnings', style: TextStyle(color: _muted(isDark), fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('\$', style: TextStyle(color: amber, fontSize: 24)),
                    const SizedBox(width: 5),
                    // Animated counter
                    AnimatedBuilder(
                      animation: _earningsAnim,
                      builder: (_, __) => Text(
                        (240 * _earningsAnim.value).toInt().toString(),
                        style: TextStyle(fontSize: 48,
                            fontWeight: FontWeight.bold, color: _text(isDark)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('EGP', style: TextStyle(color: _muted(isDark), fontSize: 16)),
                  ]),
                  const SizedBox(height: 15),
                  Divider(color: _border(isDark).withOpacity(0.5)),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.trending_up, color: teal, size: 16),
                    const SizedBox(width: 8),
                    Text("Today's total: ", style: TextStyle(color: _muted(isDark), fontSize: 12)),
                    Text('1,150 EGP', style: TextStyle(
                        color: _text(isDark), fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              )),
              const SizedBox(height: 20),

              // Trip summary
              _a(3, Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card(isDark), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(isDark)),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.location_on_outlined, color: teal, size: 20),
                    const SizedBox(width: 10),
                    Text('Trip Summary', style: TextStyle(
                        color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(width: 12, height: 12,
                        decoration: BoxDecoration(color: teal, shape: BoxShape.circle)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('From', style: TextStyle(color: _muted(isDark), fontSize: 11)),
                      Text('Cairo Distribution Hub',
                          style: TextStyle(color: _text(isDark), fontSize: 15)),
                    ])),
                  ]),
                  Container(margin: const EdgeInsets.only(left: 5.5),
                      height: 25, width: 1, color: _border(isDark)),
                  Row(children: [
                    Container(width: 12, height: 12,
                        decoration: BoxDecoration(color: amber, shape: BoxShape.circle)),
                    const SizedBox(width: 15),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('To', style: TextStyle(color: _muted(isDark), fontSize: 11)),
                      Text('Alexandria Port Terminal',
                          style: TextStyle(color: _text(isDark), fontSize: 15)),
                    ])),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    _statBox('Distance', '120 km', isDark),
                    const SizedBox(width: 15),
                    _statBox('Duration', '2 hr 28 min', isDark),
                  ]),
                ]),
              )),
              const SizedBox(height: 20),

              // Rating
              _a(4, Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card(isDark), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(isDark)),
                ),
                child: Column(children: [
                  Text('How was your delivery experience?',
                      style: TextStyle(color: _muted(isDark), fontSize: 13)),
                  const SizedBox(height: 15),
                  // Staggered stars
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => AnimatedBuilder(
                      animation: _starAnims[i],
                      builder: (_, __) => Transform.scale(
                        scale: _starAnims[i].value,
                        child: Icon(Icons.star, color: amber, size: 30),
                      ),
                    )),
                  ),
                ]),
              )),
              const SizedBox(height: 30),

              // Complete button
              _a(5, _GradBtn(
                label: 'Complete Trip',
                icon: Icons.check_circle_outline_rounded,
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
              )),
              const SizedBox(height: 20),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, bool isDark) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2A37) : const Color(0xFFF8FEFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border(isDark))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: _muted(isDark), fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
              color: _text(isDark), fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ));
}

// ══════════════════════════════════════════════════════
//  CONFETTI PARTICLE DATA
// ══════════════════════════════════════════════════════
class _ConfettiParticle {
  final Color color;
  final double x;      // 0.0 - 1.0 horizontal position
  final double delay;  // 0.0 - 1.0 start delay
  final double drift;  // -1 or 1 horizontal drift direction

  const _ConfettiParticle({
    required this.color,
    required this.x,
    required this.delay,
    required this.drift,
  });
}
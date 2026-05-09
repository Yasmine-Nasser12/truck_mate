import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  DRIVER STATE SCREENS — ANIMATIONS مطابقة لـ React Native
//  lib/screen/driver/driver_state_screens.dart
//
//  الـ animations المنقولة بالضبط من RN:
//  • Empty  → spring scale-in (stiffness≈200) + floating bg blobs +
//             radio pulse rings (1→1.6 & 1→1.3, easeOut 2s ∞) +
//             icon bounce+rotate loop (3s ∞) + shimmer sweep on btn +
//             RefreshCw spin 360° loop
//  • Error  → spring scale-in + red pulse rings (→1.4, opacity→0, 2s) +
//             AlertCircle shake on mount (−10°,+10°,−10°,0 at 0.5s delay) +
//             WifiOff badge spring pop + red dot pulse + shimmer sweep
//  • Loading→ cards slide-up with stagger (delay +100ms each) +
//             shimmer sweep per card + 3 dots stagger pulse +
//             "Loading…" text opacity loop
// ══════════════════════════════════════════════════════════════════

// ─── Colors ──────────────────────────────────────────────────────
const Color _kTeal  = Color(0xFF00D5BE);
const Color _kTeal2 = Color(0xFF00BBA7);
const Color _kRed   = Color(0xFFD32F2F);
const Color _kAmber = Color(0xFFF59E0B);
const Color _kBg    = Color(0xFF0F2334);
const Color _kCard  = Color(0xFF0A1628);

const LinearGradient _kGrad = LinearGradient(
  colors: [_kTeal, _kTeal2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ─── Gradient Button with shimmer sweep ──────────────────────────
class _GradButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _GradButton(
      {required this.label, required this.icon, required this.onTap});

  @override
  State<_GradButton> createState() => _GradButtonState();
}

class _GradButtonState extends State<_GradButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerX;

  @override
  void initState() {
    super.initState();
    // shimmer: x sweep −300 → 300 in 2s linear ∞  (same as RN animate: x:[-300,300])
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          gradient: _kGrad,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: _kTeal.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(alignment: Alignment.center, children: [
          // shimmer sweep
          AnimatedBuilder(
            animation: _shimmerX,
            builder: (_, __) => Transform.translate(
              offset: Offset(_shimmerX.value, 0),
              child: Container(
                width: 120,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.white.withOpacity(0),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0),
                  ]),
                ),
              ),
            ),
          ),
          // label + icon
          Row(mainAxisSize: MainAxisSize.min, children: [
            _SpinningIcon(icon: widget.icon),
            const SizedBox(width: 8),
            Text(widget.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ]),
        ]),
      ),
    );
  }
}

// Spinning icon (360° loop) — RefreshCw in RN
class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  const _SpinningIcon({required this.icon});
  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    // RN: duration:2000, repeat:Infinity, ease:"linear"
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
        turns: _ctrl,
        child: Icon(widget.icon, color: Colors.white, size: 20),
      );
}

// ══════════════════════════════════════════════════════════════════
//  FLOATING BACKGROUND BLOBS
// ══════════════════════════════════════════════════════════════════
class _FloatingBlob extends StatefulWidget {
  final Color color;
  final double size;
  final Alignment alignment;
  final Offset animateOffset; // how far it drifts
  final Duration duration;
  final Duration delay;

  const _FloatingBlob({
    required this.color,
    required this.size,
    required this.alignment,
    required this.animateOffset,
    required this.duration,
    this.delay = Duration.zero,
  });

  @override
  State<_FloatingBlob> createState() => _FloatingBlobState();
}

class _FloatingBlobState extends State<_FloatingBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _offset = Tween<Offset>(begin: Offset.zero, end: widget.animateOffset)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: AnimatedBuilder(
        animation: _offset,
        builder: (_, child) => Transform.translate(
          offset: Offset(
              _offset.value.dx * widget.size,
              _offset.value.dy * widget.size),
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.05),
          ),
          // Blur simulated with large boxShadow spread
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.05),
                  blurRadius: 80,
                  spreadRadius: 40)
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  RADIO PULSE RINGS  (Empty screen icon)
//  RN: outer scale 1→1.6 opacity 0.4→0 duration:2s ∞
//      inner scale 1→1.3 opacity 0.3→0 delay:0.4s
// ══════════════════════════════════════════════════════════════════
class _PulseRing extends StatefulWidget {
  final double size;
  final Color color;
  final double targetScale;
  final Duration delay;
  final Duration duration;

  const _PulseRing({
    required this.size,
    required this.color,
    required this.targetScale,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _scale = Tween<double>(begin: 1.0, end: widget.targetScale).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BOUNCING + ROTATING ICON  (Empty screen)
//  RN: scale [1,1.1,1] rotate [0,5,-5,0] duration:3s ∞
// ══════════════════════════════════════════════════════════════════
class _BouncingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _BouncingIcon({required this.icon, required this.color});

  @override
  State<_BouncingIcon> createState() => _BouncingIconState();
}

class _BouncingIconState extends State<_BouncingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: false);

    // scale: 1 → 1.1 → 1  (mirror in half cycle)
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // rotate: 0 → 5° → -5° → 0
    _rotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: Transform.rotate(
          angle: _rotate.value * 3.14159 / 180,
          child: child,
        ),
      ),
      child: Icon(widget.icon, color: widget.color, size: 40),
    );
  }
}

// Badge spring pop (WifiOff / Radio)
class _BadgePop extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _BadgePop({required this.child, this.delay = Duration.zero});

  @override
  State<_BadgePop> createState() => _BadgePopState();
}

class _BadgePopState extends State<_BadgePop>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // RN: initial:{scale:0} animate:{scale:1} spring stiffness:200
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

// ══════════════════════════════════════════════════════════════════
//  SHAKE ANIMATION  (Error icon AlertCircle)
//  RN: rotate [0,-10,10,-10,0] at delay:0.5s, duration:0.5s once
// ══════════════════════════════════════════════════════════════════
class _ShakeIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _ShakeIcon({required this.icon, required this.color});

  @override
  State<_ShakeIcon> createState() => _ShakeIconState();
}

class _ShakeIconState extends State<_ShakeIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _rotate = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // delay 0.5s then run once
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotate,
      builder: (_, child) => Transform.rotate(
        angle: _rotate.value * 3.14159 / 180,
        child: child,
      ),
      child: Icon(widget.icon, color: widget.color, size: 48),
    );
  }
}

// Red / green pulsing dot
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // RN: opacity [1,0.4,1] scale [1,1.2,1] duration:1500 ∞
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _scale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  ENTRY ANIMATION WRAPPER  (spring scale+fade — stiffness≈200)
//  Matches RN: initial:{opacity:0,scale:0.9} animate:{opacity:1,scale:1}
//              type:"spring" stiffness:200  +  staggered children
// ══════════════════════════════════════════════════════════════════
class _SpringEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset slideFrom; // for slide-up children

  const _SpringEntry({
    required this.child,
    this.delay = Duration.zero,
    this.slideFrom = Offset.zero,
  });

  @override
  State<_SpringEntry> createState() => _SpringEntryState();
}

class _SpringEntryState extends State<_SpringEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.slideFrom, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}

// simple fade+slide without spring (for text/card children)
class _FadeSlideEntry extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _FadeSlideEntry({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeSlideEntry> createState() => _FadeSlideEntryState();
}

class _FadeSlideEntryState extends State<_FadeSlideEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ══════════════════════════════════════════════════════════════════
//  1. REQUESTS LIST EMPTY  ← مطابق لـ RequestsListEmpty.tsx
// ══════════════════════════════════════════════════════════════════
class DriverRequestsListEmptyScreen extends StatelessWidget {
  final VoidCallback? onRefresh;
  const DriverRequestsListEmptyScreen({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // ── Floating background blobs ──
        const Positioned.fill(
          child: IgnorePointer(
            child: Stack(children: [
              _FloatingBlob(
                color: _kTeal,
                size: 256,
                alignment: Alignment(0.8, -0.6),
                animateOffset: Offset(0.12, -0.08),
                duration: Duration(milliseconds: 8000),
              ),
              _FloatingBlob(
                color: _kAmber,
                size: 192,
                alignment: Alignment(-0.8, 0.7),
                animateOffset: Offset(-0.1, 0.15),
                duration: Duration(milliseconds: 10000),
                delay: Duration(milliseconds: 1000),
              ),
            ]),
          ),
        ),

        // ── Content ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Icon area: pulse rings + bouncing icon + badge
                _SpringEntry(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(alignment: Alignment.center, children: [
                      // outer ring: scale 1→1.6
                      const _PulseRing(
                          size: 96,
                          color: _kTeal,
                          targetScale: 1.6,
                          duration: Duration(milliseconds: 2000)),
                      // inner ring: scale 1→1.3 delay 0.4s
                      const _PulseRing(
                          size: 96,
                          color: _kTeal,
                          targetScale: 1.3,
                          delay: Duration(milliseconds: 400),
                          duration: Duration(milliseconds: 2000)),
                      // main circle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _kTeal.withOpacity(0.15),
                            _kTeal.withOpacity(0.08),
                          ]),
                          border: Border.all(
                              color: _kTeal.withOpacity(0.3), width: 1.5),
                        ),
                        child: const _BouncingIcon(
                            icon: Icons.inbox_outlined, color: _kTeal),
                      ),
                      // small radio badge bottom-right
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: _BadgePop(
                          delay: const Duration(milliseconds: 300),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF34C759).withOpacity(0.2),
                              border: Border.all(
                                  color: const Color(0xFF34C759), width: 2),
                            ),
                            child: const Icon(Icons.wifi_tethering,
                                color: Color(0xFF34C759), size: 14),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 300),
                  child: const Text(
                    'No Requests Available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    'Stay online to receive new shipment requests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: const Color(0xFFCBFBF1).withOpacity(0.6),
                        fontSize: 15,
                        height: 1.5),
                  ),
                ),

                const SizedBox(height: 32),

                // Info card
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCard.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _kTeal.withOpacity(0.15), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF34C759).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.wifi_tethering,
                              color: Color(0xFF34C759), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("You're Online & Ready",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                'New shipment requests will appear here automatically',
                                style: TextStyle(
                                    color: const Color(0xFFCBFBF1)
                                        .withOpacity(0.6),
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Refresh button with shimmer + spinning icon
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 600),
                  child: _GradButton(
                    label: 'Refresh',
                    icon: Icons.refresh_rounded,
                    onTap: onRefresh ?? () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  2. REQUESTS LIST ERROR  ← مطابق لـ RequestsListError.tsx
// ══════════════════════════════════════════════════════════════════
class DriverRequestsListErrorScreen extends StatelessWidget {
  final VoidCallback? onRetry;
  const DriverRequestsListErrorScreen({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // ── Floating background blobs (grey + red for error) ──
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(children: [
              _FloatingBlob(
                color: const Color(0xFF8E8E93),
                size: 256,
                alignment: const Alignment(0.8, -0.6),
                animateOffset: const Offset(0.12, -0.08),
                duration: const Duration(milliseconds: 8000),
              ),
              _FloatingBlob(
                color: _kRed,
                size: 192,
                alignment: const Alignment(-0.8, 0.7),
                animateOffset: const Offset(-0.1, 0.15),
                duration: const Duration(milliseconds: 10000),
                delay: const Duration(milliseconds: 1000),
              ),
            ]),
          ),
        ),

        // ── Content ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Icon area: red pulse rings + shake AlertCircle + WifiOff badge
                _SpringEntry(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(alignment: Alignment.center, children: [
                      // outer red ring: scale→1.4 opacity→0
                      const _PulseRing(
                          size: 96,
                          color: _kRed,
                          targetScale: 1.4,
                          duration: Duration(milliseconds: 2000)),
                      // inner red ring: delay 0.5s
                      const _PulseRing(
                          size: 96,
                          color: _kRed,
                          targetScale: 1.4,
                          delay: Duration(milliseconds: 500),
                          duration: Duration(milliseconds: 2000)),
                      // main circle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _kRed.withOpacity(0.20),
                            const Color(0xFF8E8E93).withOpacity(0.15),
                          ]),
                          border: Border.all(
                              color: _kRed.withOpacity(0.3), width: 1.5),
                        ),
                        // AlertCircle shake on mount
                        child: const _ShakeIcon(
                            icon: Icons.error_outline_rounded, color: _kRed),
                      ),
                      // WifiOff badge: spring pop at delay 0.6s
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: _BadgePop(
                          delay: const Duration(milliseconds: 600),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF8E8E93).withOpacity(0.2),
                              border: Border.all(
                                  color: const Color(0xFF8E8E93), width: 2),
                            ),
                            child: const Icon(Icons.wifi_off_rounded,
                                color: Color(0xFF8E8E93), size: 16),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 300),
                  child: const Text(
                    'Failed to Load Requests',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    'Please check your connection and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: const Color(0xFFCBFBF1).withOpacity(0.6),
                        fontSize: 15,
                        height: 1.5),
                  ),
                ),

                const SizedBox(height: 32),

                // Error details card
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 500),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kCard.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF8E8E93).withOpacity(0.2),
                          width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Troubleshooting:',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ...[
                          'Check your internet connection',
                          'Ensure you have a stable network signal',
                          'Try again in a few moments',
                        ].map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _kRed),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(t,
                                        style: TextStyle(
                                            color: const Color(0xFFCBFBF1)
                                                .withOpacity(0.6),
                                            fontSize: 13,
                                            height: 1.4)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Connection error indicator (red pulsing dot)
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 600),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _PulseDot(color: _kRed),
                      const SizedBox(width: 8),
                      Text('Connection error',
                          style: TextStyle(
                              color:
                                  const Color(0xFFCBFBF1).withOpacity(0.5),
                              fontSize: 13)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Retry button
                _FadeSlideEntry(
                  delay: const Duration(milliseconds: 700),
                  child: _GradButton(
                    label: 'Retry',
                    icon: Icons.refresh_rounded,
                    onTap: onRetry ??
                        () => Navigator.pushReplacementNamed(
                            context, '/driver_requests'),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  3. REQUESTS LIST LOADING  ← مطابق لـ RequestsListLoading.tsx
//
//  RN animations:
//  • Header: opacity:0,y:-20 → opacity:1,y:0  duration:500ms
//  • Tabs:   opacity:0 → 1  delay:200ms
//  • "Loading requests…": opacity [0.5,1,0.5] loop 2s ∞
//  • Skeleton cards: opacity:0,y:20 → 1,0  stagger delay: 400+i*100ms
//  • Shimmer sweep on each card: x −300→300 1.5s linear ∞ delay i*200ms
//  • Loading dots: scale+opacity stagger i*200ms 1.5s ∞
// ══════════════════════════════════════════════════════════════════
class DriverRequestsListLoadingScreen extends StatefulWidget {
  const DriverRequestsListLoadingScreen({super.key});

  @override
  State<DriverRequestsListLoadingScreen> createState() =>
      _RequestsListLoadingState();
}

class _RequestsListLoadingState extends State<DriverRequestsListLoadingScreen>
    with SingleTickerProviderStateMixin {
  // single shimmer controller shared across skeletons
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerX;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // skeleton box helper
  Widget _sk(double h, double w, {double r = 8}) {
    return Container(
      width: w == -1 ? double.infinity : w,
      height: h,
      decoration: BoxDecoration(
        color: _kTeal.withOpacity(0.10),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }

  // skeleton card with shimmer sweep
  Widget _skCard(int index) {
    return _FadeSlideEntry(
      delay: Duration(milliseconds: 400 + index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _kCard.withOpacity(0.8),
              const Color(0xFF0F2334).withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: _kTeal.withOpacity(0.15), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          // shimmer sweep with per-card delay
          AnimatedBuilder(
            animation: _shimmerX,
            builder: (_, __) {
              // offset delayed by index
              final delay = index * 0.2; // 0..0.4 fraction
              final raw = (_shimmerX.value / 600 + delay) % 1.0;
              final x = (raw * 600) - 300;
              return Transform.translate(
                offset: Offset(x, 0),
                child: Container(
                  width: 120,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        _kTeal.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // skeleton content
          Padding(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // price banner
                Container(
                  height: 40,
                  color: _kAmber.withOpacity(0.15),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // route row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kTeal.withOpacity(0.2))),
                            const SizedBox(height: 4),
                            Container(
                                width: 2,
                                height: 24,
                                color: _kTeal.withOpacity(0.15)),
                            const SizedBox(height: 4),
                            Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kAmber.withOpacity(0.2))),
                          ]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _sk(12, 64, r: 6),
                                const SizedBox(height: 4),
                                _sk(16, -1, r: 6),
                                const SizedBox(height: 16),
                                _sk(12, 64, r: 6),
                                const SizedBox(height: 4),
                                _sk(16, -1, r: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // info grid
                      Row(
                        children: List.generate(
                          3,
                          (i) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _kTeal.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _sk(10, 48, r: 4),
                                  const SizedBox(height: 4),
                                  _sk(14, -1, r: 4),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // buttons
                      Row(children: [
                        Expanded(
                            child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                    color: _kTeal.withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(8)))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                    color: _kTeal.withOpacity(0.20),
                                    borderRadius:
                                        BorderRadius.circular(8)))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(children: [
        // blobs
        const Positioned.fill(
          child: IgnorePointer(
            child: Stack(children: [
              _FloatingBlob(
                color: _kTeal,
                size: 256,
                alignment: Alignment(0.8, -0.6),
                animateOffset: Offset(0.12, -0.08),
                duration: Duration(milliseconds: 8000),
              ),
              _FloatingBlob(
                color: _kAmber,
                size: 192,
                alignment: Alignment(-0.6, 0.5),
                animateOffset: Offset(-0.1, 0.15),
                duration: Duration(milliseconds: 10000),
                delay: Duration(milliseconds: 1000),
              ),
            ]),
          ),
        ),

        SafeArea(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // Header skeleton
              _FadeSlideEntry(
                delay: Duration.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sk(28, 100, r: 8),
                    const SizedBox(height: 8),
                    _sk(16, 192, r: 6),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tabs skeleton
              _FadeSlideEntry(
                delay: const Duration(milliseconds: 200),
                child: Row(children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _kGrad,
                        borderRadius: BorderRadius.circular(12),
                        color: _kTeal.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // "Loading requests…" pulsing text
              _FadeSlideEntry(
                delay: const Duration(milliseconds: 300),
                child: _LoadingText(),
              ),
              const SizedBox(height: 8),

              // 3 skeleton cards with stagger
              ...[0, 1, 2].map((i) => _skCard(i)),

              // loading dots
              const SizedBox(height: 16),
              _FadeSlideEntry(
                delay: const Duration(milliseconds: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3, (i) => _LoadingDot(delay: i * 200)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ]),
    );
  }
}

// "Loading requests…" with opacity loop  [0.5,1,0.5] 2s ∞
class _LoadingText extends StatefulWidget {
  @override
  State<_LoadingText> createState() => _LoadingTextState();
}

class _LoadingTextState extends State<_LoadingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, child) => Opacity(opacity: _opacity.value, child: child),
      child: Center(
        child: Text(
          'Loading requests...',
          style: TextStyle(
              color: const Color(0xFFCBFBF1).withOpacity(0.6),
              fontSize: 13),
        ),
      ),
    );
  }
}

// Individual loading dot — scale+opacity stagger  (1.5s ∞)
class _LoadingDot extends StatefulWidget {
  final int delay; // ms
  const _LoadingDot({required this.delay});
  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _scale = Tween<double>(begin: 1.0, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: _kTeal),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  الـ screens القديمة (Earnings + Alerts + Logout)
//  بنفس الـ style الجديد بس محتفظة بنفس الـ API
// ══════════════════════════════════════════════════════════════════

// ─── Earnings ────────────────────────────────────────────────────
class DriverEarningsEmptyScreen extends StatelessWidget {
  const DriverEarningsEmptyScreen({super.key});
  @override
  Widget build(BuildContext context) => DriverRequestsListEmptyScreen(
        onRefresh: () => Navigator.pop(context),
      );
}

class DriverEarningsErrorScreen extends StatelessWidget {
  const DriverEarningsErrorScreen({super.key});
  @override
  Widget build(BuildContext context) => DriverRequestsListErrorScreen(
        onRetry: () => Navigator.pushReplacementNamed(
            context, '/driver_earnings'),
      );
}

class DriverEarningsLoadingScreen extends StatelessWidget {
  const DriverEarningsLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const DriverRequestsListLoadingScreen();
}

// ─── Alerts ──────────────────────────────────────────────────────
class DriverAlertsEmptyScreen extends StatelessWidget {
  const DriverAlertsEmptyScreen({super.key});
  @override
  Widget build(BuildContext context) => DriverRequestsListEmptyScreen(
        onRefresh: () => Navigator.pop(context),
      );
}

class DriverAlertsErrorScreen extends StatelessWidget {
  const DriverAlertsErrorScreen({super.key});
  @override
  Widget build(BuildContext context) => DriverRequestsListErrorScreen(
        onRetry: () => Navigator.pushReplacementNamed(
            context, '/driver_notifications'),
      );
}

class DriverAlertsLoadingScreen extends StatelessWidget {
  const DriverAlertsLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const DriverRequestsListLoadingScreen();
}

// ══════════════════════════════════════════════════════════════════
//  LOGOUT DIALOG — spring scale in (elasticOut 350ms)
// ══════════════════════════════════════════════════════════════════
const Color _kRedLight = Color(0xFFEF4444);

class DriverLogoutDialog extends StatefulWidget {
  const DriverLogoutDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => const DriverLogoutDialog(),
      );

  @override
  State<DriverLogoutDialog> createState() => _DriverLogoutDialogState();
}

class _DriverLogoutDialogState extends State<DriverLogoutDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350))
      ..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    final kCard = d ? const Color(0xFF162535) : Colors.white;
    final kDeep = d ? const Color(0xFF1C2F42) : const Color(0xFFF0F5FA);
    final kText = d ? Colors.white : const Color(0xFF0D1B2A);
    final kSub = d ? Colors.white60 : Colors.black45;
    final kBdr = d ? Colors.white12 : const Color(0xFFE0E8F0);

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBdr),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: d
                      ? const Color(0xFF2A0A0A)
                      : const Color(0xFFFEEEEE),
                  boxShadow: [
                    BoxShadow(
                        color: _kRedLight.withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4)
                  ],
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kRedLight, width: 2.5)),
                  alignment: Alignment.center,
                  child: const Text('!',
                      style: TextStyle(
                          color: _kRedLight,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Logout',
                  style: TextStyle(
                      color: kText,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSub, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: kDeep,
                    borderRadius: BorderRadius.circular(14)),
                child: Text(
                  "You'll need to sign in again to access your account",
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: kSub, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _kTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _kTeal.withOpacity(0.4)),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, color: _kTeal, size: 16),
                            SizedBox(width: 6),
                            Text('Cancel',
                                style: TextStyle(
                                    color: _kTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _kRedLight,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: _kRedLight.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Logout',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ]),
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
}
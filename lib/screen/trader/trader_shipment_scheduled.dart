import 'package:flutter/material.dart';

// RN animations ported from RequestAcceptSuccess.tsx:
// • initial={{ opacity:0, scale:0.9 }} type:"spring" stiffness:200 → wrapper
// • initial={{ scale:0 }} type:"spring" stiffness:200 damping:10 → success icon
// • 3 pulsing rings: scale[1,1.6] opacity[0.4,0] 1.5s infinite (offset 0/0.5/1s)
// • Shimmer: x[-200→200] opacity[0,0.3,0] delay:0.5s → icon surface
// • Confetti: 12 dots, y[0,-80,-120] opacity[0,1,0] rotate[0,360] stagger 0.1s each
// • initial={{ opacity:0, y:10/20 }} → text + cards staggered (delay 0.7/0.8/0.9s)
// • Shimmer sweep x[-300→300] 2s linear infinite → Track button
// • whileTap scale:0.98 → both buttons

class TraderShipmentScheduled extends StatefulWidget {
  final String pickup, dropoff, date, time, packages, weight;
  const TraderShipmentScheduled({super.key,
    required this.pickup, required this.dropoff,
    required this.date, required this.time,
    required this.packages, required this.weight});

  @override
  State<TraderShipmentScheduled> createState() => _TraderShipmentScheduledState();
}

class _TraderShipmentScheduledState extends State<TraderShipmentScheduled>
    with TickerProviderStateMixin {

  // Icon entrance: spring scale 0→1, stiffness 200 damping 10
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

  // Wrapper: opacity+scale 0.9→1, spring stiffness 200
  late final AnimationController _wrapCtrl;
  late final Animation<double> _wrapFade, _wrapScale;

  // 3 pulsing rings
  late final List<AnimationController> _ringCtrls;
  late final List<Animation<double>> _ringScales, _ringOpacities;

  // Shimmer on icon surface
  late final AnimationController _iconShimmerCtrl;
  late final Animation<double> _iconShimmerX, _iconShimmerOpacity;

  // Confetti: 12 dots
  late final List<AnimationController> _confettiCtrls;
  late final List<Animation<double>> _confettiY, _confettiOpacity, _confettiRotate;

  // Content entries: staggered opacity+y
  late final List<AnimationController> _contentCtrls;
  late final List<Animation<double>> _contentFades;
  late final List<Animation<Offset>> _contentSlides;

  // Button shimmer
  late final AnimationController _btnShimmerCtrl;
  late final Animation<double> _btnShimmerX;

  String get _shipmentId {
    final now = DateTime.now();
    return 'TM-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().substring(0, 8)}';
  }

  static const _confettiColors = [
    Color(0xFF34C759), Color(0xFF00D5BE), Color(0xFFF59E0B), Color(0xFFFBBF24)
  ];

  @override
  void initState() {
    super.initState();

    // Wrapper: opacity+scale spring 200ms
    _wrapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _wrapFade  = CurvedAnimation(parent: _wrapCtrl, curve: Curves.easeOut);
    _wrapScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _wrapCtrl, curve: Curves.elasticOut));

    // Icon: spring scale 0→1, delay 200ms
    _iconCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));

    // 3 Pulsing rings: scale[1,1.6] opacity[0.4,0] 1.5s infinite
    _ringCtrls = List.generate(3,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat());
    _ringScales = _ringCtrls.map((c) =>
        Tween<double>(begin: 1.0, end: 1.6)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    _ringOpacities = _ringCtrls.map((c) =>
        Tween<double>(begin: 0.4, end: 0.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Icon shimmer: x[-100→100] opacity[0,0.3,0] 1.5s, delay 500ms
    _iconShimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _iconShimmerX = Tween<double>(begin: -100, end: 100).animate(_iconShimmerCtrl);
    _iconShimmerOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.0), weight: 60),
    ]).animate(_iconShimmerCtrl);

    // Confetti: 12 dots, stagger 100ms each
    _confettiCtrls = List.generate(12,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 2000)));
    _confettiY = _confettiCtrls.map((c) =>
        Tween<double>(begin: 0, end: -120)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();
    _confettiOpacity = _confettiCtrls.map((c) =>
        TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
        ]).animate(c)).toList();
    _confettiRotate = _confettiCtrls.map((c) =>
        Tween<double>(begin: 0, end: 2 * 3.14159)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Content entries: 8 elements, delay 700ms + i*100ms
    _contentCtrls = List.generate(8,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 400)));
    _contentFades = _contentCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>).toList();
    _contentSlides = _contentCtrls.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Button shimmer: x[-300→300] 2s linear infinite
    _btnShimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _btnShimmerX = Tween<double>(begin: -300, end: 300).animate(_btnShimmerCtrl);

    // Start sequence
    _wrapCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _iconCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _iconShimmerCtrl.forward();
    });
    for (int i = 0; i < 12; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _confettiCtrls[i].forward();
      });
    }
    // Ring delays: 0, 500, 1000ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ringCtrls[1].value = 0.33;
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _ringCtrls[2].value = 0.66;
    });
    // Content stagger
    for (int i = 0; i < _contentCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 700 + i * 100), () {
        if (mounted) _contentCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _wrapCtrl.dispose(); _iconCtrl.dispose();
    for (final c in _ringCtrls) { c.dispose(); }
    _iconShimmerCtrl.dispose();
    for (final c in _confettiCtrls) { c.dispose(); }
    for (final c in _contentCtrls) { c.dispose(); }
    _btnShimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF0F2334),
      body: SafeArea(
        child: ScaleTransition(
          scale: _wrapScale,
          child: FadeTransition(
            opacity: _wrapFade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const SizedBox(height: 32),

                // ── Success icon with confetti + rings ──
                SizedBox(
                  height: 160,
                  child: Stack(alignment: Alignment.topCenter, children: [

                    // Confetti: 12 dots (y[0,-120] opacity[0,1,0] rotate[0,2π])
                    ...List.generate(12, (i) => AnimatedBuilder(
                      animation: _confettiCtrls[i],
                      builder: (_, __) => Positioned(
                        left: MediaQuery.of(context).size.width * 0.5 - 80 +
                              (20 + (i * 13.5)) - 24,
                        top: 40 + _confettiY[i].value,
                        child: Opacity(
                          opacity: _confettiOpacity[i].value.clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: _confettiRotate[i].value,
                            child: Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _confettiColors[i % 4])),
                          ),
                        ),
                      ),
                    )),

                    // 3 Pulsing rings
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Center(child: SizedBox(
                        width: 96, height: 96,
                        child: Stack(alignment: Alignment.center, children: [
                          ...List.generate(3, (i) => AnimatedBuilder(
                            animation: _ringCtrls[i],
                            builder: (_, __) => Container(
                              width: 96 * _ringScales[i].value,
                              height: 96 * _ringScales[i].value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF34C759)
                                    .withOpacity(_ringOpacities[i].value.clamp(0.0, 1.0))),
                            ),
                          )),

                          // Main icon
                          ScaleTransition(
                            scale: _iconScale,
                            child: Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF34C759), Color(0xFF30B0C7)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                                boxShadow: [BoxShadow(
                                    color: const Color(0xFF34C759).withOpacity(0.5),
                                    blurRadius: 24, spreadRadius: 4)]),
                              child: ClipOval(child: Stack(alignment: Alignment.center, children: [
                                // Shimmer on icon
                                AnimatedBuilder(
                                  animation: _iconShimmerCtrl,
                                  builder: (_, __) => Positioned(
                                    left: _iconShimmerX.value - 30, top: 0, bottom: 0,
                                    child: Opacity(
                                      opacity: _iconShimmerOpacity.value.clamp(0.0, 1.0),
                                      child: Container(width: 60,
                                        decoration: BoxDecoration(gradient: LinearGradient(
                                          colors: [Colors.transparent, Colors.white, Colors.transparent]))))),
                                ),
                                const Icon(Icons.check_circle_outline_rounded,
                                    color: Colors.white, size: 52),
                              ])),
                            ),
                          ),
                        ]),
                      )),
                    ),
                  ]),
                ),

                const SizedBox(height: 8),

                // Text: opacity+y delay 0.7s
                SlideTransition(position: _contentSlides[0], child: FadeTransition(
                  opacity: _contentFades[0],
                  child: const Text('Shipment Scheduled!',
                    style: TextStyle(color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                )),
                const SizedBox(height: 10),
                SlideTransition(position: _contentSlides[1], child: FadeTransition(
                  opacity: _contentFades[1],
                  child: Text(
                    'Your shipment has been confirmed and\na driver has been assigned',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5),
                        fontSize: 13.5, height: 1.6)),
                )),
                const SizedBox(height: 28),

                // Main card: opacity+y delay 0.9s
                SlideTransition(position: _contentSlides[2], child: FadeTransition(
                  opacity: _contentFades[2],
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1628).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFF00D5BE).withOpacity(0.2), width: 0.8)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Route timeline
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Column(children: [
                          Container(width: 10, height: 10,
                            decoration: const BoxDecoration(
                                color: Color(0xFF00D5BE), shape: BoxShape.circle)),
                          Container(width: 1.5, height: 44,
                            color: const Color(0xFF00D5BE).withOpacity(0.3)),
                          Container(width: 10, height: 10,
                            decoration: const BoxDecoration(
                                color: Color(0xFF0E8FD4), shape: BoxShape.circle)),
                        ]),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Pickup', style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          Text(widget.pickup, style: const TextStyle(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Drop-off', style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          Text(widget.dropoff, style: const TextStyle(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ]),
                      ]),
                      Divider(color: const Color(0xFF00D5BE).withOpacity(0.15), height: 28),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Scheduled Date', style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF00D5BE), size: 14),
                            const SizedBox(width: 5),
                            Text(widget.date, style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Time', style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(widget.time, style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Packages', style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.widgets_outlined, color: Color(0xFF00D5BE), size: 14),
                            const SizedBox(width: 5),
                            Text(widget.packages, style: const TextStyle(
                                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                        ])),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Weight', style: TextStyle(
                              color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${widget.weight} kg', style: const TextStyle(
                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ])),
                      ]),
                      Divider(color: const Color(0xFF00D5BE).withOpacity(0.15), height: 28),
                      // Vehicle card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D5BE).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF00D5BE).withOpacity(0.2), width: 0.8)),
                        child: Row(children: [
                          Container(width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D5BE).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.local_shipping_outlined,
                                color: Color(0xFF00D5BE), size: 20)),
                          const SizedBox(width: 12),
                          const Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Swift Pickup', style: TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text('Pickup Truck', style: TextStyle(
                                color: Color(0xFF00D5BE), fontSize: 12)),
                          ])),
                          const Text('\$240', style: TextStyle(
                              color: Color(0xFF00D5BE), fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ]),
                  ),
                )),
                const SizedBox(height: 16),

                // Driver info bar: delay 1.0s
                SlideTransition(position: _contentSlides[3], child: FadeTransition(
                  opacity: _contentFades[3],
                  child: Container(
                    width: double.infinity, height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x1A00D3F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF00D3F2).withOpacity(0.25), width: 0.8)),
                    child: Row(children: [
                      // Pulsing dot (InTransitScreen pattern: opacity[1,0.4,1] 1.5s infinite)
                      _PulsingDot(color: const Color(0xFF00D3F2)),
                      const SizedBox(width: 10),
                      const Text('Driver will arrive at pickup in 15 minutes',
                          style: TextStyle(color: Color(0xFF00D3F2), fontSize: 13)),
                    ]),
                  ),
                )),
                const SizedBox(height: 16),

                // Track button: shimmer + whileTap
                SlideTransition(position: _contentSlides[4], child: FadeTransition(
                  opacity: _contentFades[4],
                  child: _TapScaleButton(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/trader_home', (route) => false),
                    child: Container(
                      width: double.infinity, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00D5BE), Color(0xFF00D3F2)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: const Color(0xFF00D5BE).withOpacity(0.35),
                            blurRadius: 16, offset: const Offset(0, 6))]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(alignment: Alignment.center, children: [
                          // Shimmer x[-300→300] 2s linear infinite
                          AnimatedBuilder(
                            animation: _btnShimmerX,
                            builder: (_, __) => Positioned(
                              left: _btnShimmerX.value - 40, top: 0, bottom: 0,
                              child: Container(width: 80,
                                decoration: BoxDecoration(gradient: LinearGradient(
                                  colors: [Colors.transparent,
                                    Colors.white.withOpacity(0.2), Colors.transparent])))),
                          ),
                          const Text('Track Shipment', style: TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 12),

                // Return to Home button: delay 1.1s
                SlideTransition(position: _contentSlides[5], child: FadeTransition(
                  opacity: _contentFades[5],
                  child: _TapScaleButton(
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/trader_home', (route) => false),
                    child: Container(
                      width: double.infinity, height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.home_outlined,
                            color: Colors.white.withOpacity(0.7), size: 20),
                        const SizedBox(width: 8),
                        Text('Return to Home', style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 15, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                )),
                const SizedBox(height: 20),

                // Shipment ID: delay 1.2s
                SlideTransition(position: _contentSlides[6], child: FadeTransition(
                  opacity: _contentFades[6],
                  child: Column(children: [
                    Text('Shipment ID', style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(_shipmentId, style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12,
                        letterSpacing: 1.2, fontWeight: FontWeight.w500)),
                  ]),
                )),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// Pulsing dot: opacity[1,0.4,1] scale[1,1.2,1] 1.5s infinite
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity, _scale;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.4).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
    _scale   = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Opacity(
      opacity: _opacity.value,
      child: Transform.scale(
        scale: _scale.value,
        child: Container(width: 8, height: 8,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)))));
}

// whileTap scale:0.98
class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScaleButton({required this.child, required this.onTap});
  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}
class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}
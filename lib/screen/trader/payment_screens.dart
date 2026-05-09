import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════
//  PAYMENT SCREENS — with RN-matching animations
// ══════════════════════════════════════════════════════

const Color _kTeal  = Color(0xFF00D5BE);
const Color _kGreen = Color(0xFF009689);
const Color _kRed   = Color(0xFFEF4444);

// ── Animation constants ──
const Duration _kFast    = Duration(milliseconds: 300);
const Duration _kMed     = Duration(milliseconds: 500);
const Duration _kSlow    = Duration(milliseconds: 700);
const Duration _kStagger = Duration(milliseconds: 80);
const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;
const Curve _kEaseInOut    = Curves.easeInOutCubic;

// ── Animated tap (RN TouchableOpacity) ──
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override
  State<_Tap> createState() => _TapState();
}
class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _ctrl.forward(),
    onTapUp:     (_) { _ctrl.reverse(); widget.onTap?.call(); },
    onTapCancel: ()  => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

// ── Staggered list ──
class _StaggeredList extends StatefulWidget {
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final Duration initialDelay;
  const _StaggeredList({required this.count, required this.itemBuilder,
      this.initialDelay = const Duration(milliseconds: 200)});
  @override
  State<_StaggeredList> createState() => _StaggeredListState();
}
class _StaggeredListState extends State<_StaggeredList>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _fades;
  late List<Animation<Offset>> _slides;
  @override
  void initState() {
    super.initState();
    final total = Duration(
        milliseconds: 350 + widget.count * _kStagger.inMilliseconds);
    _ctrl = AnimationController(vsync: this, duration: total);
    _fades = List.generate(widget.count, (i) {
      final s = (i * _kStagger.inMilliseconds) / total.inMilliseconds;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _ctrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _slides = List.generate(widget.count, (i) {
      final s = (i * _kStagger.inMilliseconds) / total.inMilliseconds;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    Future.delayed(widget.initialDelay, () { if (mounted) _ctrl.forward(); });
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(widget.count, (i) => FadeTransition(
      opacity: _fades[i],
      child: SlideTransition(
          position: _slides[i], child: widget.itemBuilder(context, i)),
    )),
  );
}

// ══════════════════════════════════════════════════════
//  1. PAYMENT PROCESSING SCREEN
// ══════════════════════════════════════════════════════
class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});
  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  // Spinner rotation (RN: Animated.loop on rotate)
  late AnimationController _spinCtrl;
  // Text fade in
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this,
        duration: const Duration(seconds: 1))..repeat();

    _textCtrl  = AnimationController(vsync: this, duration: _kMed);
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _textCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(context,
          _fadeRoute(const PaymentSuccessScreen()));
    });
  }

  @override
  void dispose() { _spinCtrl.dispose(); _textCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kBg   = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kText = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted= isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);

    return Scaffold(
      backgroundColor: kBg,
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing glow behind spinner (RN: Animated opacity on shadow)
          _PulsingGlow(child: SizedBox(
            width: 80, height: 80,
            child: RotationTransition(
              turns: _spinCtrl,
              child: CustomPaint(painter: _SpinnerPainter()),
            ),
          )),
          const SizedBox(height: 48),
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textSlide,
              child: Column(children: [
                Text('Processing\nyour payment...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kText, fontSize: 28,
                        fontWeight: FontWeight.bold, height: 1.3)),
                const SizedBox(height: 16),
                Text('Please wait while we process',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 15)),
              ]),
            ),
          ),
        ],
      )),
    );
  }
}

// Pulsing glow widget (RN: Animated.loop on opacity/scale for glow)
class _PulsingGlow extends StatefulWidget {
  final Widget child;
  const _PulsingGlow({required this.child});
  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}
class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _opacity;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _scale   = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, child) => Stack(alignment: Alignment.center, children: [
      Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kTeal.withOpacity(0.2),
            ),
          ),
        ),
      ),
      child!,
    ]),
    child: widget.child,
  );
}

class _SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      -pi / 2, pi * 1.5, false,
      Paint()
        ..color = _kTeal
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ══════════════════════════════════════════════════════
//  2. PAYMENT SUCCESS SIMPLE SCREEN
// ══════════════════════════════════════════════════════
class PaymentSuccessSimpleScreen extends StatefulWidget {
  const PaymentSuccessSimpleScreen({super.key});
  @override
  State<PaymentSuccessSimpleScreen> createState() =>
      _PaymentSuccessSimpleScreenState();
}

class _PaymentSuccessSimpleScreenState extends State<PaymentSuccessSimpleScreen>
    with TickerProviderStateMixin {
  // Check icon scale bounce (RN: spring scale 0→1)
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale, _iconFade;
  // Text stagger
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  // Button slide up
  late AnimationController _btnCtrl;
  late Animation<Offset> _btnSlide;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _iconCtrl  = AnimationController(vsync: this, duration: _kSlow);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: _kEaseOutBack));
    _iconFade  = CurvedAnimation(parent: _iconCtrl, curve: _kEaseOutCubic);

    _textCtrl  = AnimationController(vsync: this, duration: _kMed);
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic));

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _runSequence();
  }

  void _runSequence() async {
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose(); _textCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kBg   = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kText = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted= isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);

    return Scaffold(
      backgroundColor: kBg,
      body: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // ── Check icon — bounce scale ──
          ScaleTransition(
            scale: _iconScale,
            child: FadeTransition(
              opacity: _iconFade,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009689), _kTeal],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.45),
                      blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 52),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // ── Text — fade + slide ──
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textSlide,
              child: Column(children: [
                Text('Payment\nSuccessful', textAlign: TextAlign.center,
                    style: TextStyle(color: kText, fontSize: 30,
                        fontWeight: FontWeight.bold, height: 1.3)),
                const SizedBox(height: 16),
                Text('Your payment has been processed',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 16)),
              ]),
            ),
          ),
          const SizedBox(height: 80),

          // ── Button — slide up ──
          SlideTransition(
            position: _btnSlide,
            child: FadeTransition(
              opacity: _btnFade,
              child: _GradientBtn(
                label: 'View Invoice',
                onTap: () => Navigator.pushReplacement(context,
                    _slideUpRoute(const PaymentSuccessScreen())),
              ),
            ),
          ),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════
//  3. PAYMENT FAILED SCREEN
// ══════════════════════════════════════════════════════
class PaymentFailedScreen extends StatefulWidget {
  const PaymentFailedScreen({super.key});
  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconCtrl, _textCtrl, _btnCtrl;
  late Animation<double> _iconScale, _iconFade, _textFade, _btnFade;
  late Animation<Offset> _textSlide, _btnSlide;

  @override
  void initState() {
    super.initState();
    _iconCtrl  = AnimationController(vsync: this, duration: _kSlow);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: _kEaseOutBack));
    _iconFade  = CurvedAnimation(parent: _iconCtrl, curve: _kEaseOutCubic);

    _textCtrl  = AnimationController(vsync: this, duration: _kMed);
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic));

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));

    _runSequence();
  }

  void _runSequence() async {
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose(); _textCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0F2030) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _iconScale,
            child: FadeTransition(
              opacity: _iconFade,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _kRed,
                  boxShadow: [BoxShadow(color: _kRed.withOpacity(0.45),
                      blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.white, size: 52),
              ),
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _textFade,
            child: SlideTransition(
              position: _textSlide,
              child: Column(children: [
                Text('Payment failed', textAlign: TextAlign.center,
                    style: TextStyle(color: kText, fontSize: 30,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                Text('Please try again', textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 16)),
              ]),
            ),
          ),
          const SizedBox(height: 60),
          SlideTransition(
            position: _btnSlide,
            child: FadeTransition(
              opacity: _btnFade,
              child: Column(children: [
                _GradientBtn(label: 'Retry Payment',
                    onTap: () => Navigator.pushReplacement(context,
                        _fadeRoute(const PaymentProcessingScreen()))),
                const SizedBox(height: 14),
                _Tap(
                  onTap: () => Navigator.push(context,
                      _slideUpRoute(const PaymentMethodsSelectScreen())),
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text('Change Method',
                        style: TextStyle(color: kText, fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════
//  4. PAYMENT METHODS LIST SCREEN
// ══════════════════════════════════════════════════════
class PaymentMethodsListScreen extends StatefulWidget {
  const PaymentMethodsListScreen({super.key});
  @override
  State<PaymentMethodsListScreen> createState() =>
      _PaymentMethodsListScreenState();
}

class _PaymentMethodsListScreenState extends State<PaymentMethodsListScreen>
    with TickerProviderStateMixin {
  final List<_CardData> _cards = [
    _CardData(brand: 'Visa',       last4: '4532', expiry: '12/25',
        isDefault: true,  color: const Color(0xFF3B5BF6)),
    _CardData(brand: 'Mastercard', last4: '8901', expiry: '08/26',
        isDefault: false, color: const Color(0xFFFF6B35)),
  ];

  // Header entry
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Button entry
  late AnimationController _btnCtrl;
  late Animation<double> _btnFade;
  late Animation<Offset> _btnSlide;

  void _deleteCard(int index) => setState(() => _cards.removeAt(index));

  @override
  void initState() {
    super.initState();
    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() { _headerCtrl.dispose(); _btnCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0D1F30) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),

          // ── Header ──
          FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _CircleBackBtn(isDark: isDark, kBorder: kBorder),
                const SizedBox(width: 16),
                Text('Payment Methods', style: TextStyle(color: kText,
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const SizedBox(height: 28),

          // ── Add button ──
          SlideTransition(
            position: _btnSlide,
            child: FadeTransition(
              opacity: _btnFade,
              child: _GradientBtn(
                label: '+ Add New Card',
                onTap: () => Navigator.push(context,
                    _slideUpRoute(const AddCardScreen())),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text('Saved Cards', style: TextStyle(color: kMuted, fontSize: 15,
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // ── Cards list — staggered ──
          Expanded(child: _StaggeredList(
            count: _cards.length,
            initialDelay: const Duration(milliseconds: 300),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _CardTile(
                card: _cards[i], isDark: isDark,
                kCard: kCard, kText: kText, kMuted: kMuted, kBorder: kBorder,
                onDelete: () => _deleteCard(i),
              ),
            ),
          )),
        ]),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════
//  5. PAYMENT SUCCESS FULL SCREEN
// ══════════════════════════════════════════════════════
class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({super.key});
  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  // Check icon bounce
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale, _iconFade;
  // Amount counter (RN: Animated.timing on number)
  late AnimationController _amountCtrl;
  late Animation<double> _amountValue;
  // Receipt card slide up
  late AnimationController _receiptCtrl;
  late Animation<Offset> _receiptSlide;
  late Animation<double> _receiptFade;
  // Bottom buttons stagger
  late AnimationController _btnsCtrl;
  late List<Animation<double>> _btnFades;
  late List<Animation<Offset>> _btnSlides;

  static const int _kBtns = 3;

  String _generateTxnId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    return 'TXN-' + List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    _iconCtrl  = AnimationController(vsync: this, duration: _kSlow);
    _iconScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: _kEaseOutBack));
    _iconFade  = CurvedAnimation(parent: _iconCtrl, curve: _kEaseOutCubic);

    _amountCtrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _amountValue = Tween<double>(begin: 0, end: 240)
        .animate(CurvedAnimation(parent: _amountCtrl, curve: _kEaseOutCubic));

    _receiptCtrl  = AnimationController(vsync: this, duration: _kMed);
    _receiptSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _receiptCtrl, curve: _kEaseOutCubic));
    _receiptFade  = CurvedAnimation(parent: _receiptCtrl, curve: _kEaseOutCubic);

    final totalMs = 350 + _kBtns * _kStagger.inMilliseconds;
    _btnsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));
    _btnFades = List.generate(_kBtns, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _btnsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _btnSlides = List.generate(_kBtns, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(CurvedAnimation(parent: _btnsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _runSequence();
  }

  void _runSequence() async {
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _amountCtrl.forward();
    _receiptCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _btnsCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose(); _amountCtrl.dispose();
    _receiptCtrl.dispose(); _btnsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0D1F30) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2EAF0);

    final now    = DateTime.now();
    final txnId  = _generateTxnId();
    final dateStr= '${_month(now.month)} ${now.day}, ${now.year} • '
        '${_hour(now.hour)}:${now.minute.toString().padLeft(2, '0')} '
        '${now.hour >= 12 ? 'PM' : 'AM'}';

    final btns = [
      ('☆  Rate Your Experience', () {}),
      ('↓  Download Invoice',      () {}),
      ('⌂  Return to Home',
          () => Navigator.of(context).popUntil((r) => r.isFirst)),
    ];

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 40),

          // ── Check icon — bounce ──
          ScaleTransition(
            scale: _iconScale,
            child: FadeTransition(
              opacity: _iconFade,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF009689), _kTeal],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.4),
                      blurRadius: 35, spreadRadius: 6)],
                ),
                child: const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 56),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text('Payment Successful!', textAlign: TextAlign.center,
              style: TextStyle(color: kText, fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Your payment has been processed successfully',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 15)),
          const SizedBox(height: 32),

          // ── Receipt card — slide up ──
          SlideTransition(
            position: _receiptSlide,
            child: FadeTransition(
              opacity: _receiptFade,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: isDark ? [] : [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Text('Amount Paid',
                      style: TextStyle(color: kMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  // Animated counter (RN: Animated.timing on number value)
                  AnimatedBuilder(
                    animation: _amountValue,
                    builder: (_, __) => Text(
                      '\$${_amountValue.value.toInt()}',
                      style: const TextStyle(color: _kTeal, fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: kBorder),
                  const SizedBox(height: 16),
                  _ReceiptRow(label: 'Transaction ID', value: txnId,
                      kText: kText, kMuted: kMuted),
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'Date & Time', value: dateStr,
                      kText: kText, kMuted: kMuted),
                  const SizedBox(height: 12),
                  _ReceiptRow(label: 'Payment Method', value: 'Visa **** 4532',
                      kText: kText, kMuted: kMuted),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Email receipt info
          SlideTransition(
            position: _receiptSlide,
            child: FadeTransition(
              opacity: _receiptFade,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorder),
                ),
                child: Center(child: Text(
                    'A receipt has been sent to your email',
                    style: TextStyle(color: kMuted, fontSize: 14))),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Bottom buttons — staggered ──
          ...List.generate(_kBtns, (i) {
            final (label, onTap) = btns[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FadeTransition(
                opacity: _btnFades[i],
                child: SlideTransition(
                  position: _btnSlides[i],
                  child: i == 0
                    ? _GradientBtn(label: label, onTap: onTap)
                    : _OutlineBtn(label: label, kCard: kCard,
                          kText: kText, kBorder: kBorder, onTap: onTap),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
  int _hour(int h) => h > 12 ? h - 12 : (h == 0 ? 12 : h);
}

// ══════════════════════════════════════════════════════
//  6. PAYMENT METHODS SELECT SCREEN
// ══════════════════════════════════════════════════════
class PaymentMethodsSelectScreen extends StatefulWidget {
  final String driverName;
  final double price;
  const PaymentMethodsSelectScreen({super.key,
      this.driverName = '', this.price = 0});
  @override
  State<PaymentMethodsSelectScreen> createState() =>
      _PaymentMethodsSelectScreenState();
}

class _PaymentMethodsSelectScreenState
    extends State<PaymentMethodsSelectScreen> with TickerProviderStateMixin {
  int _selected = 0;

  final _methods = [
    _PayMethod(icon: Icons.credit_card_rounded, name: 'Visa',
        sub: '**** **** **** 4532', isDefault: true),
    _PayMethod(icon: Icons.credit_card_rounded, name: 'Mastercard',
        sub: '**** **** **** 8901', isDefault: false),
    _PayMethod(icon: Icons.account_balance_wallet_outlined,
        name: 'TruckMate Wallet', sub: '\$480.00 available', isDefault: false),
  ];

  // Header entry
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Confirm button slide up
  late AnimationController _btnCtrl;
  late Animation<Offset> _btnSlide;
  late Animation<double> _btnFade;

  @override
  void initState() {
    super.initState();
    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() { _headerCtrl.dispose(); _btnCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0D1F30) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _CircleBackBtn(isDark: isDark, kBorder: kBorder),
                const SizedBox(width: 16),
                Text('Payment Methods', style: TextStyle(color: kText,
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // ── Methods list — staggered ──
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _StaggeredList(
            count: _methods.length + 1,
            initialDelay: const Duration(milliseconds: 150),
            itemBuilder: (_, i) {
              if (i == _methods.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _Tap(
                    onTap: () => Navigator.push(context,
                        _slideUpRoute(const AddCardScreen())),
                    child: Container(
                      width: double.infinity, height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: _kTeal, size: 20),
                          const SizedBox(width: 10),
                          Text('Add New Payment Method',
                              style: TextStyle(color: _kTeal, fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final m = _methods[i];
              final selected = _selected == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Tap(
                  onTap: () => setState(() => _selected = i),
                  child: AnimatedContainer(
                    duration: _kFast,
                    curve: _kEaseOutCubic,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selected ? _kTeal : kBorder,
                          width: selected ? 1.5 : 1),
                      boxShadow: isDark ? [] : [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _kTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(m.icon, color: _kTeal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(m.name, style: TextStyle(color: kText,
                                fontSize: 16, fontWeight: FontWeight.w600)),
                            if (m.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _kTeal.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _kTeal.withOpacity(0.4)),
                                ),
                                child: const Text('Default',
                                    style: TextStyle(color: _kTeal,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 4),
                          Text(m.sub, style: TextStyle(
                              color: kMuted, fontSize: 13)),
                        ],
                      )),
                      if (selected)
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _kTeal, width: 2),
                            color: _kTeal.withOpacity(0.12),
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: _kTeal, size: 16),
                        ),
                    ]),
                  ),
                ),
              );
            },
          ),
        )),

        // ── Confirm button — slide up ──
        SlideTransition(
          position: _btnSlide,
          child: FadeTransition(
            opacity: _btnFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: _GradientBtn(
                label: 'Confirm Payment Method',
                onTap: () => Navigator.pushReplacement(context,
                    _fadeRoute(const PaymentProcessingScreen())),
              ),
            ),
          ),
        ),
      ])),
    );
  }
}

// ══════════════════════════════════════════════════════
//  ADD CARD SCREEN
// ══════════════════════════════════════════════════════
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with TickerProviderStateMixin {
  final _numberCtrl = TextEditingController();
  final _nameCtrl   = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl    = TextEditingController();

  // Card form — slide up from bottom (RN: spring translateY)
  late AnimationController _formCtrl;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  // Header
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    _formCtrl  = AnimationController(vsync: this, duration: _kMed);
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _formCtrl, curve: _kEaseOutCubic));
    _formFade  = CurvedAnimation(parent: _formCtrl, curve: _kEaseOutCubic);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _numberCtrl.dispose(); _nameCtrl.dispose();
    _expiryCtrl.dispose(); _cvvCtrl.dispose();
    _headerCtrl.dispose(); _formCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final kBg      = isDark ? const Color(0xFF0B1A2C) : const Color(0xFFF5F8FA);
    final kCard    = isDark ? const Color(0xFF0D1F30) : Colors.white;
    final kText    = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted   = isDark ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
    final kBorder  = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2EAF0);
    final kFieldBg = isDark ? const Color(0xFF112030) : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _CircleBackBtn(isDark: isDark, kBorder: kBorder),
                const SizedBox(width: 16),
                Text('Add New Card', style: TextStyle(color: kText,
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Form card — slide up ──
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SlideTransition(
            position: _formSlide,
            child: FadeTransition(
              opacity: _formFade,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kBorder),
                  boxShadow: isDark ? [] : [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _FieldLabel('Card Number', kText),
                  _CardTextField(_numberCtrl, 'XXXX XXXX XXXX XXXX',
                      TextInputType.number, kText, kMuted, kFieldBg, kBorder,
                      icon: Icons.credit_card_rounded),
                  const SizedBox(height: 18),
                  _FieldLabel('Cardholder Name', kText),
                  _CardTextField(_nameCtrl, 'Name on card',
                      TextInputType.name, kText, kMuted, kFieldBg, kBorder,
                      icon: Icons.person_outline),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Expiry Date', kText),
                        _CardTextField(_expiryCtrl, 'MM/YY',
                            TextInputType.datetime, kText, kMuted,
                            kFieldBg, kBorder,
                            icon: Icons.calendar_month_outlined),
                      ])),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('CVV', kText),
                        _CardTextField(_cvvCtrl, '•••',
                            TextInputType.number, kText, kMuted,
                            kFieldBg, kBorder,
                            icon: Icons.lock_outline, obscure: true),
                      ])),
                  ]),
                  const SizedBox(height: 28),
                  _GradientBtn(
                    label: 'Add Card',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Card added successfully!'),
                        backgroundColor: _kTeal,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    },
                  ),
                ]),
              ),
            ),
          ),
        )),
        const SizedBox(height: 20),
      ])),
    );
  }
}

// ══════════════════════════════════════════════════════
//  ROUTE HELPERS
// ══════════════════════════════════════════════════════
Route<T> _slideUpRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMed,
  reverseTransitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) {
    final slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    return SlideTransition(position: slide,
        child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: _kEaseOutCubic),
            child: child));
  },
);

Route<T> _fadeRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
);

// ══════════════════════════════════════════════════════
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════
class _GradientBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF009689), _kTeal],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.35),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Colors.white,
          fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final Color kCard, kText, kBorder;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.kCard,
      required this.kText, required this.kBorder, required this.onTap});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder)),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(color: kText,
          fontSize: 16, fontWeight: FontWeight.w500)),
    ),
  );
}

class _CircleBackBtn extends StatelessWidget {
  final bool isDark;
  final Color kBorder;
  const _CircleBackBtn({required this.isDark, required this.kBorder});
  @override
  Widget build(BuildContext context) => _Tap(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF0D1F30) : Colors.white,
        border: Border.all(color: kBorder),
      ),
      child: Icon(Icons.chevron_left_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A2A3A), size: 24),
    ),
  );
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  final Color kText, kMuted;
  const _ReceiptRow({required this.label, required this.value,
      required this.kText, required this.kMuted});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: kMuted, fontSize: 14)),
      Flexible(child: Text(value, textAlign: TextAlign.right,
          style: TextStyle(color: kText, fontSize: 14,
              fontWeight: FontWeight.w500))),
    ],
  );
}

class _CardTile extends StatelessWidget {
  final _CardData card;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder;
  final VoidCallback onDelete;
  const _CardTile({required this.card, required this.isDark,
      required this.kCard, required this.kText, required this.kMuted,
      required this.kBorder, required this.onDelete});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: kCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
      boxShadow: isDark ? [] : [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(children: [
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(color: card.color,
            borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.credit_card_rounded,
            color: Colors.white, size: 26),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(card.brand, style: TextStyle(color: kText,
              fontSize: 16, fontWeight: FontWeight.w600)),
          if (card.isDefault) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: _kTeal, borderRadius: BorderRadius.circular(20)),
              child: const Text('Default', style: TextStyle(color: Colors.white,
                  fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        const SizedBox(height: 6),
        Text('•••• •••• •••• ${card.last4}',
            style: TextStyle(color: kMuted, fontSize: 14)),
        const SizedBox(height: 2),
        Text('Expires ${card.expiry}',
            style: TextStyle(color: kMuted, fontSize: 13)),
      ])),
      _Tap(
        onTap: onDelete,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: _kRed.withOpacity(0.12)),
          child: Icon(Icons.delete_outline_rounded, color: _kRed, size: 20),
        ),
      ),
    ]),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final Color kText;
  const _FieldLabel(this.text, this.kText);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(color: kText,
        fontSize: 14, fontWeight: FontWeight.w500)),
  );
}

Widget _CardTextField(
    TextEditingController ctrl, String hint, TextInputType type,
    Color kText, Color kMuted, Color kFieldBg, Color kBorder,
    {IconData? icon, bool obscure = false}) =>
  TextField(
    controller: ctrl, keyboardType: type, obscureText: obscure,
    style: TextStyle(color: kText, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: kMuted, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: _kTeal, size: 20) : null,
      filled: true, fillColor: kFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kTeal, width: 1.5)),
    ),
  );

// ── Data models ──
class _CardData {
  final String brand, last4, expiry;
  final bool isDefault;
  final Color color;
  _CardData({required this.brand, required this.last4, required this.expiry,
      required this.isDefault, required this.color});
}

class _PayMethod {
  final IconData icon;
  final String name, sub;
  final bool isDefault;
  _PayMethod({required this.icon, required this.name,
      required this.sub, required this.isDefault});
}
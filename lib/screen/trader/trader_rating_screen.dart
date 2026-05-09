import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════
//  TRADER RATING SCREENS — with RN-matching animations
// ══════════════════════════════════════════════════════

// ── Animation constants ──
const Duration _kFast    = Duration(milliseconds: 300);
const Duration _kMed     = Duration(milliseconds: 500);
const Duration _kSlow    = Duration(milliseconds: 700);
const Duration _kStagger = Duration(milliseconds: 80);
const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;
const Curve _kEaseInOut    = Curves.easeInOutCubic;

// ── Animated tap — scale 0.96 (RN TouchableOpacity) ──
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Tap({required this.child, this.onTap});
  @override
  State<_Tap> createState() => _TapState();
}
class _TapState extends State<_Tap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap?.call(); },
    onTapCancel: ()  => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
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
//  RATE DRIVER SCREEN
// ══════════════════════════════════════════════════════
class RateDriverScreen extends StatefulWidget {
  final String driverName, driverInitials;
  const RateDriverScreen({
    super.key,
    this.driverName     = 'John Michael',
    this.driverInitials = 'JD',
  });
  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen>
    with TickerProviderStateMixin {
  int _stars = 0;
  bool _recommend = false;
  int _easeOfAccess = 0, _timing = 0, _communication = 0, _facilities = 0;

  // ── Header fade + slide down ──
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // ── Driver card — scale bounce (RN: spring scale 0.9→1) ──
  late AnimationController _driverCtrl;
  late Animation<double> _driverScale, _driverFade;

  // ── Stars card — slide up ──
  late AnimationController _starsCtrl;
  late Animation<double> _starsFade;
  late Animation<Offset> _starsSlide;

  // ── Aspects card — slide up with delay ──
  late AnimationController _aspectsCtrl;
  late Animation<double> _aspectsFade;
  late Animation<Offset> _aspectsSlide;

  // ── Each star — individual scale bounce on tap ──
  late List<AnimationController> _starCtrls;
  late List<Animation<double>> _starScales;

  // ── Aspect circles — scale on select ──
  late List<List<AnimationController>> _aspectCtrls;

  // ── Submit button — slide up ──
  late AnimationController _btnCtrl;
  late Animation<Offset> _btnSlide;
  late Animation<double> _btnFade;

  static const _starLabels = [
    'Tap a star to rate', 'Terrible!', 'Not great...',
    'It was okay.', 'Pretty good!', "Great 5 stars! Can't get any better than that!",
  ];

  bool get _canSubmit =>
      _stars > 0 && _easeOfAccess > 0 && _timing > 0 &&
      _communication > 0 && _facilities > 0;

  @override
  void initState() {
    super.initState();

    // Header
    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    // Driver card
    _driverCtrl  = AnimationController(vsync: this, duration: _kMed);
    _driverScale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _driverCtrl, curve: _kEaseOutBack));
    _driverFade  = CurvedAnimation(parent: _driverCtrl, curve: _kEaseOutCubic);

    // Stars card
    _starsCtrl  = AnimationController(vsync: this, duration: _kMed);
    _starsFade  = CurvedAnimation(parent: _starsCtrl, curve: _kEaseOutCubic);
    _starsSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _starsCtrl, curve: _kEaseOutCubic));

    // Aspects card
    _aspectsCtrl  = AnimationController(vsync: this, duration: _kMed);
    _aspectsFade  = CurvedAnimation(parent: _aspectsCtrl, curve: _kEaseOutCubic);
    _aspectsSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _aspectsCtrl, curve: _kEaseOutCubic));

    // Individual star bounce controllers
    _starCtrls = List.generate(5, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200)));
    _starScales = _starCtrls.map((c) => Tween<double>(begin: 1.0, end: 1.35)
        .animate(CurvedAnimation(parent: c, curve: _kEaseOutBack))).toList();

    // Aspect circle controllers (4 aspects × 5 options)
    _aspectCtrls = List.generate(4, (_) => List.generate(5, (_) =>
        AnimationController(vsync: this,
            duration: const Duration(milliseconds: 250))));

    // Submit button
    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _runSequence();
  }

  void _runSequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _driverCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _starsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _aspectsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose(); _driverCtrl.dispose();
    _starsCtrl.dispose(); _aspectsCtrl.dispose();
    _btnCtrl.dispose();
    for (final c in _starCtrls) c.dispose();
    for (final row in _aspectCtrls) for (final c in row) c.dispose();
    super.dispose();
  }

  void _onStarTap(int i) {
    setState(() => _stars = i + 1);
    // Bounce all selected stars
    for (int j = 0; j <= i; j++) {
      _starCtrls[j].forward(from: 0).then((_) => _starCtrls[j].reverse());
    }
  }

  void _onAspectTap(int aspectIdx, int val, List<int> aspects, Function(int) setter) {
    setState(() => setter(val));
    final c = _aspectCtrls[aspectIdx][val - 1];
    c.forward(from: 0).then((_) => c.reverse());
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0A1A24) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0A1628) : Colors.white;
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFFCBFBF1) : const Color(0xFF8A9BB0);
    final kTeal   = const Color(0xFF00D5BE);
    final kGreen  = const Color(0xFF009689);
    final kBorder = isDark ? kTeal.withOpacity(0.15) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // ── [0] Header — fade + slide down ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _backBtn(context, isDark, kCard, kTeal, kBorder),
                Expanded(child: Center(child: Text('Reviews and Ratings',
                    style: TextStyle(color: kText, fontSize: 18,
                        fontWeight: FontWeight.bold)))),
                const SizedBox(width: 38),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [

            // ── [1] Driver card — scale bounce ──
            ScaleTransition(
              scale: _driverScale,
              child: FadeTransition(
                opacity: _driverFade,
                child: _buildCard(isDark: isDark, kCard: kCard, kBorder: kBorder,
                  child: Row(children: [
                    Stack(children: [
                      Container(width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8904), Color(0xFF9810FA)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight),
                          border: Border.all(color: kGreen, width: 2)),
                        child: Center(child: Text(widget.driverInitials,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 20, fontWeight: FontWeight.bold)))),
                      Positioned(bottom: 2, right: 2,
                        child: Container(width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: kTeal,
                            border: Border.all(color: kBg, width: 2)))),
                    ]),
                    const SizedBox(width: 14),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.driverName, style: TextStyle(color: kText,
                          fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Professional Driver',
                          style: TextStyle(color: kMuted.withOpacity(0.6),
                              fontSize: 13)),
                    ]),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── [2] Stars card — fade + slide up ──
            FadeTransition(
              opacity: _starsFade,
              child: SlideTransition(
                position: _starsSlide,
                child: _buildCard(isDark: isDark, kCard: kCard, kBorder: kBorder,
                  child: Column(children: [
                    Text('How was the trip?', style: TextStyle(color: kText,
                        fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // Stars — each bounces on tap
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) => _Tap(
                        onTap: () => _onStarTap(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: ScaleTransition(
                            scale: _starScales[i],
                            child: Icon(
                              i < _stars
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: i < _stars ? kTeal
                                  : (isDark
                                      ? kMuted.withOpacity(0.3)
                                      : const Color(0xFFCDD5DE)),
                              size: 48),
                          ),
                        ),
                      )),
                    ),
                    const SizedBox(height: 12),

                    // Label — animated crossfade (RN: FadeIn on text change)
                    AnimatedSwitcher(
                      duration: _kFast,
                      child: Text(_starLabels[_stars],
                        key: ValueKey(_stars),
                        style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.45)
                                : kMuted,
                            fontSize: 13),
                        textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),

                    // Recommend checkbox — animated
                    _Tap(
                      onTap: () => setState(() => _recommend = !_recommend),
                      child: Row(children: [
                        _checkCircle(_recommend, kTeal, kGreen, isDark, kMuted),
                        const SizedBox(width: 10),
                        Text('I recommend this driver',
                            style: TextStyle(
                              color: _recommend ? kText
                                  : (isDark ? kMuted.withOpacity(0.4) : kMuted),
                              fontSize: 14)),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── [3] Aspects card — fade + slide up ──
            FadeTransition(
              opacity: _aspectsFade,
              child: SlideTransition(
                position: _aspectsSlide,
                child: _buildCard(isDark: isDark, kCard: kCard, kBorder: kBorder,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('How would you rate the following aspects?',
                        style: TextStyle(color: kMuted, fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    _aspectRow(0, 'Ease of Access', _easeOfAccess,
                        (v) => setState(() => _easeOfAccess = v),
                        kText, kTeal, kGreen, kMuted, isDark),
                    const SizedBox(height: 20),
                    _aspectRow(1, 'Timing', _timing,
                        (v) => setState(() => _timing = v),
                        kText, kTeal, kGreen, kMuted, isDark),
                    const SizedBox(height: 20),
                    _aspectRow(2, 'Communication', _communication,
                        (v) => setState(() => _communication = v),
                        kText, kTeal, kGreen, kMuted, isDark),
                    const SizedBox(height: 20),
                    _aspectRow(3, 'Facilities', _facilities,
                        (v) => setState(() => _facilities = v),
                        kText, kTeal, kGreen, kMuted, isDark),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        )),

        // ── Submit button — slide up + opacity ──
        SlideTransition(
          position: _btnSlide,
          child: FadeTransition(
            opacity: _btnFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: AnimatedOpacity(
                opacity: _canSubmit ? 1.0 : 0.45,
                duration: _kFast,
                child: _Tap(
                  onTap: _canSubmit
                      ? () => Navigator.push(context,
                          _slideUpRoute(const WriteReviewScreen()))
                      : null,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009689), Color(0xFF00B8DB)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _canSubmit ? [BoxShadow(
                          color: kTeal.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6))] : [],
                    ),
                    alignment: Alignment.center,
                    child: const Text('Continue', style: TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ])),
    );
  }

  Widget _aspectRow(int aspectIdx, String label, int selected,
      ValueChanged<int> onSelect,
      Color kText, Color kTeal, Color kGreen, Color kMuted, bool isDark) {
    final labels = ['Bad', 'So so', 'Good', 'Great', 'Amazing'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: kText,
          fontSize: 14, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(5, (i) {
          final active = selected == i + 1;
          return _Tap(
            onTap: () {
              onSelect(i + 1);
              // Bounce the selected circle
              final c = _aspectCtrls[aspectIdx][i];
              c.forward(from: 0).then((_) => c.reverse());
            },
            child: Column(children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.25).animate(
                    CurvedAnimation(parent: _aspectCtrls[aspectIdx][i],
                        curve: _kEaseOutBack)),
                child: AnimatedContainer(
                  duration: _kFast,
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: active ? const LinearGradient(
                      colors: [Color(0xFF009689), Color(0xFF00B8DB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight) : null,
                    color: active ? null : Colors.transparent,
                    border: Border.all(
                      color: active ? Colors.transparent
                          : kTeal.withOpacity(isDark ? 0.4 : 0.3),
                      width: 1.5)),
                  child: Center(child: Text('${i + 1}', style: TextStyle(
                    color: active ? Colors.white
                        : (isDark ? kMuted.withOpacity(0.35) : kMuted),
                    fontSize: 15, fontWeight: FontWeight.w600)))),
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: TextStyle(
                  color: isDark ? kMuted.withOpacity(0.35) : kMuted,
                  fontSize: 10)),
            ]),
          );
        }),
      ),
    ]);
  }

  Widget _checkCircle(bool active, Color kTeal, Color kGreen,
      bool isDark, Color kMuted) =>
    AnimatedContainer(
      duration: _kFast,
      width: 24, height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? const LinearGradient(
          colors: [Color(0xFF009689), Color(0xFF00B8DB)],
          begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: active ? null : Colors.transparent,
        border: Border.all(
          color: active ? Colors.transparent
              : kTeal.withOpacity(isDark ? 0.3 : 0.4),
          width: 1.5)),
      child: active
          ? const Icon(Icons.check, color: Colors.white, size: 14) : null);
}

// ══════════════════════════════════════════════════════
//  WRITE REVIEW SCREEN
// ══════════════════════════════════════════════════════
class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});
  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen>
    with TickerProviderStateMixin {
  final _summaryCtrl = TextEditingController();
  final _reviewCtrl  = TextEditingController();

  // Header
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Form cards — staggered slide up
  late AnimationController _cardsCtrl;
  static const int _kCards = 3;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  // Submit button — slide up
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

    final totalMs = 350 + _kCards * _kStagger.inMilliseconds;
    _cardsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));
    _cardFades = List.generate(_kCards, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _cardSlides = List.generate(_kCards, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) { _cardsCtrl.forward(); _btnCtrl.forward(); }
    });
  }

  @override
  void dispose() {
    _summaryCtrl.dispose(); _reviewCtrl.dispose();
    _headerCtrl.dispose(); _cardsCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  Widget _card(int i, Widget child) => FadeTransition(
    opacity: _cardFades[i],
    child: SlideTransition(position: _cardSlides[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final kBg      = isDark ? const Color(0xFF0A1A24) : const Color(0xFFF5F8FA);
    final kCard    = isDark ? const Color(0xFF0A1628) : Colors.white;
    final kCard2   = isDark ? const Color(0xFF0F2A3A) : const Color(0xFFF8FAFB);
    final kText    = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted   = isDark ? const Color(0xFFCBFBF1) : const Color(0xFF8A9BB0);
    final kTeal    = const Color(0xFF00D5BE);
    final kGreen   = const Color(0xFF009689);
    final kBorder  = isDark ? kTeal.withOpacity(0.15) : const Color(0xFFE2EAF0);
    final kFieldBg = isDark ? kCard.withOpacity(0.5) : const Color(0xFFF0F4F8);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _backBtn(context, isDark, kCard, kTeal, kBorder),
                Expanded(child: Center(child: Text('Write Review',
                    style: TextStyle(color: kText, fontSize: 18,
                        fontWeight: FontWeight.bold)))),
                const SizedBox(width: 38),
              ]),
            ),
          ),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            decoration: BoxDecoration(
              color: isDark ? kCard.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
              boxShadow: isDark ? [] : [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [

              // ── [0] Summary field ──
              _card(0, _buildCard(isDark: isDark, kCard: kCard2, kBorder: kBorder,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Summarize your review', style: TextStyle(color: kText,
                      fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _summaryCtrl,
                    style: TextStyle(color: kText, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Great experience!',
                      hintStyle: TextStyle(color: kMuted, fontSize: 14),
                      filled: true, fillColor: kFieldBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
                ]))),
              const SizedBox(height: 16),

              // ── [1] Review text field ──
              _card(1, _buildCard(isDark: isDark, kCard: kCard2, kBorder: kBorder,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Write your review', style: TextStyle(color: kText,
                      fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewCtrl, maxLines: 5,
                    style: TextStyle(color: kText, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Share details about your experience...',
                      hintStyle: TextStyle(color: kMuted, fontSize: 14),
                      filled: true, fillColor: kFieldBg,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none))),
                ]))),
              const SizedBox(height: 16),

              // ── [2] Photos upload ──
              _card(2, _buildCard(isDark: isDark, kCard: kCard2, kBorder: kBorder,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Upload Photos', style: TextStyle(color: kText,
                      fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Share photos from the trip (optional)',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                  const SizedBox(height: 14),
                  _Tap(
                    onTap: () {},
                    child: Container(width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: isDark
                            ? kCard.withOpacity(0.5)
                            : const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kGreen.withOpacity(0.3))),
                      child: Icon(Icons.upload_outlined,
                          color: kGreen, size: 26)),
                  ),
                ]))),
              const SizedBox(height: 24),

              // ── Submit button — slide up ──
              SlideTransition(
                position: _btnSlide,
                child: FadeTransition(
                  opacity: _btnFade,
                  child: _Tap(
                    onTap: () => Navigator.push(context,
                        _slideUpRoute(const ReviewSubmittedScreen())),
                    child: Container(
                      width: double.infinity, height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF009689), Color(0xFF00B8DB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(
                            color: kTeal.withOpacity(0.3),
                            blurRadius: 16, offset: const Offset(0, 6))]),
                      alignment: Alignment.center,
                      child: const Text('Submit Review', style: TextStyle(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        )),
      ])),
    );
  }
}

// ══════════════════════════════════════════════════════
//  REVIEW SUBMITTED SCREEN
// ══════════════════════════════════════════════════════
class ReviewSubmittedScreen extends StatefulWidget {
  const ReviewSubmittedScreen({super.key});
  @override
  State<ReviewSubmittedScreen> createState() => _ReviewSubmittedScreenState();
}

class _ReviewSubmittedScreenState extends State<ReviewSubmittedScreen>
    with TickerProviderStateMixin {

  // Check icon — scale bounce (RN: spring scale 0→1)
  late AnimationController _iconCtrl;
  late Animation<double> _iconScale, _iconFade;

  // Glow pulse around check (RN: loop opacity)
  late AnimationController _glowCtrl;
  late Animation<double> _glowOpacity, _glowScale;

  // Text — fade + slide up
  late AnimationController _textCtrl;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  // Mini cards — stagger float in
  late AnimationController _cardsCtrl;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  // Button — slide up
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

    _glowCtrl    = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _glowOpacity = Tween<double>(begin: 0.3, end: 0.7)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowScale   = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _textCtrl  = AnimationController(vsync: this, duration: _kMed);
    _textFade  = CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: _kEaseOutCubic));

    _cardsCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _cardFades = List.generate(3, (i) {
      final s = i * 0.15;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _cardSlides = List.generate(3, (i) {
      // Left card slides from left, center from below, right from right
      final offsets = [const Offset(-0.3, 0.1), const Offset(0, 0.15), const Offset(0.3, 0.1)];
      final s = i * 0.12;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: offsets[i], end: Offset.zero)
          .animate(CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutBack)));
    });

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _runSequence();
  }

  void _runSequence() async {
    _iconCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _iconCtrl.dispose(); _glowCtrl.dispose(); _textCtrl.dispose();
    _cardsCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0A1A24) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0A1628) : Colors.white;
    final kCard2  = isDark ? const Color(0xFF0F2A3A) : const Color(0xFFF0F9F8);
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFFCBFBF1) : const Color(0xFF8A9BB0);
    final kTeal   = const Color(0xFF00D5BE);
    final kGreen  = const Color(0xFF009689);
    final kBorder = isDark ? kTeal.withOpacity(0.15) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            _backBtn(context, isDark, kCard, kTeal, kBorder),
          ])),
        const SizedBox(height: 24),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? kCard.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kBorder),
              boxShadow: isDark ? [] : [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12, offset: const Offset(0, 4))]),
            child: Column(children: [
              const SizedBox(height: 48),

              // ── Check icon — bounce + pulsing glow ──
              ScaleTransition(
                scale: _iconScale,
                child: FadeTransition(
                  opacity: _iconFade,
                  child: AnimatedBuilder(
                    animation: _glowCtrl,
                    builder: (_, child) => Stack(
                      alignment: Alignment.center, children: [
                      // Pulsing glow
                      Opacity(
                        opacity: _glowOpacity.value,
                        child: Transform.scale(
                          scale: _glowScale.value,
                          child: Container(
                            width: 140, height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kTeal.withOpacity(0.15),
                            ),
                          ),
                        ),
                      ),
                      child!,
                    ]),
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF009689), Color(0xFF00B8DB)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                        boxShadow: [BoxShadow(
                            color: kTeal.withOpacity(0.35),
                            blurRadius: 30, spreadRadius: 4)]),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 52)),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              Divider(color: kBorder, height: 1),

              // ── Text — fade + slide ──
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(children: [
                      Text('Thank you for your\nreview!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kText, fontSize: 26,
                              fontWeight: FontWeight.bold, height: 1.3)),
                      const SizedBox(height: 16),
                      Text('You help fellow travellers and\ntraders in discovering the best experiences.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kMuted, fontSize: 15,
                              height: 1.6)),
                    ]),
                  ),
                ),
              ),

              Divider(color: kBorder, height: 1),
              const SizedBox(height: 40),

              // ── Mini cards — stagger float in ──
              SizedBox(width: 180, height: 160,
                child: Stack(alignment: Alignment.center, children: [
                  // Left card
                  Positioned(left: 0, top: 20,
                    child: FadeTransition(
                      opacity: _cardFades[0],
                      child: SlideTransition(
                        position: _cardSlides[0],
                        child: Transform.rotate(angle: -0.15,
                            child: _miniCard(kCard2, kGreen, kTeal, 0.4)),
                      ),
                    )),
                  // Right card
                  Positioned(right: 0, top: 20,
                    child: FadeTransition(
                      opacity: _cardFades[2],
                      child: SlideTransition(
                        position: _cardSlides[2],
                        child: Transform.rotate(angle: 0.15,
                            child: _miniCard(kCard2, kGreen, kTeal, 0.4)),
                      ),
                    )),
                  // Center card
                  FadeTransition(
                    opacity: _cardFades[1],
                    child: SlideTransition(
                      position: _cardSlides[1],
                      child: _miniCard(kCard2, kGreen, kTeal, 1.0),
                    ),
                  ),
                ])),
              const SizedBox(height: 40),

              // ── Button — slide up ──
              SlideTransition(
                position: _btnSlide,
                child: FadeTransition(
                  opacity: _btnFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _Tap(
                      onTap: () => Navigator.push(context,
                          _slideRightRoute(const ReviewsListScreen())),
                      child: Container(
                        width: double.infinity, height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF009689), Color(0xFF00D5BE)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(
                              color: kTeal.withOpacity(0.35),
                              blurRadius: 16, offset: const Offset(0, 6))]),
                        alignment: Alignment.center,
                        child: const Text('View All Reviews',
                            style: TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        )),
      ])),
    );
  }

  Widget _miniCard(Color kCard2, Color kGreen, Color kTeal, double opacity) =>
    Opacity(opacity: opacity,
      child: Container(width: 110, height: 130,
        decoration: BoxDecoration(
          color: kCard2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kTeal.withOpacity(0.2))),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(width: 10, height: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: kGreen))))),
          const SizedBox(height: 12),
          Container(width: double.infinity, height: 6,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 6),
          Container(width: 70, height: 6,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 6),
          Container(width: 50, height: 6,
            decoration: BoxDecoration(color: kGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3))),
        ])));
}

// ══════════════════════════════════════════════════════
//  REVIEWS LIST SCREEN
// ══════════════════════════════════════════════════════
class ReviewsListScreen extends StatefulWidget {
  const ReviewsListScreen({super.key});
  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen>
    with TickerProviderStateMixin {
  static const _reviews = [
    (time: 'Just now', title: 'Excellent service',
     body: 'Very professional driver. Delivered everything on time and in perfect condition.',
     stars: 5, hasPhotos: true, isNew: true),
    (time: '5 days ago', title: 'Good communication',
     body: 'Driver kept me updated throughout the journey. Everything arrived safely.',
     stars: 4, hasPhotos: false, isNew: false),
    (time: '1 week ago', title: 'Outstanding!',
     body: 'Best driver I have worked with. Very careful with the cargo.',
     stars: 5, hasPhotos: true, isNew: false),
    (time: '1 week ago', title: 'Highly professional',
     body: 'Smooth experience from start to finish. Would definitely work with this driver again.',
     stars: 5, hasPhotos: false, isNew: false),
    (time: '2 weeks ago', title: 'Reliable and punctual',
     body: 'Great timing and very easy to communicate with. Handled everything professionally.',
     stars: 4, hasPhotos: false, isNew: false),
  ];

  // Header
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // Driver header card — scale bounce
  late AnimationController _driverCtrl;
  late Animation<double> _driverScale, _driverFade;

  // Button — slide up
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

    _driverCtrl  = AnimationController(vsync: this, duration: _kMed);
    _driverScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _driverCtrl, curve: _kEaseOutBack));
    _driverFade  = CurvedAnimation(parent: _driverCtrl, curve: _kEaseOutCubic);

    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _driverCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _btnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose(); _driverCtrl.dispose(); _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0A1A24) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0A1628) : Colors.white;
    final kCard2  = isDark ? const Color(0xFF0F2A3A) : const Color(0xFFF8FAFB);
    final kText   = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFFCBFBF1) : const Color(0xFF8A9BB0);
    final kTeal   = const Color(0xFF00D5BE);
    final kBorder = isDark ? kTeal.withOpacity(0.15) : const Color(0xFFE2EAF0);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _backBtn(context, isDark, kCard, kTeal, kBorder),
                const SizedBox(width: 14),
                Text('Reviews & Ratings', style: TextStyle(color: kText,
                    fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [

            // ── Driver header card — scale bounce ──
            ScaleTransition(
              scale: _driverScale,
              child: FadeTransition(
                opacity: _driverFade,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? kCard2 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                    boxShadow: isDark ? [] : [BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 64, height: 64,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8904), Color(0xFF9810FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                          border: Border.all(color: kTeal, width: 2)),
                        child: const Center(child: Text('JD',
                            style: TextStyle(color: Colors.white,
                                fontSize: 20, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('John Michael', style: TextStyle(color: kText,
                            fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Professional Driver',
                            style: TextStyle(color: kMuted, fontSize: 13)),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? kCard.withOpacity(0.6)
                            : const Color(0xFFF0F9F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder)),
                      child: Row(children: [
                        Icon(Icons.star_rounded, color: kTeal, size: 24),
                        const SizedBox(width: 8),
                        Text('4.7', style: TextStyle(color: kText,
                            fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 20,
                            color: kTeal.withOpacity(0.3)),
                        const SizedBox(width: 12),
                        Text('128 reviews',
                            style: TextStyle(color: kMuted, fontSize: 14)),
                      ])),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Review cards — staggered ──
            _StaggeredList(
              count: _reviews.length,
              initialDelay: const Duration(milliseconds: 300),
              itemBuilder: (_, i) {
                final r = _reviews[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _reviewTile(r.time, r.title, r.body, r.stars,
                      r.hasPhotos, r.isNew,
                      isDark, kCard2, kText, kMuted, kTeal, kBorder),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Back button — slide up ──
            SlideTransition(
              position: _btnSlide,
              child: FadeTransition(
                opacity: _btnFade,
                child: _Tap(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009689), Color(0xFF00D5BE)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: kTeal.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6))]),
                    alignment: Alignment.center,
                    child: const Text('Back to Shipment',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        )),
      ])),
    );
  }

  Widget _reviewTile(String time, String title, String body,
      int stars, bool hasPhotos, bool isNew,
      bool isDark, Color kCard2, Color kText, Color kMuted,
      Color kTeal, Color kBorder) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? kCard2 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: isDark ? [] : [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1C3449) : const Color(0xFFE8F5F4)),
            child: Center(child: Text('T', style: TextStyle(
                color: isDark ? kMuted.withOpacity(0.6) : kTeal,
                fontSize: 16, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trader', style: TextStyle(color: kText,
                fontSize: 14, fontWeight: FontWeight.w600)),
            Text(time, style: TextStyle(color: kMuted, fontSize: 12)),
          ])),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: kTeal, borderRadius: BorderRadius.circular(20)),
              child: const Text('New', style: TextStyle(
                  color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.bold)))
          else
            Row(children: List.generate(5, (i) => Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < stars ? kTeal : kMuted.withOpacity(0.3),
              size: 18))),
        ]),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(color: kText,
            fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(color: kMuted, fontSize: 13, height: 1.5)),
        if (hasPhotos) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.camera_alt_outlined, color: kTeal, size: 16),
            const SizedBox(width: 6),
            Text('Photos attached',
                style: TextStyle(color: kTeal, fontSize: 13)),
          ]),
        ],
      ]));
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

Route<T> _slideRightRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMed,
  reverseTransitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) {
    final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    return SlideTransition(position: slide,
        child: FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: _kEaseOutCubic),
            child: child));
  },
);

// ══════════════════════════════════════════════════════
//  SHARED HELPERS
// ══════════════════════════════════════════════════════
Widget _backBtn(BuildContext context, bool isDark, Color kCard,
    Color kTeal, Color kBorder) =>
  _Tap(
    onTap: () => Navigator.pop(context),
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder)),
      child: Icon(Icons.arrow_back, color: kTeal, size: 18)));

Widget _buildCard({
  required Widget child,
  required bool isDark,
  required Color kCard,
  required Color kBorder,
}) =>
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder),
      boxShadow: isDark ? [] : [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2))]),
    child: child);
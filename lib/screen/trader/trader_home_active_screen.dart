import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TraderHomeActiveScreen — animations ported 1:1 from DriverHome.tsx (RN)
//
//  RN patterns used:
//  • Header:  initial opacity:0 y:-20 → animate easeOut 500ms
//  •          name + subtitle: x:-10 delay 0.2/0.3s
//  •          Animated underline: width 0→100% delay 0.8s
//  • containerVariants: staggerChildren 0.08s, delayChildren 0.1s
//  • itemVariants: opacity+y(20) spring stiffness:100 damping:15
//  • Background blobs: x[0,30,0] y[0,-20,0] 8/10/9s easeInOut infinite
//  • Current shipment card: opacity+scale(0.95) spring
//  • Active indicator dot: opacity[1,0.4,1] scale[1,1.2,1] 2s infinite
//  • Shimmer on button: x[-300,300] 2s linear infinite
//  • InsightCards: x:-20→0 stagger delay i*0.1s
//  • ActivityCards: whileHover x:4
//  • whileTap scale:0.98 on every button
// ══════════════════════════════════════════════════════════════════════════════

class TraderHomeActiveScreen extends StatefulWidget {
  const TraderHomeActiveScreen({super.key});

  @override
  State<TraderHomeActiveScreen> createState() =>
      _TraderHomeActiveScreenState();
}

class _TraderHomeActiveScreenState extends State<TraderHomeActiveScreen>
    with TickerProviderStateMixin {

  // ── Controllers ──
  late final AnimationController _headerCtrl;   // header y:-20→0
  late final AnimationController _nameCtrl;     // name x:-10→0 + underline
  late final AnimationController _blobCtrl;     // background blobs
  late final AnimationController _cardCtrl;     // shipment card scale spring
  late final AnimationController _dotCtrl;      // active dot pulse
  late final AnimationController _shimmerCtrl;  // button shimmer
  late final List<AnimationController> _itemCtrls; // stagger items

  // ── Animations ──
  late final Animation<double> _headerFade;
  late final Animation<Offset>  _headerSlide;
  late final Animation<double> _nameFade;
  late final Animation<Offset>  _nameSlide;
  late final Animation<double> _underlineWidth; // 0→1
  late final Animation<double> _blobX1, _blobY1;
  late final Animation<double> _blobX2, _blobY2;
  late final Animation<double> _blobX3, _blobY3;
  late final Animation<double> _cardFade, _cardScale;
  late final Animation<double> _dotOpacity, _dotScale;
  late final Animation<double> _shimmerX;
  late final List<Animation<double>> _itemFades;
  late final List<Animation<Offset>>  _itemSlides;

  static const int _itemCount = 6; // header card + insights(3) + activity(2)

  @override
  void initState() {
    super.initState();

    // ── Header: opacity + y -20→0, easeOut 500ms ──
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // ── Name: x -10→0, delay 200ms ──
    _nameCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _nameFade  = CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut);
    _nameSlide = Tween<Offset>(begin: const Offset(-0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));
    // Underline: width 0→1 delay 800ms
    _underlineWidth = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOut));

    // ── Background blobs: x[0,30,0] y[0,-20,0] 8/10/9s easeInOut ──
    _blobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 8000))
      ..repeat(reverse: true);
    _blobX1 = Tween<double>(begin: 0, end: 30)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY1 = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobX2 = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY2 = Tween<double>(begin: 0, end: 30)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobX3 = Tween<double>(begin: 0, end: 20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY3 = Tween<double>(begin: 0, end: -30)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));

    // ── Card: opacity + scale 0.95→1, spring ──
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _cardFade  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardScale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack));

    // ── Active dot: opacity[1,0.4,1] scale[1,1.2,1] 2s infinite ──
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _dotOpacity = Tween<double>(begin: 1.0, end: 0.4)
        .animate(CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));
    _dotScale = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));

    // ── Button shimmer: x[-300,300] 2s linear infinite ──
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(_shimmerCtrl);

    // ── staggerChildren 0.08s (itemVariants: opacity+y spring stiffness:100 damping:15) ──
    _itemCtrls = List.generate(_itemCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500)));
    _itemFades = _itemCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)
            as Animation<double>)
        .toList();
    _itemSlides = _itemCtrls
        .map((c) => Tween<Offset>(
                begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    // ── Stagger start (delayChildren: 0.1s, staggerChildren: 0.08s) ──
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _nameCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _cardCtrl.forward(); });

    for (int i = 0; i < _itemCount; i++) {
      Future.delayed(Duration(milliseconds: 100 + i * 80),
          () { if (mounted) _itemCtrls[i].forward(); });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose(); _nameCtrl.dispose(); _blobCtrl.dispose();
    _cardCtrl.dispose(); _dotCtrl.dispose(); _shimmerCtrl.dispose();
    for (final c in _itemCtrls) { c.dispose(); }
    super.dispose();
  }

  Widget _item(int i, Widget child) {
    final idx = i.clamp(0, _itemSlides.length - 1);
    return SlideTransition(
      position: _itemSlides[idx],
      child: FadeTransition(opacity: _itemFades[idx], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final user   = context.watch<UserProvider>();
    final name   = user.fullName.isNotEmpty ? user.fullName : 'Alex';

    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning'
        : hour < 17 ? 'Good Afternoon' : 'Good Evening';

    final kBg        = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F7FA);
    final kCard      = isDark ? const Color(0xFF0A1628).withOpacity(0.6) : Colors.white;
    final kCardSolid = isDark ? const Color(0xFF112236) : Colors.white;
    final kText      = isDark ? Colors.white : const Color(0xFF0A1628);
    final kMuted     = isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF8A9BB0);
    final kBorder    = isDark
        ? const Color(0xFF00D5BE).withOpacity(0.2)
        : const Color(0xFFE0EAF0);
    const kTeal = Color(0xFF00D5BE);
    const kBlue = Color(0xFF00D3F2);
    final kInner = isDark
        ? const Color(0xFF0A1628).withOpacity(0.4)
        : const Color(0xFFF0F8FA);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kBg,
      body: Stack(children: [

        // ── Animated background blobs (DriverHome pattern) ──
        AnimatedBuilder(
          animation: _blobCtrl,
          builder: (_, __) => Stack(children: [
            // blob 1: top-right amber (x[0,30] y[0,-20] 8s)
            Positioned(
              top: 60 + _blobY1.value,
              right: 10 + _blobX1.value,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withOpacity(0.05),
                ),
              ),
            ),
            // blob 2: center-left teal (x[0,-20] y[0,30] 10s)
            Positioned(
              top: 160 + _blobY2.value,
              left: 10 + _blobX2.value,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kTeal.withOpacity(0.05),
                ),
              ),
            ),
            // blob 3: bottom-right gold (x[0,20] y[0,-30] 9s)
            Positioned(
              bottom: 120 + _blobY3.value,
              right: 20 + _blobX3.value,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFBBF24).withOpacity(0.05),
                ),
              ),
            ),
          ]),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header: opacity + y:-20→0, easeOut 500ms ──
                SlideTransition(
                  position: _headerSlide,
                  child: FadeTransition(
                    opacity: _headerFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        // Name block: x:-10→0 delay 200ms + animated underline
                        SlideTransition(
                          position: _nameSlide,
                          child: FadeTransition(
                            opacity: _nameFade,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(greeting,
                                    style: TextStyle(
                                        color: kMuted, fontSize: 14)),
                                // Name with animated underline
                                Stack(children: [
                                  Text(name,
                                      style: TextStyle(
                                          color: kText,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold)),
                                  // Animated gradient underline (width 0→100% delay 0.8s)
                                  Positioned(
                                    bottom: 0, left: 0,
                                    child: AnimatedBuilder(
                                      animation: _underlineWidth,
                                      builder: (_, __) => Container(
                                        width: _underlineWidth.value *
                                            (name.length * 14.5),
                                        height: 2,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF00D5BE),
                                              Colors.transparent
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                                Text('Shipment in progress',
                                    style: TextStyle(
                                        color: kMuted, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),

                        // Notification bell: scale spring delay 0.4s
                        _TapScaleButton(
                          onTap: () => Navigator.pushNamed(
                              context, '/trader_notifications'),
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: kCard,
                              shape: BoxShape.circle,
                              border: Border.all(color: kBorder, width: 1.5),
                              boxShadow: isDark
                                  ? []
                                  : [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))
                                    ],
                            ),
                            child: const Icon(
                                Icons.notifications_outlined,
                                color: kBlue, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Current Shipment Card: scale 0.95→1 spring ──
                _item(0,
                  ScaleTransition(
                    scale: _cardScale,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: kBorder),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                      color: kTeal.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 6))
                                ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row
                            Row(children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: kBlue.withOpacity(
                                      isDark ? 0.15 : 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.widgets_outlined,
                                    color: kBlue, size: 28)),
                              const SizedBox(width: 14),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Current Shipment',
                                      style: TextStyle(
                                          color: kBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  Text('Driver assigned',
                                      style: TextStyle(
                                          color: kText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                ],
                              )),
                              // Active dot: opacity[1,0.4,1] scale[1,1.2,1] 2s
                              AnimatedBuilder(
                                animation: _dotCtrl,
                                builder: (_, __) => Opacity(
                                  opacity: _dotOpacity.value,
                                  child: Transform.scale(
                                    scale: _dotScale.value,
                                    child: Container(
                                      width: 10, height: 10,
                                      decoration: BoxDecoration(
                                        color: kBlue,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                              color: kBlue.withOpacity(0.4),
                                              blurRadius: 6,
                                              spreadRadius: 1)
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 20),

                            // From → To
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kInner,
                                borderRadius: BorderRadius.circular(16),
                                border: isDark
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFE0EAF0)),
                              ),
                              child: Row(children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('From',
                                        style: TextStyle(
                                            color: kMuted, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('Maadi',
                                        style: TextStyle(
                                            color: kText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      width: 40, height: 2,
                                      decoration: BoxDecoration(
                                          color: kBlue,
                                          borderRadius:
                                              BorderRadius.circular(1)),
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('To',
                                        style: TextStyle(
                                            color: kMuted, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Text('Nasr City',
                                        style: TextStyle(
                                            color: kText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ]),
                            ),
                            const SizedBox(height: 16),

                            // CTA button with shimmer x[-300,300] 2s linear infinite
                            _TapScaleButton(
                              onTap: () {},
                              child: Container(
                                width: double.infinity, height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF17D4B4),
                                      Color(0xFF0E8FD4)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                        color: kTeal.withOpacity(0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6))
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Shimmer sweep
                                      AnimatedBuilder(
                                        animation: _shimmerX,
                                        builder: (_, __) => Positioned(
                                          left: _shimmerX.value - 40,
                                          top: 0, bottom: 0,
                                          child: Container(
                                            width: 80,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white
                                                      .withOpacity(0.2),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Text('Continue Setup',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Quick Insights: staggered x:-20→0 i*0.1s ──
                _item(1,
                  Text('Quick Insights',
                      style: TextStyle(
                          color: kText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item(2, _InsightCard(
                        icon: Icons.access_time_outlined,
                        label: 'Avg Time', value: '4.2h',
                        isDark: isDark, kCard: kCardSolid, kText: kText,
                        kMuted: kMuted, kBorder: kBorder, kTeal: kTeal)),
                    _item(3, _InsightCard(
                        icon: Icons.trending_up,
                        label: 'Avg Cost', value: '\$280',
                        isDark: isDark, kCard: kCardSolid, kText: kText,
                        kMuted: kMuted, kBorder: kBorder, kTeal: kTeal)),
                    _item(4, _InsightCard(
                        icon: Icons.widgets_outlined,
                        label: 'Completed', value: '47',
                        isDark: isDark, kCard: kCardSolid, kText: kText,
                        kMuted: kMuted, kBorder: kBorder, kTeal: kTeal)),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Recent Activity: staggered + whileHover x:4 ──
                _item(5,
                  Text('Recent Activity',
                      style: TextStyle(
                          color: kText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 14),

                _HoverSlideCard(
                  child: _ActivityCard(
                      route: 'Maadi → Nasr City', date: 'Dec 20',
                      isDark: isDark, kCard: kCardSolid, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal),
                ),
                const SizedBox(height: 10),
                _HoverSlideCard(
                  child: _ActivityCard(
                      route: 'Zayed → October', date: 'Dec 18',
                      isDark: isDark, kCard: kCardSolid, kText: kText,
                      kMuted: kMuted, kBorder: kBorder, kTeal: kTeal),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _InsightCard
// ══════════════════════════════════════════════════════════════════════════════
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder, kTeal;

  const _InsightCard({
    required this.icon, required this.label, required this.value,
    required this.isDark, required this.kCard, required this.kText,
    required this.kMuted, required this.kBorder, required this.kTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 101,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: isDark ? 1 : 1.5),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: kTeal.withOpacity(isDark ? 0.15 : 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kTeal, size: 18)),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: kMuted, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: kText, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _ActivityCard
// ══════════════════════════════════════════════════════════════════════════════
class _ActivityCard extends StatelessWidget {
  final String route, date;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder, kTeal;

  const _ActivityCard({
    required this.route, required this.date,
    required this.isDark, required this.kCard, required this.kText,
    required this.kMuted, required this.kBorder, required this.kTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: isDark ? 1 : 1.5),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(route,
                style: TextStyle(
                    color: kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(date, style: TextStyle(color: kMuted, fontSize: 12)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kTeal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: kTeal.withOpacity(0.4), width: 1),
            ),
            child: Text('Delivered',
                style: TextStyle(
                    color: kTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _HoverSlideCard — whileHover x:4 (RN pattern)
// ══════════════════════════════════════════════════════════════════════════════
class _HoverSlideCard extends StatefulWidget {
  final Widget child;
  const _HoverSlideCard({required this.child});

  @override
  State<_HoverSlideCard> createState() => _HoverSlideCardState();
}

class _HoverSlideCardState extends State<_HoverSlideCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0.01, 0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => _ctrl.forward(),
        onExit:  (_) => _ctrl.reverse(),
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TapScaleButton — whileTap scale:0.98 (exact RN pattern)
// ══════════════════════════════════════════════════════════════════════════════
class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapScaleButton({required this.child, required this.onTap});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown:   (_) => _ctrl.forward(),
        onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}
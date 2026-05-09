// ════════════════════════════════════════════════════════════
//  driver_earnings_screen.dart  — Full Animations
// ════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/driver_provider.dart';
import '/providers/theme_provider.dart';
import '/models/driver_models.dart';

const Color _kTeal  = Color(0xFF00D5BE);
const Color _kAmber = Color(0xFFF59E0B);

// ══════════════════════════════════════════════════════
//  EARNINGS SCREEN
// ══════════════════════════════════════════════════════
class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});
  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen>
    with TickerProviderStateMixin {

  int _tab = 0;

  // Card entrance
  late AnimationController _cardCtrl;
  late Animation<double> _cardAnim;

  // Ring progress
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  // Tab active bg (layoutId equivalent)
  // Shimmer on main card
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // Stagger items
  late AnimationController _staggerCtrl;
  late List<Animation<double>> _items;

  // Bottom sheet spring
  bool _breakdownOpen = false;

  @override
  void initState() {
    super.initState();

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _cardAnim = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic);

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _staggerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _items = List.generate(8, (i) {
      final s = (i * 0.1).clamp(0.0, 0.8);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _staggerCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  void _switchTab(int i) {
    setState(() => _tab = i);
    _cardCtrl.forward(from: 0);
    _ringCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _ringCtrl.dispose();
    _shimmerCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  _EarningsData _getData(DriverProvider driver) {
    final stats = driver.todayStats;
    switch (_tab) {
      case 0: return _EarningsData(
        label: 'Today Earnings', amount: stats.earnings.toInt(),
        comparison: 'You earned 22% more than yesterday',
        payoutLabel: 'Next payout in 2 days',
        target: 1500, current: stats.earnings.toInt(),
        baseFare: (stats.earnings * 0.6).toInt(),
        distanceBonus: (stats.earnings * 0.25).toInt(),
        peakHours: (stats.earnings * 0.15).toInt(),
        tips: (stats.earnings * 0.08).toInt(),
        deductions: (stats.earnings * 0.03).toInt(),
      );
      case 1: return const _EarningsData(
        label: 'This Week Earnings', amount: 4800,
        comparison: 'You earned 18% more than last week',
        payoutLabel: 'Next payout in 2 days',
        target: 7000, current: 4800,
        baseFare: 2880, distanceBonus: 1200, peakHours: 720, tips: 384, deductions: 144,
      );
      default: return const _EarningsData(
        label: 'This Month Earnings', amount: 12300,
        comparison: 'You earned 15% more than last month',
        payoutLabel: 'Monthly payout on Dec 30',
        target: 18000, current: 12300,
        baseFare: 7380, distanceBonus: 3075, peakHours: 1845, tips: 984, deductions: 369,
      );
    }
  }

  Widget _a(int i, Widget child) {
    final anim = _items[i.clamp(0, _items.length - 1)];
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, 20 * (1 - anim.value)), child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final driver = context.watch<DriverProvider>();
    final d = t.isDark;
    final data = _getData(driver);
    final pct = (data.current / data.target).clamp(0.0, 1.0);
    final remaining = (data.target - data.current).clamp(0, 999999);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          _a(0, Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Earnings', style: TextStyle(
                  color: t.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Your income summary',
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: t.card, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.border)),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _kTeal, size: 16)),
            ),
          ])),
          const SizedBox(height: 22),

          // Main earnings card (fade + slide up)
          _a(1, FadeTransition(
            opacity: _cardAnim,
            child: SlideTransition(
              position: Tween<Offset>(
                  begin: const Offset(0, 0.08), end: Offset.zero).animate(_cardAnim),
              child: _buildMainCard(data, d),
            ),
          )),
          const SizedBox(height: 20),

          // Tabs (layoutId spring)
          _a(2, _buildTabs(d, t)),
          const SizedBox(height: 16),

          // Progress ring card
          _a(3, FadeTransition(
            opacity: _cardAnim,
            child: _buildProgressCard(data, pct, remaining, d, t),
          )),
          const SizedBox(height: 16),

          // View History button
          _a(4, _buildHistoryBtn(context)),
          const SizedBox(height: 12),

          // Breakdown button
          _a(5, _buildBreakdownBtn(context, data, t)),
        ]),
      )),

      // Bottom sheet backdrop + sheet
      bottomSheet: _breakdownOpen
          ? _CalculationSheet(
              data: data, theme: t,
              onClose: () => setState(() => _breakdownOpen = false),
            )
          : null,
    );
  }

  Widget _buildMainCard(_EarningsData data, bool d) {
    return Stack(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF00B4A0), Color(0xFF00D5BE), Color(0xFF00C8E8)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 22)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(data.payoutLabel, style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Text(data.label, style: TextStyle(
              color: Colors.white.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 6),
          // Animated amount (scale spring)
          AnimatedBuilder(
            animation: _cardAnim,
            builder: (_, __) => Transform.scale(
              scale: 0.8 + 0.2 * _cardAnim.value,
              alignment: Alignment.centerLeft,
              child: Text('${_fmt(data.amount)} EGP',
                  style: const TextStyle(color: Colors.white, fontSize: 38,
                      fontWeight: FontWeight.w800, letterSpacing: -1)),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _cardAnim,
            builder: (_, child) => Opacity(
              opacity: _cardAnim.value, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
              child: Text(data.comparison,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ]),
      ),
      // Shimmer on card
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedBuilder(
          animation: _shimmerAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(_shimmerAnim.value * 300, 0),
            child: Container(
              width: 80, height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.white10, Colors.transparent],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildTabs(bool d, AppTheme t) {
    const labels = ['Today', 'This Week', 'This Month'];
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: t.card, borderRadius: BorderRadius.circular(14),
        boxShadow: t.cardShadow),
      child: Stack(children: [
        // Animated active background (layoutId spring)
        AnimatedAlign(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment(_tab == 0 ? -1 : _tab == 1 ? 0 : 1, 0),
          child: FractionallySizedBox(
            widthFactor: 1 / 3,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _kTeal, borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        Row(children: List.generate(3, (i) => Expanded(
          child: GestureDetector(
            onTap: () => _switchTab(i),
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              child: Text(labels[i], style: TextStyle(
                color: _tab == i ? Colors.white : t.textMuted,
                fontSize: 13,
                fontWeight: _tab == i ? FontWeight.w700 : FontWeight.w400)),
            ),
          ),
        ))),
      ]),
    );
  }

  Widget _buildProgressCard(
      _EarningsData data, double pct, int remaining, bool d, AppTheme t) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.card, borderRadius: BorderRadius.circular(18),
        boxShadow: t.cardShadow, border: Border.all(color: t.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Target Progress', style: TextStyle(color: t.textMuted, fontSize: 13)),
          const Spacer(),
          Text('Target', style: TextStyle(color: t.textMuted, fontSize: 12)),
          const SizedBox(width: 6),
          Text('${_fmt(data.target)} EGP', style: const TextStyle(
              color: _kTeal, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text('${(pct * 100).round()}% Complete',
            style: TextStyle(color: t.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),

        // Animated ring
        Center(child: AnimatedBuilder(
          animation: _ringAnim,
          builder: (_, __) => SizedBox(
            width: 180, height: 180,
            child: CustomPaint(
              painter: _RingPainter(
                progress: pct * _ringAnim.value,
                primaryColor: _kTeal,
                bgColor: d ? Colors.white12 : const Color(0xFFB2DFDB),
              ),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _ringAnim,
                  builder: (_, __) => Text(
                    _fmt((data.current * _ringAnim.value).toInt()),
                    style: TextStyle(color: t.textPrimary, fontSize: 32,
                        fontWeight: FontWeight.w800)),
                ),
                Text('Current', style: TextStyle(color: t.textMuted, fontSize: 13)),
              ])),
            ),
          ),
        )),
        const SizedBox(height: 16),

        Center(child: Text(
          remaining > 0
              ? '${_fmt(remaining)} EGP remaining to reach target'
              : '🎉 Target reached!',
          style: TextStyle(color: t.textMuted, fontSize: 13),
        )),
      ]),
    );
  }

  Widget _buildHistoryBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/driver_earnings_history'),
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00B4A0), Color(0xFF00C8E8)],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View Earnings History', style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
        ]),
      ),
    );
  }

  Widget _buildBreakdownBtn(BuildContext context, _EarningsData data, AppTheme t) {
    return GestureDetector(
      onTap: () {
        if (Navigator.canPop(context)) {
          Navigator.pushNamed(context, '/driver_earnings_breakdown');
        } else {
          setState(() => _breakdownOpen = true);
        }
      },
      child: Container(
        width: double.infinity, height: 50,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kTeal.withOpacity(0.3)),
          boxShadow: t.cardShadow),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.info_outline_rounded, color: _kTeal, size: 18),
          SizedBox(width: 8),
          Text('How this was calculated',
              style: TextStyle(color: _kTeal, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════
//  CALCULATION BOTTOM SHEET  (spring y:'100%'→0)
// ══════════════════════════════════════════════════════
class _CalculationSheet extends StatefulWidget {
  final _EarningsData data;
  final AppTheme theme;
  final VoidCallback onClose;
  const _CalculationSheet({
    required this.data, required this.theme, required this.onClose});
  @override
  State<_CalculationSheet> createState() => _CalculationSheetState();
}

class _CalculationSheetState extends State<_CalculationSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late List<Animation<double>> _rows;

  @override
  void initState() {
    super.initState();
    // Spring: damping:35, stiffness:400
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _slideAnim = Tween<Offset>(
        begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const SpringCurve(damping: 35, stiffness: 400)));

    _rows = List.generate(5, (i) {
      final s = (0.2 + i * 0.08).clamp(0.0, 0.85);
      final e = (s + 0.3).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final d = t.isDark;
    final items = [
      ('Base Fare', widget.data.baseFare, 0.65),
      ('Distance Bonus', widget.data.distanceBonus, 0.25),
      ('Peak Hours', widget.data.peakHours, 0.10),
    ];

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                decoration: BoxDecoration(
                  color: t.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26))),
                child: Column(mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Handle
                  Center(child: AnimatedBuilder(
                    animation: _rows[0],
                    builder: (_, __) => Transform.scale(
                      scaleX: _rows[0].value,
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: d ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(99))),
                    ),
                  )),
                  const SizedBox(height: 20),
                  Text('Calculation Breakdown', style: TextStyle(
                      color: t.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('How your earnings were calculated',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  ...items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value;
                    return AnimatedBuilder(
                      animation: _rows[i + 1],
                      builder: (_, child) => Opacity(
                        opacity: _rows[i + 1].value,
                        child: Transform.translate(
                            offset: Offset(-20 * (1 - _rows[i + 1].value), 0),
                            child: child),
                      ),
                      child: _BreakdownRow(
                        label: item.$1, amount: item.$2,
                        barPct: item.$3, theme: t),
                    );
                  }),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.card, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.border)),
                    child: Row(children: [
                      Text('Net Earnings', style: TextStyle(
                          color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text('${_fmt(widget.data.amount)} EGP',
                          style: const TextStyle(
                              color: _kTeal, fontSize: 18, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Breakdown row with animated progress bar
class _BreakdownRow extends StatefulWidget {
  final String label;
  final int amount;
  final double barPct;
  final AppTheme theme;
  const _BreakdownRow({required this.label, required this.amount,
      required this.barPct, required this.theme});
  @override
  State<_BreakdownRow> createState() => _BreakdownRowState();
}

class _BreakdownRowState extends State<_BreakdownRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800))..forward();
    _anim = Tween<double>(begin: 0, end: widget.barPct).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border), boxShadow: t.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.label, style: TextStyle(color: t.textMuted, fontSize: 13)),
          const Spacer(),
          Text('${_fmt(widget.amount)} EGP',
              style: const TextStyle(color: _kTeal, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _anim.value,
              minHeight: 5,
              backgroundColor: t.isDark ? Colors.white12 : const Color(0xFFB2DFDB),
              valueColor: const AlwaysStoppedAnimation<Color>(_kTeal),
            ),
          ),
        ),
      ]),
    );
  }
}


// ══════════════════════════════════════════════════════
//  EARNINGS HISTORY SCREEN
// ══════════════════════════════════════════════════════
class DriverEarningsHistoryScreen extends StatefulWidget {
  const DriverEarningsHistoryScreen({super.key});
  @override
  State<DriverEarningsHistoryScreen> createState() => _EarningsHistoryState();
}

class _EarningsHistoryState extends State<DriverEarningsHistoryScreen>
    with SingleTickerProviderStateMixin {
  int _filter = 0;

  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() { _listCtrl.dispose(); super.dispose(); }

  static const _allTrips = [
    _TripItem(route: 'Maadi → Nasr City', date: 'Dec 16, 2025', ref: 'TR-4721', amount: 850, isPaid: true),
    _TripItem(route: 'Downtown → Heliopolis', date: 'Dec 16, 2025', ref: 'TR-4720', amount: 620, isPaid: true),
    _TripItem(route: 'Zamalek → New Cairo', date: 'Dec 15, 2025', ref: 'TR-4719', amount: 1150, isPaid: false),
    _TripItem(route: '6th October → Maadi', date: 'Dec 15, 2025', ref: 'TR-4718', amount: 730, isPaid: true),
    _TripItem(route: 'Nasr City → Dokki', date: 'Dec 14, 2025', ref: 'TR-4717', amount: 540, isPaid: true),
    _TripItem(route: 'Heliopolis → Sheikh Zayed', date: 'Dec 14, 2025', ref: 'TR-4716', amount: 920, isPaid: false),
    _TripItem(route: 'Mohandessin → New Cairo', date: 'Dec 13, 2025', ref: 'TR-4715', amount: 1080, isPaid: true),
  ];

  List<_TripItem> get filtered {
    if (_filter == 1) return _allTrips.where((t) => t.isPaid).toList();
    if (_filter == 2) return _allTrips.where((t) => !t.isPaid).toList();
    return _allTrips;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    final d = t.isDark;
    final list = filtered;
    final total = list.fold(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: t.card, borderRadius: BorderRadius.circular(12),
                  boxShadow: t.cardShadow),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: t.textPrimary, size: 18)),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Earnings History', style: TextStyle(
                  color: t.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Completed trips & payouts',
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 20),

          // Filter tabs (layoutId spring)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: t.card, borderRadius: BorderRadius.circular(14),
              boxShadow: t.cardShadow),
            child: Stack(children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: Alignment(
                    _filter == 0 ? -1 : _filter == 1 ? 0 : 1, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / 3,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF009689), Color(0xFF00B8DB)]),
                      borderRadius: BorderRadius.circular(10))),
                ),
              ),
              Row(children: List.generate(3, (i) {
                final labels = ['All', 'Paid', 'Pending'];
                return Expanded(child: GestureDetector(
                  onTap: () {
                    setState(() => _filter = i);
                    _listCtrl.forward(from: 0);
                  },
                  child: Container(color: Colors.transparent,
                    alignment: Alignment.center,
                    child: Text(labels[i], style: TextStyle(
                      color: _filter == i ? Colors.white : t.textMuted,
                      fontSize: 13,
                      fontWeight: _filter == i ? FontWeight.w700 : FontWeight.w400))),
                ));
              })),
            ]),
          ),
          const SizedBox(height: 16),

          // Total summary (animated amount)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_filter),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kTeal.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kTeal.withOpacity(0.2))),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _filter == 0 ? 'Total Earnings'
                        : _filter == 1 ? 'Total Paid' : 'Total Pending',
                    style: TextStyle(color: t.textMuted, fontSize: 12)),
                  Text('${_fmt(total)} EGP',
                      style: const TextStyle(color: _kTeal, fontSize: 28, fontWeight: FontWeight.w800)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('Total Trips', style: TextStyle(color: t.textMuted, fontSize: 12)),
                  Text('${list.length}',
                      style: TextStyle(color: t.textPrimary, fontSize: 20)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // List with AnimatePresence popLayout equivalent
          Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: list.isEmpty
                ? Center(key: const ValueKey('empty'),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox_outlined, color: t.textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text('No trips found',
                          style: TextStyle(color: t.textMuted, fontSize: 16)),
                    ]))
                : ListView.separated(
                    key: ValueKey('list_$_filter'),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final delay = i * 0.06;
                      return AnimatedBuilder(
                        animation: _listCtrl,
                        builder: (_, child) {
                          final t2 = (((_listCtrl.value - delay) / 0.4)
                              .clamp(0.0, 1.0));
                          final curve = Curves.easeOutCubic.transform(t2);
                          return Opacity(
                            opacity: curve,
                            child: Transform.translate(
                                offset: Offset(0, 20 * (1 - curve)),
                                child: child),
                          );
                        },
                        child: _TripTile(trip: list[i], theme: t),
                      );
                    },
                  ),
          )),
        ]),
      )),
    );
  }
}

class _TripItem {
  final String route, date, ref;
  final int amount;
  final bool isPaid;
  const _TripItem({required this.route, required this.date,
      required this.ref, required this.amount, required this.isPaid});
}

class _TripTile extends StatefulWidget {
  final _TripItem trip;
  final AppTheme theme;
  const _TripTile({required this.trip, required this.theme});
  @override
  State<_TripTile> createState() => _TripTileState();
}

class _TripTileState extends State<_TripTile> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border), boxShadow: t.cardShadow),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.trip.route, style: TextStyle(
                  color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(children: [
                Text(widget.trip.date, style: TextStyle(color: t.textMuted, fontSize: 12)),
                const SizedBox(width: 8),
                Container(width: 4, height: 4,
                    decoration: BoxDecoration(color: t.textMuted, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(widget.trip.ref, style: TextStyle(color: t.textMuted, fontSize: 12)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('+${_fmt(widget.trip.amount)} EGP',
                  style: const TextStyle(
                      color: _kTeal, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.trip.isPaid
                      ? _kTeal.withOpacity(0.15)
                      : const Color(0xFFFF8904).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(
                  widget.trip.isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    color: widget.trip.isPaid ? _kTeal : const Color(0xFFFF8904),
                    fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════
//  EARNINGS BREAKDOWN SCREEN
// ══════════════════════════════════════════════════════
class DriverEarningsBreakdownScreen extends StatefulWidget {
  const DriverEarningsBreakdownScreen({super.key});
  @override
  State<DriverEarningsBreakdownScreen> createState() => _EarningsBreakdownState();
}

class _EarningsBreakdownState extends State<DriverEarningsBreakdownScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late List<Animation<double>> _anims;

  static const _factors = [
    _Factor('18 trips this week', Icons.location_on_outlined,
        '8,460 EGP total from completed trips', 'Contribution', 1.0, '100%'),
    _Factor('Long-distance trips', Icons.bolt_outlined,
        '5,200 EGP from trips over 20km', 'Most earnings came from these', 0.61, '61%'),
    _Factor('Weekend earnings', Icons.access_time_outlined,
        '3,100 EGP earned on weekends', 'You earn more on weekends', 0.37, '37%'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..forward();
    _anims = List.generate(_factors.length, (i) {
      final s = i * 0.15;
      return CurvedAnimation(parent: _ctrl,
          curve: Interval(s, (s + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: t.card, borderRadius: BorderRadius.circular(12),
                  boxShadow: t.cardShadow),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: t.textPrimary, size: 18)),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Earnings Breakdown', style: TextStyle(
                  color: t.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
              Text('Where your money comes from',
                  style: TextStyle(color: t.textMuted, fontSize: 13)),
            ]),
          ]),
          const SizedBox(height: 22),

          // Primary metric card
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(scale: 0.95 + 0.05 * v, child: child)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.card, borderRadius: BorderRadius.circular(18),
                boxShadow: t.cardShadow, border: Border.all(color: t.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Primary Metric', style: TextStyle(color: t.textMuted, fontSize: 12)),
                    Text('Average Earnings per Trip', style: TextStyle(
                        color: t.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    const Text('470 EGP', style: TextStyle(
                        color: _kTeal, fontSize: 38, fontWeight: FontWeight.w800)),
                  ])),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _kTeal.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.trending_up_rounded, color: _kTeal, size: 20)),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.isDark ? const Color(0xFF0F2334) : const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(12)),
                  child: Text('This is 18% higher than the platform average',
                      style: TextStyle(color: t.textMuted, fontSize: 13)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 22),

          Text('CONTRIBUTING FACTORS', style: TextStyle(
              color: t.textMuted, fontSize: 11,
              letterSpacing: 1.4, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),

          // Animated factor cards (stagger + slide from left)
          ...List.generate(_factors.length, (i) {
            final f = _factors[i];
            return FadeTransition(
              opacity: _anims[i],
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(_anims[i]),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: t.card, borderRadius: BorderRadius.circular(16),
                    boxShadow: t.cardShadow, border: Border.all(color: t.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: _kTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10)),
                        child: Icon(f.icon, color: _kTeal, size: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.title, style: TextStyle(
                            color: t.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                        Text(f.subtitle, style: TextStyle(color: t.textMuted, fontSize: 11)),
                      ])),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text(f.barLabel, style: TextStyle(color: t.textMuted, fontSize: 12)),
                      const Spacer(),
                      Text(f.pctLabel, style: const TextStyle(
                          color: _kTeal, fontSize: 13, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    // Animated progress bar
                    AnimatedBuilder(
                      animation: _anims[i],
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: f.barValue * _anims[i].value,
                          minHeight: 5,
                          backgroundColor: t.isDark ? Colors.white12 : const Color(0xFFB2DFDB),
                          valueColor: const AlwaysStoppedAnimation<Color>(_kTeal),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),

          const SizedBox(height: 4),

          // Key Insight card
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
            builder: (_, v, child) => Opacity(opacity: v,
                child: Transform.translate(
                    offset: Offset(0, 20 * (1 - v)), child: child)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.card, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kTeal.withOpacity(0.2)),
                boxShadow: t.cardShadow),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kTeal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.trending_up_rounded, color: _kTeal, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('KEY INSIGHT', style: TextStyle(
                      color: _kTeal, fontSize: 11,
                      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 6),
                  Text('Most of your earnings came from long-distance trips during peak hours',
                      style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Consider accepting more trips over 20km for higher earnings',
                      style: TextStyle(color: t.textMuted, fontSize: 12)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/driver_earnings_history'),
            child: Container(
              width: double.infinity, height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00B4A0), Color(0xFF00C8E8)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(16)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('See full trip breakdown', style: TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
              ]),
            ),
          ),
        ]),
      )),
    );
  }
}

class _Factor {
  final String title, subtitle, barLabel, pctLabel;
  final IconData icon;
  final double barValue;
  const _Factor(this.title, this.icon, this.subtitle,
      this.barLabel, this.barValue, this.pctLabel);
}


// ══════════════════════════════════════════════════════
//  RING PAINTER
// ══════════════════════════════════════════════════════
class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor, bgColor;
  const _RingPainter({required this.progress,
      required this.primaryColor, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radius = min(cx, cy) - 14;
    const stroke = 14.0;
    canvas.drawCircle(Offset(cx, cy), radius,
        Paint()..color = bgColor..style = PaintingStyle.stroke
          ..strokeWidth = stroke..strokeCap = StrokeCap.round);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -pi / 2, 2 * pi * progress, false,
      Paint()..color = primaryColor..style = PaintingStyle.stroke
        ..strokeWidth = stroke..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}


// ══════════════════════════════════════════════════════
//  SPRING CURVE
// ══════════════════════════════════════════════════════
class SpringCurve extends Curve {
  final double damping, stiffness;
  const SpringCurve({this.damping = 35, this.stiffness = 400});

  @override
  double transformInternal(double t) {
    final beta = damping / (2 * sqrt(stiffness));
    if (beta < 1) {
      final omega = sqrt(stiffness) * sqrt(1 - beta * beta);
      return 1 - exp(-beta * sqrt(stiffness) * t) *
          (cos(omega * t) + (beta * sqrt(stiffness) / omega) * sin(omega * t));
    }
    return 1 - (1 + sqrt(stiffness) * t) * exp(-sqrt(stiffness) * t);
  }
}


// ══════════════════════════════════════════════════════
//  DATA + HELPERS
// ══════════════════════════════════════════════════════
class _EarningsData {
  final String label, comparison, payoutLabel;
  final int amount, target, current;
  final int baseFare, distanceBonus, peakHours, tips, deductions;
  const _EarningsData({
    required this.label, required this.amount,
    required this.comparison, required this.payoutLabel,
    required this.target, required this.current,
    required this.baseFare, required this.distanceBonus,
    required this.peakHours, required this.tips, required this.deductions,
  });
}

String _fmt(int n) {
  if (n >= 1000) {
    final s = n.toString();
    final buf = StringBuffer();
    final mod = s.length % 3;
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (i - mod) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
  return n.toString();
}
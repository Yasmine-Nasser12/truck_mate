import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════
//  TRADER NOTIFICATIONS SCREEN — with RN-matching animations
// ══════════════════════════════════════════════════════

// ── Animation constants ──
const Duration _kFast    = Duration(milliseconds: 300);
const Duration _kMed     = Duration(milliseconds: 500);
const Duration _kStagger = Duration(milliseconds: 90);
const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;

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
    _s = Tween<double>(begin: 1.0, end: 0.97)
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

// ══════════════════════════════════════════════════════
//  DATA
// ══════════════════════════════════════════════════════
enum _NotifType { actionRequired, update, completed }

class _TraderNotif {
  final String? time;
  final String group, badge, title, body, btnText;
  final _NotifType type;
  final IconData icon;
  const _TraderNotif({
    this.time, required this.group, required this.type,
    required this.badge, required this.icon,
    required this.title, required this.body, required this.btnText,
  });
}

const _kNotifs = [
  _TraderNotif(
    time: '2:45 PM', group: 'Today',
    type: _NotifType.actionRequired, badge: 'Action Required',
    icon: Icons.check_circle_outline_rounded,
    title: 'Driver accepted shipment',
    body: 'Driver Ahmed has accepted your shipment #SH-4521 from Cairo to Alexandria',
    btnText: 'Track Shipment'),
  _TraderNotif(
    time: '11:20 AM', group: 'Today',
    type: _NotifType.update, badge: 'Update',
    icon: Icons.inventory_2_outlined,
    title: 'Shipment in transit',
    body: 'Your shipment #SH-4518 is now on the way to Giza. Expected delivery: 3:00 PM',
    btnText: 'Track Shipment'),
  _TraderNotif(
    time: null, group: 'Earlier',
    type: _NotifType.completed, badge: 'Completed',
    icon: Icons.description_outlined,
    title: 'Invoice generated',
    body: 'Invoice #INV-8845 for 850 EGP is ready. Payment processed successfully',
    btnText: 'View Invoice'),
  _TraderNotif(
    time: '2 days ago', group: 'Earlier',
    type: _NotifType.completed, badge: 'Completed',
    icon: Icons.attach_money_rounded,
    title: 'Payment completed',
    body: 'Payment of 1,200 EGP has been processed for shipment #SH-4507',
    btnText: 'View Invoice'),
];

// ══════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════
class TraderNotificationsScreen extends StatefulWidget {
  const TraderNotificationsScreen({super.key});
  @override
  State<TraderNotificationsScreen> createState() =>
      _TraderNotificationsScreenState();
}

class _TraderNotificationsScreenState extends State<TraderNotificationsScreen>
    with TickerProviderStateMixin {

  // ── Title — fade + slide down (RN: Animated.timing translateY) ──
  late AnimationController _titleCtrl;
  late Animation<double>   _titleFade;
  late Animation<Offset>   _titleSlide;

  // ── Section headers — staggered fade ──
  late AnimationController _sectCtrl;
  late Animation<double>   _todayHeaderFade;
  late Animation<double>   _earlierHeaderFade;

  // ── Notification cards — staggered slide up (RN: Stagger + spring) ──
  // Today: 2 cards, Earlier: 2 cards = 4 total
  late AnimationController _cardsCtrl;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  // ── Timeline dots — scale bounce on appear ──
  late List<AnimationController> _dotCtrls;
  late List<Animation<double>>   _dotScales;

  // ── Action buttons — fade in after card ──
  late AnimationController _btnsCtrl;
  late List<Animation<double>> _btnFades;

  static const int _kTotal = 4;

  Color _typeColor(_NotifType t) {
    switch (t) {
      case _NotifType.actionRequired: return const Color(0xFFFF8904);
      case _NotifType.update:         return const Color(0xFF3B82F6);
      case _NotifType.completed:      return const Color(0xFF00D5BE);
    }
  }

  @override
  void initState() {
    super.initState();

    // Title
    _titleCtrl  = AnimationController(vsync: this, duration: _kMed);
    _titleFade  = CurvedAnimation(parent: _titleCtrl, curve: _kEaseOutCubic);
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: _kEaseOutCubic));

    // Section headers
    _sectCtrl = AnimationController(vsync: this, duration: _kMed);
    _todayHeaderFade   = CurvedAnimation(parent: _sectCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _earlierHeaderFade = CurvedAnimation(parent: _sectCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut));

    // Cards stagger
    final totalMs = 400 + _kTotal * _kStagger.inMilliseconds;
    _cardsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));

    _cardFades = List.generate(_kTotal, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.45).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _cardSlides = List.generate(_kTotal, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    // Timeline dots — each bounces in with slight delay
    _dotCtrls = List.generate(_kTotal, (_) =>
        AnimationController(vsync: this,
            duration: const Duration(milliseconds: 400)));
    _dotScales = _dotCtrls.map((c) =>
        Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: _kEaseOutBack)))
        .toList();

    // Buttons — fade after their card
    final btnTotalMs = 400 + _kTotal * _kStagger.inMilliseconds + 200;
    _btnsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: btnTotalMs));
    _btnFades = List.generate(_kTotal, (i) {
      final s = ((i * _kStagger.inMilliseconds) + 200) / btnTotalMs;
      final e = (s + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _btnsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _runSequence();
  }

  void _runSequence() async {
    // Title slides in first
    _titleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    // Section headers fade
    _sectCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    // Cards stagger in
    _cardsCtrl.forward();
    _btnsCtrl.forward();
    // Dots bounce in one by one
    for (int i = 0; i < _kTotal; i++) {
      await Future.delayed(Duration(
          milliseconds: 100 + i * _kStagger.inMilliseconds));
      if (mounted) _dotCtrls[i].forward();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sectCtrl.dispose();
    _cardsCtrl.dispose();
    _btnsCtrl.dispose();
    for (final c in _dotCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kBg    = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFEFF6F5);
    final kText  = isDark ? Colors.white : const Color(0xFF0A1628);
    final kMuted = isDark
        ? Colors.white.withOpacity(0.45)
        : const Color(0xFF8A9BB0);

    final today   = _kNotifs.asMap().entries.where((e) => e.value.group == 'Today').toList();
    final earlier = _kNotifs.asMap().entries.where((e) => e.value.group == 'Earlier').toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── [0] Title — fade + slide down ──
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: Text('Notifications',
                    style: TextStyle(color: kText, fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            // ── [1] "Today" header — fade ──
            FadeTransition(
              opacity: _todayHeaderFade,
              child: Text('Today',
                  style: TextStyle(color: kMuted, fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // ── Today cards ──
            ...today.map((e) {
              final i = e.key;
              return _AnimatedNotifItem(
                notif: e.value,
                isDark: isDark,
                kText: kText,
                kMuted: kMuted,
                typeColor: _typeColor(e.value.type),
                isLast: i == today.last.key,
                cardFade: _cardFades[i],
                cardSlide: _cardSlides[i],
                dotScale: _dotScales[i],
                btnFade: _btnFades[i],
              );
            }),

            const SizedBox(height: 24),

            // ── [2] "Earlier" header — fade ──
            FadeTransition(
              opacity: _earlierHeaderFade,
              child: Text('Earlier',
                  style: TextStyle(color: kMuted, fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),

            // ── Earlier cards ──
            ...earlier.map((e) {
              final i = e.key;
              return _AnimatedNotifItem(
                notif: e.value,
                isDark: isDark,
                kText: kText,
                kMuted: kMuted,
                typeColor: _typeColor(e.value.type),
                isLast: i == earlier.last.key,
                cardFade: _cardFades[i],
                cardSlide: _cardSlides[i],
                dotScale: _dotScales[i],
                btnFade: _btnFades[i],
              );
            }),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  ANIMATED NOTIFICATION ITEM
// ══════════════════════════════════════════════════════
class _AnimatedNotifItem extends StatefulWidget {
  final _TraderNotif notif;
  final bool isLast, isDark;
  final Color kText, kMuted, typeColor;
  final Animation<double> cardFade, dotScale, btnFade;
  final Animation<Offset> cardSlide;

  const _AnimatedNotifItem({
    required this.notif,
    required this.isLast,
    required this.isDark,
    required this.kText,
    required this.kMuted,
    required this.typeColor,
    required this.cardFade,
    required this.cardSlide,
    required this.dotScale,
    required this.btnFade,
  });

  @override
  State<_AnimatedNotifItem> createState() => _AnimatedNotifItemState();
}

class _AnimatedNotifItemState extends State<_AnimatedNotifItem> {
  @override
  void initState() {
    super.initState();
    // Listen to all animations so widget rebuilds correctly
    widget.cardFade.addListener(_rebuild);
    widget.dotScale.addListener(_rebuild);
    widget.btnFade.addListener(_rebuild);
    widget.cardSlide.addListener(_rebuild);
  }

  void _rebuild() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    widget.cardFade.removeListener(_rebuild);
    widget.dotScale.removeListener(_rebuild);
    widget.btnFade.removeListener(_rebuild);
    widget.cardSlide.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kCard   = widget.isDark ? const Color(0xFF0F1C2E) : Colors.white;
    final isFilled = widget.notif.type == _NotifType.actionRequired;
    final notif    = widget.notif;
    final isDark   = widget.isDark;
    final kText    = widget.kText;
    final kMuted   = widget.kMuted;
    final typeColor = widget.typeColor;

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Timeline column ──
        SizedBox(width: 72, child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Time label
          notif.time != null
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 10),
                  child: Opacity(
                    opacity: widget.cardFade.value,
                    child: Text(notif.time!,
                        style: TextStyle(color: kMuted, fontSize: 11)),
                  ))
              : const SizedBox(height: 26),

          // ── Timeline dot — scale bounce ──
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Transform.scale(
              scale: widget.dotScale.value,
              child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: typeColor.withOpacity(0.2),
                  border: Border.all(color: typeColor, width: 2)),
                child: Center(child: Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: typeColor),
                )),
              ),
            ),
          ]),

          // Timeline line
          if (!widget.isLast)
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 2,
                    color: typeColor.withOpacity(isDark ? 0.25 : 0.3)),
                const SizedBox(width: 8),
              ])),
        ])),

        const SizedBox(width: 10),

        // ── Notification card — fade + slide up ──
        Expanded(child: Opacity(
          opacity: widget.cardFade.value,
          child: Transform.translate(
            offset: Offset(0, widget.cardSlide.value.dy * 20),
            child: _Tap(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(18),
                  border: isDark
                      ? Border.all(
                          color: const Color(0xFF00D5BE).withOpacity(0.1),
                          width: 0.8)
                      : null,
                  boxShadow: isDark ? [] : [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // Badge
                  Opacity(
                    opacity: widget.cardFade.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(isDark ? 0.15 : 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: isDark ? Border.all(
                            color: typeColor.withOpacity(0.4), width: 0.8)
                            : null,
                      ),
                      child: Text(notif.badge, style: TextStyle(
                          color: typeColor, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Icon + title
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: typeColor.withOpacity(0.15)),
                      child: Icon(notif.icon, color: typeColor, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(notif.title, style: TextStyle(
                        color: kText, fontSize: 16,
                        fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 10),

                  // Body
                  Text(notif.body, style: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.55)
                          : const Color(0xFF6B8096),
                      fontSize: 13, height: 1.5)),
                  const SizedBox(height: 14),

                  // ── Action button — fade in after card ──
                  Opacity(
                    opacity: widget.btnFade.value,
                    child: isFilled
                      ? _Tap(
                          onTap: () {},
                          child: Container(
                            width: double.infinity, height: 44,
                            decoration: BoxDecoration(
                                color: typeColor,
                                borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text(notif.btnText, style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                          ))
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: _Tap(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(isDark ? 0.12 : 0.10),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: typeColor.withOpacity(
                                        isDark ? 0.3 : 0.4),
                                    width: 0.8)),
                              child: Text(notif.btnText, style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                            ),
                          )),
                  ),
                ]),
              ),
            ),
          ),
        )),
      ]),
    );
  }
}
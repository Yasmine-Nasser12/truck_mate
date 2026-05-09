import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// RN animations ported:
// • initial={{ opacity:0, y:20 }} → header + stat cards (delay 0.2s)
// • initial={{ opacity:0, y:20 }} → each shipment card staggered (delay i*0.1+0.3)
// • whileTap scale:0.98 → shipment cards (like RN whileTap)
// • Background blobs: x[0,-20,0] y[0,30,0] 10s easeInOut infinite (second blob from InTransitScreen)

class _ShipmentItem {
  final String date, from, to, driver, status;
  final int price, statusColor;
  const _ShipmentItem({
    required this.date, required this.from, required this.to,
    required this.driver, required this.price,
    required this.status, required this.statusColor,
  });
}

const _kShipments = [
  _ShipmentItem(date: 'Today, 2:30 PM', from: 'Maadi',     to: 'Nasr City',  driver: 'Ahmed Hassan',    price: 285, status: 'In Transit', statusColor: 0xFF3B82F6),
  _ShipmentItem(date: 'Yesterday',      from: 'October',   to: 'Heliopolis', driver: 'Mohamed Ali',     price: 320, status: 'Delivered',  statusColor: 0xFF00D5BE),
  _ShipmentItem(date: 'Jan 26, 2026',   from: 'Zamalek',   to: 'Maadi',      driver: 'Omar Khaled',     price: 195, status: 'Delivered',  statusColor: 0xFF00D5BE),
  _ShipmentItem(date: 'Jan 25, 2026',   from: 'New Cairo', to: 'Downtown',   driver: 'Youssef Ibrahim', price: 240, status: 'Delivered',  statusColor: 0xFF00D5BE),
  _ShipmentItem(date: 'Jan 23, 2026',   from: 'Giza',      to: 'October',    driver: 'Ahmed Hassan',    price: 310, status: 'Delivered',  statusColor: 0xFF00D5BE),
  _ShipmentItem(date: 'Jan 20, 2026',   from: 'Nasr City', to: 'Maadi',      driver: 'Mohamed Ali',     price: 275, status: 'Delivered',  statusColor: 0xFF00D5BE),
];

class TraderMyShipmentsScreen extends StatefulWidget {
  const TraderMyShipmentsScreen({super.key});
  @override
  State<TraderMyShipmentsScreen> createState() => _TraderMyShipmentsScreenState();
}

class _TraderMyShipmentsScreenState extends State<TraderMyShipmentsScreen>
    with TickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final List<AnimationController> _cardCtrls;
  late final AnimationController _blobCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final List<Animation<double>> _cardFades;
  late final List<Animation<Offset>> _cardSlides;
  late final Animation<double> _blobX, _blobY;

  @override
  void initState() {
    super.initState();

    // Header
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // Cards: one controller per item
    _cardCtrls = List.generate(_kShipments.length + 1, // +1 for stat cards
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _cardFades = _cardCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>).toList();
    _cardSlides = _cardCtrls.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Background blobs: 10s easeInOut infinite
    _blobCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 10000))
      ..repeat(reverse: true);
    _blobX = Tween<double>(begin: 0, end: -20)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));
    _blobY = Tween<double>(begin: 0, end: 30)
        .animate(CurvedAnimation(parent: _blobCtrl, curve: Curves.easeInOut));

    // Stagger: header → stat cards → shipment cards
    _headerCtrl.forward();
    for (int i = 0; i < _cardCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 80), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _cardCtrls) { c.dispose(); }
    _blobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF8F9FA);
    final kCard   = isDark ? const Color(0xFF112236) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A1A1A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF6B7280);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE0F7FA);
    const kTeal   = Color(0xFF00D5BE);
    final kAccent = isDark ? const Color(0xFF00A3C4) : const Color(0xFF00A3C4);

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(children: [

        // Background blobs
        AnimatedBuilder(
          animation: _blobCtrl,
          builder: (_, __) => Stack(children: [
            Positioned(
              top: 80 + _blobY.value, right: 10 + _blobX.value,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: kTeal.withOpacity(0.03)))),
            Positioned(
              bottom: 80 - _blobY.value * 0.5, left: 20,
              child: Container(width: 120, height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: kAccent.withOpacity(0.03)))),
          ]),
        ),

        SafeArea(child: Column(children: [

          // Header: x -0.1→0 + opacity
          SlideTransition(position: _headerSlide, child: FadeTransition(
            opacity: _headerFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(children: [
                _TapScaleButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder)),
                    child: Icon(Icons.chevron_left,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A), size: 24))),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('My Shipments', style: TextStyle(
                      color: kText, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('${_kShipments.length} total shipments',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ]),
            ),
          )),

          // Stat cards: stagger index 0
          SlideTransition(position: _cardSlides[0], child: FadeTransition(
            opacity: _cardFades[0],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: _StatCard(icon: Icons.calendar_today_outlined,
                    label: 'This Month', value: '12',
                    isDark: isDark, kCard: kCard, kBorder: kBorder,
                    kMuted: kMuted, kText: kText, kTeal: kTeal)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(icon: Icons.attach_money,
                    label: 'Total Spent', value: '\$3.2K',
                    isDark: isDark, kCard: kCard, kBorder: kBorder,
                    kMuted: kMuted, kText: kAccent, kTeal: kTeal)),
              ]),
            ),
          )),
          const SizedBox(height: 16),

          // Shipment cards list: stagger indices 1..n
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kShipments.length,
            itemBuilder: (_, i) {
              final idx = i + 1;
              return SlideTransition(
                position: idx < _cardSlides.length ? _cardSlides[idx] : _cardSlides.last,
                child: FadeTransition(
                  opacity: idx < _cardFades.length ? _cardFades[idx] : _cardFades.last,
                  child: _TapScaleButton(
                    onTap: () {},
                    child: _ShipCard(
                      item: _kShipments[i], isDark: isDark,
                      kCard: kCard, kText: kText, kMuted: kMuted, kBorder: kBorder),
                  ),
                ),
              );
            },
          )),
        ])),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isDark;
  final Color kCard, kBorder, kMuted, kText, kTeal;
  const _StatCard({required this.icon, required this.label, required this.value,
    required this.isDark, required this.kCard, required this.kBorder,
    required this.kMuted, required this.kText, required this.kTeal});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder, width: 1.5),
      boxShadow: isDark ? [] : [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: kTeal.withOpacity(isDark ? 0.15 : 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: kTeal, size: 20)),
      const SizedBox(height: 12),
      Text(label, style: TextStyle(color: kMuted, fontSize: 13)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          color: kText, fontSize: 26, fontWeight: FontWeight.bold)),
    ]),
  );
}

class _ShipCard extends StatelessWidget {
  final _ShipmentItem item;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder;
  const _ShipCard({required this.item, required this.isDark,
    required this.kCard, required this.kText, required this.kMuted, required this.kBorder});
  @override
  Widget build(BuildContext context) {
    final statusColor = Color(item.statusColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(item.date, style: TextStyle(color: kMuted, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Text(item.status, style: TextStyle(
                color: statusColor, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: Color(0xFF00A3C4), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(item.from, style: TextStyle(
              color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: kMuted, size: 16),
          const SizedBox(width: 8),
          Text(item.to, style: TextStyle(
              color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Driver: ${item.driver}', style: TextStyle(color: kMuted, fontSize: 13)),
          Text('\$${item.price}', style: const TextStyle(
              color: Color(0xFF00A3C4), fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }
}

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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

// ══════════════════════════════════════════════════════
//  TRADER DRIVER OFFERS SCREEN — with RN-matching animations
// ══════════════════════════════════════════════════════

const Duration _kFast    = Duration(milliseconds: 300);
const Duration _kMed     = Duration(milliseconds: 500);
const Duration _kStagger = Duration(milliseconds: 80);
const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;

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

class _OfferItem {
  final String name, initials, truckType, deliveryTime;
  final double rating;
  final int trips, price;
  const _OfferItem({
    required this.name, required this.initials, required this.truckType,
    required this.rating, required this.trips, required this.price,
    required this.deliveryTime,
  });
}

const _kOffers = [
  _OfferItem(name: 'Ahmed Hassan',    initials: 'AH', truckType: 'Flatbed Truck',
      rating: 4.8, trips: 127, price: 285, deliveryTime: '4-5 hrs'),
  _OfferItem(name: 'Mohamed Ali',     initials: 'MA', truckType: 'Box Truck',
      rating: 4.9, trips: 203, price: 270, deliveryTime: '4-5 hrs'),
  _OfferItem(name: 'Omar Khaled',     initials: 'OK', truckType: 'Cargo Van',
      rating: 4.7, trips: 89,  price: 295, deliveryTime: '4-5 hrs'),
  _OfferItem(name: 'Youssef Ibrahim', initials: 'YI', truckType: 'Flatbed Truck',
      rating: 4.6, trips: 156, price: 280, deliveryTime: '4-5 hrs'),
];

class TraderDriverOffersScreen extends StatefulWidget {
  final String shipmentFrom, shipmentTo, shipmentInfo;
  const TraderDriverOffersScreen({
    super.key,
    this.shipmentFrom = 'Maadi',
    this.shipmentTo   = 'Nasr City',
    this.shipmentInfo = '2.5 tons · Flatbed Truck',
  });
  @override
  State<TraderDriverOffersScreen> createState() =>
      _TraderDriverOffersScreenState();
}

class _TraderDriverOffersScreenState extends State<TraderDriverOffersScreen>
    with TickerProviderStateMixin {

  // ── Header — fade + slide down ──
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  // ── Shipment banner — scale bounce ──
  late AnimationController _bannerCtrl;
  late Animation<double> _bannerScale, _bannerFade;

  // ── Offer cards — staggered slide up ──
  late AnimationController _listCtrl;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  @override
  void initState() {
    super.initState();

    // Header
    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    // Banner
    _bannerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _bannerScale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _bannerCtrl, curve: _kEaseOutBack));
    _bannerFade  = CurvedAnimation(parent: _bannerCtrl, curve: _kEaseOutCubic);

    // Offer cards stagger
    final totalMs = 400 + _kOffers.length * _kStagger.inMilliseconds;
    _listCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));
    _cardFades = List.generate(_kOffers.length, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _listCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _cardSlides = List.generate(_kOffers.length, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
          .animate(CurvedAnimation(parent: _listCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _runSequence();
  }

  void _runSequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _bannerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _listCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _bannerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDark;
    final kBg      = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF8F9FA);
    final kCard    = isDark ? const Color(0xFF112236) : Colors.white;
    final kShipBg  = isDark ? const Color(0xFF0A1628) : const Color(0xFFEDF6F8);
    final kText    = isDark ? Colors.white             : const Color(0xFF1A1A1A);
    final kMuted   = isDark ? const Color(0xFF5F7E97)  : const Color(0xFF6B7280);
    final kBorder  = isDark ? const Color(0xFF1A3550)  : const Color(0xFFE0F7FA);
    final kTeal    = const Color(0xFF00D5BE);
    final kPriceBg = isDark ? const Color(0xFF0A1628)  : const Color(0xFFE0F7FA);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // ── [0] Header — fade + slide down ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _Tap(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: Icon(Icons.chevron_left,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Driver Offers', style: TextStyle(
                      color: kText, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${_kOffers.length} offers available',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                ]),
              ]),
            ),
          ),
        ),

        // ── [1] Shipment banner — scale bounce ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ScaleTransition(
            scale: _bannerScale,
            child: FadeTransition(
              opacity: _bannerFade,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kShipBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kTeal.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Shipment',
                      style: TextStyle(color: kMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(widget.shipmentFrom, style: TextStyle(
                        color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: kTeal, size: 18),
                    const SizedBox(width: 8),
                    Text(widget.shipmentTo, style: TextStyle(
                        color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  Text(widget.shipmentInfo,
                      style: TextStyle(color: kMuted, fontSize: 14)),
                ]),
              ),
            ),
          ),
        ),

        // ── [2] Offer cards — staggered ──
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _kOffers.length,
          itemBuilder: (_, i) => FadeTransition(
            opacity: _cardFades[i],
            child: SlideTransition(
              position: _cardSlides[i],
              child: _OfferCard(
                offer: _kOffers[i],
                isDark: isDark,
                kCard: kCard, kText: kText, kMuted: kMuted,
                kBorder: kBorder, kTeal: kTeal, kPriceBg: kPriceBg,
                onAccept: () => Navigator.pop(context),
              ),
            ),
          ),
        )),
      ])),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _OfferItem offer;
  final bool isDark;
  final Color kCard, kText, kMuted, kBorder, kTeal, kPriceBg;
  final VoidCallback onAccept;
  const _OfferCard({
    required this.offer, required this.isDark,
    required this.kCard, required this.kText, required this.kMuted,
    required this.kBorder, required this.kTeal, required this.kPriceBg,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder, width: 1.5),
        boxShadow: isDark ? [] : [BoxShadow(
            color: kTeal.withOpacity(0.08),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Driver info
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D5BE), Color(0xFF00B8DB)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(offer.initials, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(offer.name, style: TextStyle(color: kText,
                fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(children: [
              Text(offer.truckType,
                  style: TextStyle(color: kMuted, fontSize: 13)),
              const SizedBox(width: 6),
              Container(width: 4, height: 4,
                  decoration: BoxDecoration(color: kMuted, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
              const SizedBox(width: 2),
              Text('${offer.rating}', style: TextStyle(
                  color: kText, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(width: 4, height: 4,
                  decoration: BoxDecoration(color: kMuted, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${offer.trips} trips',
                  style: TextStyle(color: kMuted, fontSize: 13)),
            ]),
          ])),
        ]),
        const SizedBox(height: 14),

        // Price box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: kPriceBg, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Price', style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text('\$${offer.price}', style: const TextStyle(
                  color: Color(0xFF00D5BE), fontSize: 22,
                  fontWeight: FontWeight.bold)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Delivery', style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(offer.deliveryTime, style: TextStyle(
                  color: kText, fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        // Accept / Reject buttons
        Row(children: [
          _Tap(
            onTap: () {},
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3D1525) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? const Color(0xFFFF476D).withOpacity(0.3)
                        : const Color(0xFFFECACA)),
              ),
              child: Icon(Icons.close,
                  color: isDark
                      ? const Color(0xFFFF476D) : const Color(0xFFEF4444),
                  size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _Tap(
            onTap: onAccept,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D5BE), Color(0xFF00B8DB)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF00D5BE).withOpacity(0.3),
                    blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Accept', style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold)),
              ]),
            ),
          )),
        ]),
      ]),
    );
  }
}
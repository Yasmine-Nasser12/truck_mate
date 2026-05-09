// ════════════════════════════════════════════════════════════
//  driver_trip_screens.dart  — Full Animations
//  1. AvailableTripsScreen
//  2. TripAvailableScreen      — border pulse + countdown
//  3. RequestDetailsScreen     — stagger entrance
//  4. RequestAcceptedScreen    — confetti + pulsing rings
//  5. FindingShipmentsScreen   — rotating search + skeleton shimmer
//  6. NoRequestsScreen         — pulsing radio waves
//  7. RequestExpiredScreen     — clock crossing line
//  8. ConnectionLostScreen     — shake + pulsing rings
//  9. FailedToLoadScreen       — error rings
// ════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/screen/driver/driver_pickup_screens.dart';

// ── Shared Palette ──
const Color _kTeal  = Color(0xFF00D5BE);
const Color _kAmber = Color(0xFFF5A623);
const Color _kRed   = Color(0xFFEF4444);
const Color _kGreen = Color(0xFF22C55E);

const _kGrad = LinearGradient(
  colors: [Color(0xFF009689), Color(0xFF00B8DB)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

Color _bg(bool d)     => d ? const Color(0xFF0D1B2A) : const Color(0xFFF5F8FA);
Color _card(bool d)   => d ? const Color(0xFF0F2035) : Colors.white;
Color _border(bool d) => d ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
Color _text(bool d)   => d ? Colors.white : const Color(0xFF1A2A3A);
Color _muted(bool d)  => d ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);
Color _chip(bool d)   => d ? const Color(0xFF112236) : const Color(0xFFEEF5FF);

// ══════════════════════════════════════════════════════
//  SHARED: GRADIENT BUTTON with shimmer
// ══════════════════════════════════════════════════════
class _GradBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const _GradBtn({required this.label, required this.onTap, this.icon});
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
          gradient: _kGrad,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: _kTeal.withOpacity(0.35),
            blurRadius: 16, offset: const Offset(0, 6),
          )],
        ),
        child: Stack(alignment: Alignment.center, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _shimAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(_shimAnim.value * 200, 0),
                child: Container(width: 80,
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
            if (widget.icon != null) ...[
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(widget.label, style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: PULSING RINGS
// ══════════════════════════════════════════════════════
class _PulsingRings extends StatefulWidget {
  final Color color;
  final Widget child;
  final double size;
  final int count;
  const _PulsingRings({
    required this.color, required this.child,
    this.size = 100, this.count = 2,
  });
  @override
  State<_PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<_PulsingRings>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: widget.size, height: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        ...List.generate(widget.count, (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final delay = i * (1.0 / widget.count);
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            return Transform.scale(
              scale: 1.0 + 0.5 * t,
              child: Container(
                width: widget.size, height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.color.withOpacity((1 - t) * 0.5),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        )),
        widget.child,
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  SHARED: BACK BUTTON
// ══════════════════════════════════════════════════════
Widget _backBtn(BuildContext ctx, bool d) => GestureDetector(
  onTap: () => Navigator.maybePop(ctx),
  child: Container(
    width: 42, height: 42,
    decoration: BoxDecoration(
      color: _card(d), shape: BoxShape.circle,
      border: Border.all(color: _border(d))),
    child: const Icon(Icons.arrow_back_rounded, color: _kTeal, size: 20),
  ),
);

// ══════════════════════════════════════════════════════
//  DATA MODEL
// ══════════════════════════════════════════════════════
class TripData {
  final String id, pickup, pickupAddr, dropoff, dropoffAddr;
  final String distance, estTime, cargoType, trader, traderPhone;
  final double price;
  final int weightLbs, packages;
  final String postedAgo, specialNotes;

  const TripData({
    required this.id,
    required this.pickup, this.pickupAddr = '',
    required this.dropoff, this.dropoffAddr = '',
    required this.distance, required this.estTime,
    required this.cargoType, required this.trader,
    this.traderPhone = '',
    required this.price,
    this.weightLbs = 0, this.packages = 0,
    this.postedAgo = '',
    this.specialNotes = '',
  });
}

const _kTrips = [
  TripData(
    id: 'REQ-4522',
    pickup: 'Cairo Distribution Hub', pickupAddr: '124 Nasr Road, Cairo',
    dropoff: 'Alexandria Port Terminal', dropoffAddr: '45 Port Road, Alexandria',
    distance: '120 km', estTime: '2 hr 30 min',
    cargoType: 'Construction Materials', trader: 'Mohamed Hassan Trading Co.',
    traderPhone: '+20 100 123 4567', price: 240,
    weightLbs: 3200, packages: 12, postedAgo: '5 mins ago',
    specialNotes: 'Handle with care - Fragile items. Contact before pickup.',
  ),
  TripData(
    id: 'REQ-4523',
    pickup: 'Maadi Warehouse', dropoff: 'New Cairo Industrial Zone',
    distance: '35 km', estTime: '45 min',
    cargoType: 'Electronics', trader: 'Tech Supplies Co.',
    price: 85, weightLbs: 1200, postedAgo: '12 mins ago',
  ),
  TripData(
    id: 'REQ-4524',
    pickup: '6th October City Depot', dropoff: 'Giza Distribution Center',
    distance: '28 km', estTime: '35 min',
    cargoType: 'Food & Beverages', trader: 'Fresh Foods Ltd.',
    price: 65, weightLbs: 2100, postedAgo: '18 mins ago',
  ),
];

// ══════════════════════════════════════════════════════
//  1. AVAILABLE TRIPS SCREEN
// ══════════════════════════════════════════════════════
class AvailableTripsScreen extends StatefulWidget {
  const AvailableTripsScreen({super.key});
  @override
  State<AvailableTripsScreen> createState() => _AvailableTripsState();
}

class _AvailableTripsState extends State<AvailableTripsScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  late AnimationController _listCtrl;

  @override
  void initState() {
    super.initState();
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  void dispose() { _listCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header (slide from top)
        TweenAnimationBuilder<double>(
          tween: Tween(begin: -30, end: 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Transform.translate(
            offset: Offset(0, v), child: Opacity(opacity: (1 + v / 30).clamp(0, 1), child: child)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trips', style: TextStyle(
                  color: _text(d), fontSize: 28, fontWeight: FontWeight.bold)),
              Text('Manage your requests and active trips',
                  style: TextStyle(color: _muted(d), fontSize: 13)),
            ]),
          ),
        ),
        const SizedBox(height: 20),

        // Animated tabs
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _card(d), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border(d))),
            child: Row(children: [
              _tabBtn('Available Requests', 0, d),
              _tabBtn('My Trips', 1, d),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        Expanded(child: _tab == 0 ? _availableList(d) : _myTrips(d)),
      ])),
    );
  }

  Widget _tabBtn(String label, int idx, bool d) => Expanded(child:
    GestureDetector(
      onTap: () {
        setState(() => _tab = idx);
        _listCtrl.forward(from: 0);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 40,
        decoration: BoxDecoration(
          gradient: _tab == idx ? _kGrad : null,
          borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: TextStyle(
          color: _tab == idx ? Colors.white : _muted(d),
          fontSize: 14, fontWeight: FontWeight.w600))),
      ),
    ));

  Widget _availableList(bool d) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _kTrips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => AnimatedBuilder(
        animation: _listCtrl,
        builder: (_, child) {
          final delay = i * 0.12;
          final t = ((_listCtrl.value - delay) / 0.4).clamp(0.0, 1.0);
          final curve = Curves.easeOutCubic.transform(t);
          return Opacity(
            opacity: curve,
            child: Transform.translate(offset: Offset(0, 20 * (1 - curve)), child: child),
          );
        },
        child: _TripCard(
          trip: _kTrips[i], isDark: d,
          onViewDetails: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => RequestDetailsScreen(trip: _kTrips[i]))),
          onAccept: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TripAvailableScreen(trip: _kTrips[i]))),
        ),
      ),
    );
  }

  Widget _myTrips(bool d) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.route_outlined, color: _muted(d), size: 56),
      const SizedBox(height: 16),
      Text('No active trips', style: TextStyle(
          color: _text(d), fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Accepted trips will appear here',
          style: TextStyle(color: _muted(d), fontSize: 14)),
    ]),
  );
}

// ── Trip Card widget ──
class _TripCard extends StatefulWidget {
  final TripData trip;
  final bool isDark;
  final VoidCallback onViewDetails, onAccept;
  const _TripCard({required this.trip, required this.isDark,
      required this.onViewDetails, required this.onAccept});
  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: _card(widget.isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border(widget.isDark)),
            boxShadow: widget.isDark ? [] : [BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10, offset: const Offset(0, 3))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Price header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kAmber,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Offered Price', style: TextStyle(
                    color: Colors.black.withOpacity(0.7), fontSize: 13)),
                Row(children: [
                  Text('${widget.trip.price.toInt()}', style: const TextStyle(
                      color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text(' EGP', style: TextStyle(
                      color: Colors.black87, fontSize: 13)),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Route
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(width: 10, height: 10,
                        decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle)),
                    Container(width: 2, height: 40, color: _kTeal.withOpacity(0.3)),
                    const Icon(Icons.location_on_rounded, color: _kAmber, size: 14),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pickup', style: TextStyle(color: _muted(widget.isDark), fontSize: 11)),
                    Text(widget.trip.pickup, style: TextStyle(color: _text(widget.isDark),
                        fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Drop-off', style: TextStyle(color: _muted(widget.isDark), fontSize: 11)),
                    Text(widget.trip.dropoff, style: TextStyle(color: _text(widget.isDark),
                        fontSize: 15, fontWeight: FontWeight.bold)),
                  ])),
                ]),
                const SizedBox(height: 12),
                // Info chips
                Row(children: [
                  _chip(Icons.location_on_outlined, 'Distance', widget.trip.distance, widget.isDark),
                  const SizedBox(width: 8),
                  _chip(Icons.access_time_rounded, 'Time', widget.trip.estTime, widget.isDark),
                  const SizedBox(width: 8),
                  _chip(Icons.scale_outlined, 'Weight', '${widget.trip.weightLbs} lbs', widget.isDark),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Cargo', style: TextStyle(color: _muted(widget.isDark), fontSize: 11)),
                    Text(widget.trip.cargoType, style: TextStyle(
                        color: _text(widget.isDark), fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                  Text(widget.trip.postedAgo, style: const TextStyle(
                      color: _kAmber, fontSize: 12)),
                ]),
                const SizedBox(height: 14),
                // Buttons
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: widget.onViewDetails,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _kTeal.withOpacity(0.5)),
                      foregroundColor: _kTeal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 13)),
                    child: const Text('View Details', style: TextStyle(
                        color: _kTeal, fontSize: 14, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(
                    onTap: widget.onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        gradient: _kGrad, borderRadius: BorderRadius.circular(12)),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Accept', style: TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ]),
                    ),
                  )),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value, bool d) =>
    Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: _chip(d), borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border(d))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _kTeal, size: 12),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(color: _muted(d), fontSize: 10)),
        ]),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: _text(d),
            fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    ));
}


// ══════════════════════════════════════════════════════
//  2. TRIP AVAILABLE SCREEN — border pulse + countdown
// ══════════════════════════════════════════════════════
class TripAvailableScreen extends StatefulWidget {
  final TripData trip;
  const TripAvailableScreen({super.key, required this.trip});
  @override
  State<TripAvailableScreen> createState() => _TripAvailableState();
}

class _TripAvailableState extends State<TripAvailableScreen>
    with TickerProviderStateMixin {
  int _countdown = 45;
  late final _timer = Stream.periodic(const Duration(seconds: 1)).listen((_) {
    if (!mounted) return;
    setState(() => _countdown--);
    if (_countdown <= 0) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const RequestExpiredScreen()));
    }
  });

  // Border color animation (teal → amber → teal)
  late AnimationController _borderCtrl;
  late Animation<Color?> _borderAnim;

  // Card glow pulse
  late AnimationController _glowCtrl;

  // Entrance stagger
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  @override
  void initState() {
    super.initState();
    _borderCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _borderAnim = TweenSequence<Color?>([
      TweenSequenceItem(
          tween: ColorTween(begin: _kTeal, end: _kAmber), weight: 50),
      TweenSequenceItem(
          tween: ColorTween(begin: _kAmber, end: _kTeal), weight: 50),
    ]).animate(_borderCtrl);

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _items = List.generate(8, (i) {
      final s = (i * 0.09).clamp(0.0, 0.75);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _borderCtrl.dispose();
    _glowCtrl.dispose();
    _entranceCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(children: [
        const SizedBox(height: 16),

        // NEW SHIPMENT badge
        _a(0, Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: _card(d), borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kTeal.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _kGreen,
                  boxShadow: [BoxShadow(
                    color: _kGreen.withOpacity(0.5 * _glowCtrl.value),
                    blurRadius: 8,
                  )],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('NEW SHIPMENT REQUEST', style: TextStyle(
                color: _text(d), fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ))),
        const SizedBox(height: 16),

        _a(1, Text('Trip Available', style: TextStyle(
            color: _text(d), fontSize: 26, fontWeight: FontWeight.bold))),
        const SizedBox(height: 6),
        _a(1, Text('Review details and accept or decline',
            style: TextStyle(color: _muted(d), fontSize: 13))),
        const SizedBox(height: 10),

        // Distance badge
        _a(2, Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _card(d), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border(d))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_on_outlined, color: _kTeal, size: 16),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, color: _kTeal, size: 14),
            const SizedBox(width: 4),
            const Icon(Icons.location_on_rounded, color: _kAmber, size: 16),
            const SizedBox(width: 8),
            Text('${widget.trip.distance} • ${widget.trip.estTime}',
                style: TextStyle(color: _text(d), fontSize: 13)),
          ]),
        )),
        const SizedBox(height: 16),

        // Main card with animated border
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _a(3, AnimatedBuilder(
            animation: _borderAnim,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                color: (_borderAnim.value ?? _kTeal).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _borderAnim.value ?? _kTeal, width: 1.5)),
              child: child,
            ),
            child: Column(children: [
              // Price
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: _kGrad,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Trip Payment',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  Text('${widget.trip.price.toInt()} EGP', style: const TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ]),
              ),
              // Route + details
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _routeTimeline(widget.trip.pickup, widget.trip.dropoff, d),
                  const SizedBox(height: 16),
                  Row(children: [
                    _infoChip(Icons.location_on_outlined, 'Distance', widget.trip.distance, d),
                    const SizedBox(width: 10),
                    _infoChip(Icons.access_time_rounded, 'Est. Time', widget.trip.estTime, d),
                  ]),
                  const SizedBox(height: 14),
                  // Shipment
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card(d).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border(d))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.local_shipping_outlined, color: _kTeal, size: 16),
                        const SizedBox(width: 8),
                        Text('Shipment Details', style: TextStyle(
                            color: _text(d), fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 12),
                      _detailRow('Type', widget.trip.cargoType, d),
                      const SizedBox(height: 8),
                      _detailRow('Weight', '${widget.trip.weightLbs} lbs', d),
                    ]),
                  ),
                ]),
              ),
            ]),
          )),
        )),

        // Countdown timer
        _a(4, Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _card(d), borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border(d))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.access_time_rounded, color: _kAmber, size: 18),
              const SizedBox(width: 8),
              Text('Request expires in ', style: TextStyle(color: _muted(d), fontSize: 14)),
              // Pulsing countdown
              AnimatedBuilder(
                animation: _glowCtrl,
                builder: (_, __) => Text('${_countdown}s', style: TextStyle(
                  color: _kAmber, fontSize: 16, fontWeight: FontWeight.bold,
                  shadows: [Shadow(
                    color: _kAmber.withOpacity(0.5 * _glowCtrl.value),
                    blurRadius: 8,
                  )],
                )),
              ),
            ]),
          ),
        )),

        // Buttons
        _a(5, Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _card(d), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(d))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.close, color: _muted(d), size: 18),
                  const SizedBox(width: 6),
                  Text('Decline', style: TextStyle(color: _muted(d), fontSize: 15)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => RequestAcceptedScreen(trip: widget.trip))),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: _kGrad, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: _kTeal.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 5))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Accept Trip', style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              ),
            )),
          ]),
        )),
      ])),
    );
  }
}


// ══════════════════════════════════════════════════════
//  3. REQUEST DETAILS SCREEN — stagger entrance
// ══════════════════════════════════════════════════════
class RequestDetailsScreen extends StatefulWidget {
  final TripData trip;
  const RequestDetailsScreen({super.key, required this.trip});
  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsState();
}

class _RequestDetailsState extends State<RequestDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _items;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))..forward();
    _items = List.generate(8, (i) {
      final s = (i * 0.09).clamp(0.0, 0.75);
      final e = (s + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _ctrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(children: [
        // Header
        _a(0, Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            _backBtn(context, d),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Request Details', style: TextStyle(
                  color: _text(d), fontSize: 22, fontWeight: FontWeight.bold)),
              Text(widget.trip.id, style: TextStyle(color: _muted(d), fontSize: 13)),
            ]),
          ]),
        )),
        const SizedBox(height: 16),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [

            // Payment card
            _a(1, Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card(d), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kAmber.withOpacity(0.5), width: 1.5)),
              child: Column(children: [
                Text('Offered Payment', style: TextStyle(color: _muted(d), fontSize: 14)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.attach_money_rounded, color: _kAmber, size: 28),
                  Text('${widget.trip.price.toInt()}', style: const TextStyle(
                      color: _kAmber, fontSize: 36, fontWeight: FontWeight.bold)),
                  const Text(' EGP', style: TextStyle(color: _kAmber, fontSize: 18)),
                ]),
                const SizedBox(height: 6),
                Text('Posted ${widget.trip.postedAgo}',
                    style: TextStyle(color: _muted(d), fontSize: 13)),
              ]),
            )),
            const SizedBox(height: 14),

            // Route card
            _a(2, _sectionCard(d, Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.location_on_outlined, color: _kTeal, size: 18),
                const SizedBox(width: 8),
                Text('Route', style: TextStyle(
                    color: _text(d), fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              _fullRoute(widget.trip, d),
              const SizedBox(height: 16),
              Row(children: [
                _infoChip(Icons.location_on_outlined, 'Distance', widget.trip.distance, d),
                const SizedBox(width: 10),
                _infoChip(Icons.access_time_rounded, 'Est. Time', widget.trip.estTime, d),
              ]),
            ]))),
            const SizedBox(height: 14),

            // Cargo
            _a(3, _sectionCard(d, Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.inventory_2_outlined, color: _kTeal, size: 18),
                const SizedBox(width: 8),
                Text('Cargo Details', style: TextStyle(
                    color: _text(d), fontSize: 17, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 16),
              _infoLine('Type', widget.trip.cargoType, d),
              const SizedBox(height: 10),
              _infoLine('Weight', '${widget.trip.weightLbs} lbs', d),
              if (widget.trip.packages > 0) ...[
                const SizedBox(height: 10),
                _infoLine('Packages', '${widget.trip.packages} pallets', d),
              ],
            ]))),
            const SizedBox(height: 14),

            // Trader
            _a(4, Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card(d), borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border(d))),
              child: Row(children: [
                Container(width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _kTeal.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.person_outline_rounded, color: _kTeal, size: 24)),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Trader', style: TextStyle(color: _muted(d), fontSize: 12)),
                  Text(widget.trip.trader, style: TextStyle(
                      color: _text(d), fontSize: 15, fontWeight: FontWeight.w600)),
                  if (widget.trip.traderPhone.isNotEmpty)
                    Text(widget.trip.traderPhone, style: TextStyle(color: _muted(d), fontSize: 13)),
                ]),
              ]),
            )),

            // Special notes
            if (widget.trip.specialNotes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _a(5, Container(
                width: double.infinity, padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kAmber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kAmber.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.note_outlined, color: _kAmber, size: 16),
                    const SizedBox(width: 8),
                    Text('SPECIAL NOTES', style: TextStyle(
                        color: _kAmber.withOpacity(0.8), fontSize: 11,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 10),
                  Text(widget.trip.specialNotes,
                      style: TextStyle(color: _text(d), fontSize: 14, height: 1.5)),
                ]),
              )),
            ],
            const SizedBox(height: 20),
          ]),
        )),

        // Buttons
        _a(6, Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _card(d), borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border(d))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.close, color: _muted(d), size: 18),
                  const SizedBox(width: 6),
                  Text('Reject', style: TextStyle(color: _muted(d), fontSize: 15)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RequestAcceptedScreen(trip: widget.trip))),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: _kGrad, borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: _kTeal.withOpacity(0.35),
                      blurRadius: 14, offset: const Offset(0, 5))]),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Accept Request', style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ]),
              ),
            )),
          ]),
        )),
      ])),
    );
  }
}


// ══════════════════════════════════════════════════════
//  4. REQUEST ACCEPTED SCREEN — confetti + pulsing rings
// ══════════════════════════════════════════════════════
class RequestAcceptedScreen extends StatefulWidget {
  final TripData trip;
  const RequestAcceptedScreen({super.key, required this.trip});
  @override
  State<RequestAcceptedScreen> createState() => _RequestAcceptedState();
}

class _RequestAcceptedState extends State<RequestAcceptedScreen>
    with TickerProviderStateMixin {

  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _iconCtrl;
  late Animation<double> _iconAnim;
  late AnimationController _confettiCtrl;
  final _particles = <_ConfettiParticle>[];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    for (int i = 0; i < 12; i++) {
      _particles.add(_ConfettiParticle(
        color: [const Color(0xFF34C759), _kTeal, _kAmber,
            const Color(0xFFFBBF24)][i % 4],
        x: 0.2 + i * 0.05,
        delay: i * 0.1,
        drift: i % 2 == 0 ? 1.0 : -1.0,
      ));
    }

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))..forward();
    _items = List.generate(8, (i) {
      final s = (0.1 + i * 0.1).clamp(0.0, 0.85);
      final e = (s + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _iconAnim = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);

    _confettiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _iconCtrl.dispose();
    _confettiCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Stack(children: [
        // Confetti
        ...List.generate(_particles.length, (i) {
          final p = _particles[i];
          return AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) {
              final t = ((_confettiCtrl.value - p.delay).clamp(0.0, 1.0));
              if (t == 0) return const SizedBox.shrink();
              return Positioned(
                left: MediaQuery.of(context).size.width * p.x,
                top: -120 * t + 40,
                child: Opacity(
                  opacity: (1 - t).clamp(0, 1),
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translate(p.drift * 40 * t, 0)
                      ..rotateZ(t * 2 * pi),
                    child: Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: p.color)),
                  ),
                ),
              );
            },
          );
        }),

        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 32),

            // Icon with pulsing rings
            _a(0, AnimatedBuilder(
              animation: _iconAnim,
              builder: (_, child) => Transform.scale(scale: _iconAnim.value, child: child),
              child: _PulsingRings(
                color: _kGreen, size: 100, count: 3,
                child: Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF009689), _kTeal],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(
                        color: _kTeal.withOpacity(0.4),
                        blurRadius: 30, spreadRadius: 6)]),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 40),
                ),
              ),
            )),
            const SizedBox(height: 24),

            _a(1, Text('Request Accepted!', style: TextStyle(
                color: _text(d), fontSize: 26, fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            _a(1, Text('You can now head to the pickup location',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted(d), fontSize: 15))),
            const SizedBox(height: 28),

            // Info card
            _a(2, Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _card(d), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border(d))),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Request ID', style: TextStyle(color: _muted(d), fontSize: 13)),
                  Text(widget.trip.id, style: TextStyle(
                      color: _text(d), fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
                Divider(color: _border(d), height: 24),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: _kGreen, shape: BoxShape.circle)),
                    Container(width: 1, height: 30, color: _muted(d)),
                    const Icon(Icons.location_on_rounded, color: _kAmber, size: 12),
                  ]),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.trip.pickup, style: TextStyle(
                        color: _text(d), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 14),
                    Text(widget.trip.dropoff, style: TextStyle(
                        color: _text(d), fontSize: 15, fontWeight: FontWeight.w600)),
                  ])),
                ]),
                Divider(color: _border(d), height: 24),
                // Earnings
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kAmber.withOpacity(0.25))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("You'll Earn", style: TextStyle(color: _muted(d), fontSize: 14)),
                    Text('${widget.trip.price.toInt()} EGP', style: const TextStyle(
                        color: _kAmber, fontSize: 20, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ]),
            )),
            const SizedBox(height: 16),

            // Next step
            _a(3, Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kTeal.withOpacity(d ? 0.1 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kTeal.withOpacity(0.25))),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kTeal.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.near_me_rounded, color: _kTeal, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Next Step', style: TextStyle(
                      color: _text(d), fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Navigate to the pickup location and confirm arrival',
                      style: TextStyle(color: _muted(d), fontSize: 13, height: 1.4)),
                ])),
              ]),
            )),
            const SizedBox(height: 20),

            _a(4, _GradBtn(
              label: 'Go to Pickup',
              icon: Icons.near_me_rounded,
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PickupScreen()),
                (route) => false,
              ),
            )),
            const SizedBox(height: 28),
          ]),
        ),
      ])),
    );
  }
}


// ══════════════════════════════════════════════════════
//  5. FINDING SHIPMENTS SCREEN — skeleton shimmer
// ══════════════════════════════════════════════════════
class FindingShipmentsScreen extends StatefulWidget {
  const FindingShipmentsScreen({super.key});
  @override
  State<FindingShipmentsScreen> createState() => _FindingShipmentsState();
}

class _FindingShipmentsState extends State<FindingShipmentsScreen>
    with TickerProviderStateMixin {
  // Search icon rotation (linear infinite)
  late AnimationController _rotateCtrl;

  // Truck badge bounce
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // Skeleton shimmer
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // Loading dots
  late AnimationController _dotsCtrl;
  int _dot = 0;

  // Entrance
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  @override
  void initState() {
    super.initState();

    // Search rotates 360° every 3s
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat();

    // Truck bounces y:[0,-4,0] scale:[1,1.1,1]
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _bounceAnim = Tween<double>(begin: 0, end: -4)
        .animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));

    // Shimmer sweep
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    // Dots pulse
    Stream.periodic(const Duration(milliseconds: 500))
        .listen((_) { if (mounted) setState(() => _dot = (_dot + 1) % 3); });

    // Entrance
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _items = List.generate(6, (i) {
      final s = (i * 0.1).clamp(0.0, 0.7);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _bounceCtrl.dispose();
    _shimmerCtrl.dispose();
    _entranceCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(children: [
        const SizedBox(height: 40),

        // Animated icon
        _a(0, Stack(alignment: Alignment.bottomRight, children: [
          // Outer rings
          _PulsingRings(
            color: _kTeal, size: 100, count: 2,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kTeal.withOpacity(0.1),
                border: Border.all(color: _kTeal.withOpacity(0.2))),
              // Rotating search icon
              child: AnimatedBuilder(
                animation: _rotateCtrl,
                builder: (_, child) => Transform.rotate(
                  angle: _rotateCtrl.value * 2 * pi, child: child),
                child: const Icon(Icons.search_rounded, color: _kTeal, size: 40),
              ),
            ),
          ),
          // Bouncing truck badge
          AnimatedBuilder(
            animation: _bounceCtrl,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _bounceAnim.value),
              child: Transform.scale(
                scale: 1.0 + (_bounceCtrl.value * 0.1).abs(),
                child: child),
            ),
            child: Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(
                  color: _kAmber, shape: BoxShape.circle),
              child: const Icon(Icons.local_shipping_outlined,
                  color: Colors.white, size: 16)),
          ),
        ])),
        const SizedBox(height: 24),

        _a(1, Text('Finding Nearby Shipments', style: TextStyle(
            color: _text(d), fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        // Pulsing loading text
        _a(1, AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (_, __) => Opacity(
            opacity: 0.6 + 0.4 * sin(_shimmerCtrl.value * 2 * pi),
            child: Text('Searching for available requests...',
                style: TextStyle(color: _muted(d), fontSize: 14)),
          ),
        )),
        const SizedBox(height: 32),

        // Skeleton cards with shimmer
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (_, i) => AnimatedBuilder(
            animation: _items[(i + 2).clamp(0, _items.length - 1)],
            builder: (_, child) {
              final v = _items[(i + 2).clamp(0, _items.length - 1)].value;
              return Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
              );
            },
            child: _SkeletonCard(isDark: d, shimmerAnim: _shimmerAnim, delay: i * 0.2),
          ),
        )),

        // Loading dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ...List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: i == _dot ? 20 : 8, height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: i == _dot ? _kTeal : _muted(d).withOpacity(0.4),
                borderRadius: BorderRadius.circular(4)))),
          ]),
        ),
      ])),
    );
  }
}

// Skeleton card with shimmer
class _SkeletonCard extends StatelessWidget {
  final bool isDark;
  final Animation<double> shimmerAnim;
  final double delay;
  const _SkeletonCard({required this.isDark, required this.shimmerAnim, required this.delay});

  @override
  Widget build(BuildContext context) {
    final skBg = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) {
        final shimX = (shimmerAnim.value - delay) * 200;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card(isDark), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border(isDark))),
          child: Stack(children: [
            // Content
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _sk(50, 50, skBg, circle: true),
                const SizedBox(width: 12),
                Expanded(child: Column(children: [
                  _sk(double.infinity, 14, skBg),
                  const SizedBox(height: 8),
                  _sk(150, 10, skBg),
                ])),
              ]),
              const SizedBox(height: 14),
              _sk(double.infinity, 10, skBg),
              const SizedBox(height: 8),
              _sk(200, 10, skBg),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _sk(double.infinity, 36, skBg)),
                const SizedBox(width: 10),
                Expanded(child: _sk(double.infinity, 36,
                    _kTeal.withOpacity(0.2))),
              ]),
            ]),
            // Shimmer overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Transform.translate(
                offset: Offset(shimX, 0),
                child: Container(
                  width: 60,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white10, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _sk(double w, double h, Color color, {bool circle = false}) =>
      Container(
        width: w, height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: circle
              ? BorderRadius.circular(100)
              : BorderRadius.circular(6)));
}


// ══════════════════════════════════════════════════════
//  6. NO REQUESTS SCREEN — pulsing radio waves
// ══════════════════════════════════════════════════════
class NoRequestsScreen extends StatefulWidget {
  const NoRequestsScreen({super.key});
  @override
  State<NoRequestsScreen> createState() => _NoRequestsState();
}

class _NoRequestsState extends State<NoRequestsScreen>
    with TickerProviderStateMixin {
  // Radio wave pulse
  late AnimationController _waveCtrl;

  // Inbox icon scale+rotate
  late AnimationController _iconCtrl;
  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconRotateAnim;

  // Entrance stagger
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  @override
  void initState() {
    super.initState();

    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();

    _iconCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);
    _iconScaleAnim = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));
    _iconRotateAnim = Tween<double>(begin: -0.087, end: 0.087)
        .animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.easeInOut));

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _items = List.generate(7, (i) {
      final s = (i * 0.09).clamp(0.0, 0.75);
      final e = (s + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _iconCtrl.dispose();
    _entranceCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          // Inbox with pulsing radio waves
          _a(0, SizedBox(
            width: 120, height: 120,
            child: Stack(alignment: Alignment.center, children: [
              // Outer wave
              AnimatedBuilder(
                animation: _waveCtrl,
                builder: (_, __) {
                  final t = _waveCtrl.value;
                  return Transform.scale(
                    scale: 1.0 + 0.6 * t,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kTeal.withOpacity(0.4 * (1 - t)),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Inner wave (delayed)
              AnimatedBuilder(
                animation: _waveCtrl,
                builder: (_, __) {
                  final t = (_waveCtrl.value + 0.4) % 1.0;
                  return Transform.scale(
                    scale: 1.0 + 0.3 * t,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _kTeal.withOpacity(0.3 * (1 - t)),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Icon
              AnimatedBuilder(
                animation: _iconCtrl,
                builder: (_, child) => Transform.scale(
                  scale: _iconScaleAnim.value,
                  child: Transform.rotate(
                    angle: _iconRotateAnim.value,
                    child: child,
                  ),
                ),
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _card(d),
                    border: Border.all(color: _kTeal.withOpacity(0.25)),
                    boxShadow: [BoxShadow(
                        color: _kTeal.withOpacity(0.12),
                        blurRadius: 20, spreadRadius: 4)]),
                  child: const Icon(Icons.move_to_inbox_outlined,
                      color: _kTeal, size: 46)),
              ),
              // Green signal badge
              Positioned(bottom: 2, right: 2, child: Container(
                width: 30, height: 30,
                decoration: const BoxDecoration(
                    color: _kGreen, shape: BoxShape.circle),
                child: const Icon(Icons.wifi_tethering_rounded,
                    color: Colors.white, size: 16))),
            ]),
          )),
          const SizedBox(height: 28),

          _a(1, Text('No Requests Available', style: TextStyle(
              color: _text(d), fontSize: 24, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          _a(1, Text('Stay online to receive new trips',
              style: TextStyle(color: _muted(d), fontSize: 15))),
          const SizedBox(height: 28),

          // Online status card (slide from left)
          _a(2, Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card(d), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border(d))),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.wifi_tethering_rounded,
                    color: _kGreen, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("You're Online & Ready", style: TextStyle(
                    color: _text(d), fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("We'll notify you when new shipments are available",
                    style: TextStyle(color: _muted(d), fontSize: 12, height: 1.4)),
              ])),
            ]),
          )),
          const SizedBox(height: 14),

          // Zone card
          _a(3, Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card(d), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border(d))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Current Zone', style: TextStyle(color: _muted(d), fontSize: 14)),
              Text('Downtown Area', style: TextStyle(
                  color: _text(d), fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 20),

          // Refresh + Go Offline
          _a(4, Row(children: [
            Expanded(child: _outlineBtn(
              Icons.refresh_rounded, 'Refresh', _kTeal, d,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const FindingShipmentsScreen())))),
            const SizedBox(width: 12),
            Expanded(child: _outlineBtn(
              Icons.power_settings_new_rounded, 'Go Offline', _muted(d), d,
              () => Navigator.popUntil(context, (r) => r.isFirst))),
          ])),
          const SizedBox(height: 14),

          _a(5, _GradBtn(
            label: 'Back to Home',
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
          )),
        ]),
      ))),
    );
  }

  Widget _outlineBtn(IconData icon, String label, Color c, bool d, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _card(d), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border(d))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: c, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
}


// ══════════════════════════════════════════════════════
//  7. REQUEST EXPIRED SCREEN — clock crossing line
// ══════════════════════════════════════════════════════
class RequestExpiredScreen extends StatefulWidget {
  const RequestExpiredScreen({super.key});
  @override
  State<RequestExpiredScreen> createState() => _RequestExpiredState();
}

class _RequestExpiredState extends State<RequestExpiredScreen>
    with TickerProviderStateMixin {
  // Crossing line scaleX 0→1
  late AnimationController _lineCtrl;
  late Animation<double> _lineAnim;

  // Background opacity pulse
  late AnimationController _bgPulseCtrl;

  // Entrance
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  @override
  void initState() {
    super.initState();

    _lineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..forward(from: 0);
    _lineAnim = CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOut);

    _bgPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _items = List.generate(6, (i) {
      final s = (i * 0.1).clamp(0.0, 0.7);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() {
    _lineCtrl.dispose();
    _bgPulseCtrl.dispose();
    _entranceCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          // Clock with crossing line
          _a(0, AnimatedBuilder(
            animation: _bgPulseCtrl,
            builder: (_, child) => Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _muted(d).withOpacity(0.12 + 0.05 * _bgPulseCtrl.value),
                border: Border.all(color: _muted(d).withOpacity(0.2))),
              child: child,
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(Icons.access_time_rounded, color: _muted(d), size: 56),
              // Animated crossing line
              AnimatedBuilder(
                animation: _lineAnim,
                builder: (_, __) => Transform.rotate(
                  angle: pi / 4,
                  child: Transform.scale(
                    scaleX: _lineAnim.value,
                    child: Container(
                      width: 80, height: 2.5,
                      decoration: BoxDecoration(
                        color: _muted(d),
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
            ]),
          )),
          const SizedBox(height: 28),

          _a(1, Text('Request Expired', style: TextStyle(
              color: _text(d), fontSize: 26, fontWeight: FontWeight.bold))),
          const SizedBox(height: 12),
          _a(2, Text('This shipment is no longer available',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted(d), fontSize: 15))),
          const SizedBox(height: 8),
          _a(2, Text(
            'The trader may have assigned it to another driver or cancelled',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted(d), fontSize: 14, height: 1.5))),
          const SizedBox(height: 28),

          _a(3, Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card(d), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border(d))),
            child: Text('Stay online to receive new trip requests from nearby traders',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted(d), fontSize: 14, height: 1.5)),
          )),
          const SizedBox(height: 24),

          _a(4, _GradBtn(
            label: 'Back to Home',
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
          )),
        ]),
      ))),
    );
  }
}


// ══════════════════════════════════════════════════════
//  8. CONNECTION LOST SCREEN — shake + pulsing rings
// ══════════════════════════════════════════════════════
class ConnectionLostScreen extends StatefulWidget {
  const ConnectionLostScreen({super.key});
  @override
  State<ConnectionLostScreen> createState() => _ConnectionLostState();
}

class _ConnectionLostState extends State<ConnectionLostScreen>
    with TickerProviderStateMixin {
  // Shake on wifi icon
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Retry button shimmer
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // Red dot pulse
  late AnimationController _dotCtrl;

  // Entrance
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;

  @override
  void initState() {
    super.initState();

    // Shake: rotate[0,-10,10,-10,0] once on load
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -0.175), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.175, end: 0.175), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.175, end: -0.175), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -0.175, end: 0), weight: 25),
    ]).animate(_shakeCtrl);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _shakeCtrl.forward();
    });

    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _shimmerAnim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));

    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _items = List.generate(7, (i) {
      final s = (i * 0.09).clamp(0.0, 0.75);
      final e = (s + 0.38).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _shimmerCtrl.dispose();
    _dotCtrl.dispose();
    _entranceCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          // Wifi icon with pulsing rings + shake
          _a(0, AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.rotate(
                angle: _shakeAnim.value, child: child),
            child: _PulsingRings(
              color: _kRed, size: 110, count: 2,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRed.withOpacity(0.1),
                  border: Border.all(color: _kRed.withOpacity(0.3))),
                child: const Icon(Icons.wifi_off_rounded, color: _kRed, size: 52)),
            ),
          )),
          const SizedBox(height: 28),

          _a(1, Text('Connection Lost', style: TextStyle(
              color: _text(d), fontSize: 26, fontWeight: FontWeight.bold))),
          const SizedBox(height: 10),
          _a(1, Text('Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted(d), fontSize: 15))),
          const SizedBox(height: 24),

          // Reasons card (slide from left)
          _a(2, Container(
            width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card(d), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border(d))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Possible Reasons:', style: TextStyle(
                  color: _text(d), fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...[
                'No internet connection',
                'Server is temporarily unavailable',
                'Your session may have expired',
              ].map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: _kRed, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(r, style: TextStyle(color: _muted(d), fontSize: 14)),
                ]),
              )),
            ]),
          )),
          const SizedBox(height: 16),

          // Pulsing offline dot
          _a(3, Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, __) => Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _kRed,
                  boxShadow: [BoxShadow(
                    color: _kRed.withOpacity(0.5 * _dotCtrl.value),
                    blurRadius: 6,
                  )],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('Unable to connect', style: TextStyle(color: _muted(d), fontSize: 14)),
          ])),
          const SizedBox(height: 24),

          // Retry button with rotating icon + shimmer
          _a(4, GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity, height: 56,
              decoration: BoxDecoration(
                gradient: _kGrad, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: _kTeal.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))]),
              child: Stack(alignment: Alignment.center, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _shimmerAnim,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(_shimmerAnim.value * 200, 0),
                      child: Container(width: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.white24, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Retry', style: TextStyle(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ]),
            ),
          )),
          const SizedBox(height: 12),
          _a(5, TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: Text('Back to Home', style: TextStyle(color: _muted(d), fontSize: 15)),
          )),
        ]),
      ))),
    );
  }
}


// ══════════════════════════════════════════════════════
//  9. FAILED TO LOAD SCREEN
// ══════════════════════════════════════════════════════
class FailedToLoadScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  const FailedToLoadScreen({
    super.key,
    this.title = 'Failed to load\nrequests',
    this.subtitle = 'Unable to fetch available requests. Please try again.',
    this.onRetry,
  });
  @override
  State<FailedToLoadScreen> createState() => _FailedToLoadState();
}

class _FailedToLoadState extends State<FailedToLoadScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late List<Animation<double>> _items;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _items = List.generate(5, (i) {
      final s = (i * 0.12).clamp(0.0, 0.7);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _entranceCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
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
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          // Error rings
          _a(0, _PulsingRings(
            color: _kRed, size: 110, count: 2,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, child) => Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRed.withOpacity(0.1 + 0.05 * _pulseCtrl.value)),
                child: child,
              ),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRed, width: 2)),
                child: const Center(child: Text('!', style: TextStyle(
                    color: _kRed, fontSize: 32, fontWeight: FontWeight.bold)))),
            ),
          )),
          const SizedBox(height: 28),

          _a(1, Text(widget.title, textAlign: TextAlign.center,
              style: TextStyle(color: _text(d), fontSize: 26,
                  fontWeight: FontWeight.bold, height: 1.3))),
          const SizedBox(height: 12),
          _a(2, Text(widget.subtitle, textAlign: TextAlign.center,
              style: TextStyle(color: _muted(d), fontSize: 15, height: 1.5))),
          const SizedBox(height: 32),

          _a(3, _GradBtn(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onTap: widget.onRetry ?? () => Navigator.pop(context),
          )),
        ]),
      ))),
    );
  }
}


// ══════════════════════════════════════════════════════
//  SHARED HELPERS
// ══════════════════════════════════════════════════════
Widget _routeTimeline(String pickup, String dropoff, bool d) =>
  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [
      Container(width: 10, height: 10,
          decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle)),
      Container(width: 2, height: 40, color: _kTeal.withOpacity(0.3)),
      const Icon(Icons.location_on_rounded, color: _kAmber, size: 14),
    ]),
    const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Pickup', style: TextStyle(color: _muted(d), fontSize: 11)),
      Text(pickup, style: TextStyle(color: _text(d), fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Text('Drop-off', style: TextStyle(color: _muted(d), fontSize: 11)),
      Text(dropoff, style: TextStyle(color: _text(d), fontSize: 16, fontWeight: FontWeight.bold)),
    ])),
  ]);

Widget _infoChip(IconData icon, String label, String value, bool d) =>
  Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: _chip(d), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border(d))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _kTeal, size: 13),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: _muted(d), fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(
          color: _text(d), fontSize: 14, fontWeight: FontWeight.bold)),
    ]),
  ));

Widget _detailRow(String label, String value, bool d) =>
  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(color: _muted(d), fontSize: 13)),
    Text(value, style: TextStyle(color: _text(d), fontSize: 13, fontWeight: FontWeight.w600)),
  ]);

Widget _infoLine(String label, String value, bool d) =>
  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Text(label, style: TextStyle(color: _muted(d), fontSize: 14)),
    Text(value, style: TextStyle(color: _text(d), fontSize: 14, fontWeight: FontWeight.w600)),
  ]);

Widget _sectionCard(bool d, Widget child) => Container(
  width: double.infinity, padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: _card(d), borderRadius: BorderRadius.circular(16),
    border: Border.all(color: _border(d))),
  child: child);

Widget _fullRoute(TripData t, bool d) => Row(
  crossAxisAlignment: CrossAxisAlignment.start, children: [
  Column(children: [
    Container(width: 10, height: 10,
        decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle)),
    Container(width: 2, height: 55, color: _kTeal.withOpacity(0.3)),
    const Icon(Icons.location_on_rounded, color: _kAmber, size: 14),
  ]),
  const SizedBox(width: 14),
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Pickup Location', style: TextStyle(color: _muted(d), fontSize: 11)),
    Text(t.pickup, style: TextStyle(color: _text(d), fontSize: 16, fontWeight: FontWeight.bold)),
    if (t.pickupAddr.isNotEmpty)
      Text(t.pickupAddr, style: TextStyle(color: _muted(d), fontSize: 13)),
    const SizedBox(height: 14),
    Text('Drop-off Location', style: TextStyle(color: _muted(d), fontSize: 11)),
    Text(t.dropoff, style: TextStyle(color: _text(d), fontSize: 16, fontWeight: FontWeight.bold)),
    if (t.dropoffAddr.isNotEmpty)
      Text(t.dropoffAddr, style: TextStyle(color: _muted(d), fontSize: 13)),
  ])),
]);

// ══════════════════════════════════════════════════════
//  CONFETTI PARTICLE
// ══════════════════════════════════════════════════════
class _ConfettiParticle {
  final Color color;
  final double x, delay, drift;
  const _ConfettiParticle({
    required this.color, required this.x,
    required this.delay, required this.drift,
  });
}
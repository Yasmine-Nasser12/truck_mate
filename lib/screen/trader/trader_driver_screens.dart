import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/screen/trader/payment_screens.dart';

// ══════════════════════════════════════════════════════
//  FILE: lib/screen/trader/trader_driver_screens.dart
// ══════════════════════════════════════════════════════

const Color _kTeal  = Color(0xFF00D5BE);
const Color _kGreen = Color(0xFF009689);
const Color _kRed   = Color(0xFFEF4444);
const Color _kAmber = Color(0xFFF5A623);

const _kGradient = LinearGradient(
  colors: [Color(0xFF009689), Color(0xFF00B8DB)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// ── Animation constants (same timing as RN driver home) ──
const Duration _kFast   = Duration(milliseconds: 300);
const Duration _kMed    = Duration(milliseconds: 500);
const Duration _kSlow   = Duration(milliseconds: 700);
const Duration _kStagger = Duration(milliseconds: 70);

const Curve _kEaseOutCubic = Curves.easeOutCubic;
const Curve _kEaseOutBack  = Curves.easeOutBack;
const Curve _kEaseInOut    = Curves.easeInOutCubic;

// Theme helpers
Color _bg(bool d)     => d ? const Color(0xFF0A1628) : const Color(0xFFF5F8FA);
Color _card(bool d)   => d ? const Color(0xFF0F2035) : Colors.white;
Color _border(bool d) => d ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
Color _text(bool d)   => d ? Colors.white : const Color(0xFF1A2A3A);
Color _muted(bool d)  => d ? const Color(0xFF6B8A9E) : const Color(0xFF8A9BB0);

// ── Custom slide-up page route (matches RN modal presentation) ──
Route<T> _slideUpRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMed,
  reverseTransitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) {
    final slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    final fade = CurvedAnimation(parent: anim, curve: _kEaseOutCubic);
    return SlideTransition(
        position: slide, child: FadeTransition(opacity: fade, child: child));
  },
);

// ── Slide-right route (RN stack push) ──
Route<T> _slideRightRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMed,
  reverseTransitionDuration: _kFast,
  transitionsBuilder: (_, anim, __, child) {
    final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    final fade = CurvedAnimation(parent: anim, curve: _kEaseOutCubic);
    return SlideTransition(
        position: slide, child: FadeTransition(opacity: fade, child: child));
  },
);

// ══════════════════════════════════════════════════════
//  ANIMATED TAP — scale 0.96 (RN TouchableOpacity)
// ══════════════════════════════════════════════════════
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

// ══════════════════════════════════════════════════════
//  STAGGERED LIST — each item fade+slide with delay
// ══════════════════════════════════════════════════════
class _StaggeredList extends StatefulWidget {
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final Duration initialDelay;
  const _StaggeredList({
    required this.count,
    required this.itemBuilder,
    this.initialDelay = const Duration(milliseconds: 200),
  });
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
      return Tween<Offset>(
          begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _ctrl,
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
//  SHARED WIDGETS
// ══════════════════════════════════════════════════════
Widget _backBtn(BuildContext ctx, bool d) => _Tap(
  onTap: () => Navigator.maybePop(ctx),
  child: Container(
    width: 42, height: 42,
    decoration: BoxDecoration(
      color: _card(d), shape: BoxShape.circle,
      border: Border.all(color: _border(d)),
    ),
    child: Icon(Icons.chevron_left_rounded,
        color: d ? Colors.white : const Color(0xFF1A2A3A), size: 24),
  ),
);

class _GradBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _GradBtn({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) => _Tap(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: _kGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _kTeal.withOpacity(0.35),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
        ],
        Text(label, style: const TextStyle(color: Colors.white,
            fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

// ═══════════════════ DATA MODELS ═══════════════════
class DriverModel {
  final String initials, name, vehicle;
  final double rating, price, distance;
  final int reviews;
  final bool isBestMatch;
  const DriverModel({
    required this.initials, required this.name, required this.vehicle,
    required this.rating, required this.price, required this.distance,
    required this.reviews, this.isBestMatch = false,
  });
}

const _kDrivers = [
  DriverModel(initials: 'AH', name: 'Ahmed Hassan',   rating: 4.9, reviews: 234,
      price: 240, distance: 2.4, vehicle: 'Pickup Truck', isBestMatch: true),
  DriverModel(initials: 'MA', name: 'Mohamed Ali',    rating: 4.8, reviews: 189,
      price: 220, distance: 3.1, vehicle: 'Van'),
  DriverModel(initials: 'KI', name: 'Khaled Ibrahim', rating: 4.7, reviews: 156,
      price: 250, distance: 4.5, vehicle: 'Pickup Truck'),
  DriverModel(initials: 'YA', name: 'Yasser Ahmed',   rating: 4.6, reviews: 143,
      price: 280, distance: 5.2, vehicle: 'Box Truck'),
];

enum OfferStatus { pending, accepted, rejected }

class OfferModel {
  final String initials, name, vehicle, timeAgo;
  final double rating, distance, price;
  final int etaMins;
  final OfferStatus status;
  const OfferModel({
    required this.initials, required this.name, required this.vehicle,
    required this.timeAgo, required this.rating, required this.distance,
    required this.price, required this.etaMins, required this.status,
  });
}

const _kOffers = [
  OfferModel(initials: 'AH', name: 'Ahmed Hassan', vehicle: 'Pickup Truck',
      timeAgo: '5 mins ago', rating: 4.9, distance: 2.4,
      price: 240, etaMins: 15, status: OfferStatus.pending),
  OfferModel(initials: 'MA', name: 'Mohamed Ali', vehicle: 'Van',
      timeAgo: '8 mins ago', rating: 4.8, distance: 3.1,
      price: 220, etaMins: 20, status: OfferStatus.pending),
  OfferModel(initials: 'KI', name: 'Khaled Ibrahim', vehicle: 'Pickup Truck',
      timeAgo: '12 mins ago', rating: 4.7, distance: 4.5,
      price: 250, etaMins: 25, status: OfferStatus.pending),
  OfferModel(initials: 'OY', name: 'Omar Youssef', vehicle: 'Box Truck',
      timeAgo: '2 hours ago', rating: 4.9, distance: 1.8,
      price: 260, etaMins: 10, status: OfferStatus.accepted),
  OfferModel(initials: 'TS', name: 'Tamer Said', vehicle: 'Van',
      timeAgo: '1 day ago', rating: 4.5, distance: 7.2,
      price: 300, etaMins: 40, status: OfferStatus.rejected),
];

// ══════════════════════════════════════════════════════
//  1. SUGGESTED DRIVERS SCREEN
// ══════════════════════════════════════════════════════
class SuggestedDriversScreen extends StatefulWidget {
  final String pickup, dropoff, date, time, packages, weight;
  const SuggestedDriversScreen({
    super.key,
    this.pickup = '', this.dropoff = '',
    this.date = '', this.time = '',
    this.packages = '', this.weight = '',
  });
  @override
  State<SuggestedDriversScreen> createState() => _SuggestedDriversScreenState();
}

class _SuggestedDriversScreenState extends State<SuggestedDriversScreen>
    with TickerProviderStateMixin {

  // ── Header fade+slide down (RN: Animated.timing translateY -20→0) ──
  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  // ── Banner scale+fade (RN: spring scale 0.9→1) ──
  late AnimationController _bannerCtrl;
  late Animation<double>   _bannerScale;
  late Animation<double>   _bannerFade;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(
        begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    _bannerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _bannerScale = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _bannerCtrl, curve: _kEaseOutBack));
    _bannerFade  = CurvedAnimation(parent: _bannerCtrl, curve: _kEaseOutCubic);

    _runSequence();
  }

  void _runSequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _bannerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── [0] Header — fade + slide down ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _backBtn(context, d),
                const SizedBox(width: 14),
                Text('Suggested Drivers', style: TextStyle(color: _text(d),
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── [1] Banner — scale bounce ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ScaleTransition(
            scale: _bannerScale,
            child: FadeTransition(
              opacity: _bannerFade,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: d ? _kTeal.withOpacity(0.08) : const Color(0xFFDFFAF6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kTeal.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_kDrivers.length} drivers available for your route',
                      style: TextStyle(
                          color: d ? _kTeal : const Color(0xFF0A5048),
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (widget.pickup.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('${widget.pickup} → ${widget.dropoff}',
                        style: TextStyle(color: _muted(d), fontSize: 12)),
                  ],
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── [2] Driver cards — staggered list ──
        Expanded(child: _StaggeredList(
          count: _kDrivers.length,
          initialDelay: const Duration(milliseconds: 250),
          itemBuilder: (_, i) {
            final drv = _kDrivers[i];
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, i < _kDrivers.length - 1 ? 14 : 4),
              child: _SuggestedDriverCard(
                driver: drv, isDark: d,
                onViewDetails: () => Navigator.push(context,
                    _slideRightRoute(DriverDetailsScreen(
                      driver: drv,
                      pickup: widget.pickup, dropoff: widget.dropoff,
                      date: widget.date, time: widget.time,
                      packages: widget.packages, weight: widget.weight,
                    ))),
                onSelect: () => Navigator.push(context,
                    _slideRightRoute(DriverOffersScreen(
                      selectedDriver: drv,
                      pickup: widget.pickup, dropoff: widget.dropoff,
                    ))),
              ),
            );
          },
        )),
      ])),
    );
  }
}

// ── Driver Card — with "Best Match" badge ──
class _SuggestedDriverCard extends StatelessWidget {
  final DriverModel driver;
  final bool isDark;
  final VoidCallback onViewDetails, onSelect;
  const _SuggestedDriverCard({required this.driver, required this.isDark,
      required this.onViewDetails, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card(isDark), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border(isDark)),
          boxShadow: isDark ? [] : [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 56, height: 56,
              decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(driver.initials, style: const TextStyle(
                  color: Color(0xFF0A1628), fontWeight: FontWeight.w700, fontSize: 18))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(driver.name, style: TextStyle(color: _text(isDark),
                  fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, color: _kAmber, size: 15),
                const SizedBox(width: 4),
                Text('${driver.rating}', style: const TextStyle(
                    color: _kAmber, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('(${driver.reviews} reviews)',
                    style: TextStyle(color: _muted(isDark), fontSize: 12)),
              ]),
            ])),
            Text('\$${driver.price.toInt()}', style: const TextStyle(
                color: _kTeal, fontSize: 22, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.location_on_outlined, color: _kTeal.withOpacity(0.7), size: 15),
            const SizedBox(width: 5),
            Text('${driver.distance} km away',
                style: TextStyle(color: _muted(isDark), fontSize: 13)),
            const SizedBox(width: 20),
            Icon(Icons.local_shipping_outlined, color: _kTeal.withOpacity(0.7), size: 15),
            const SizedBox(width: 5),
            Text(driver.vehicle, style: TextStyle(color: _muted(isDark), fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Tap(
              onTap: onViewDetails,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  border: Border.all(color: _border(isDark)),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('View Details',
                    style: TextStyle(color: _text(isDark), fontSize: 14)),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: _Tap(
              onTap: onSelect,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                    gradient: _kGradient,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Select Driver', style: TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ]),
              ),
            )),
          ]),
        ]),
      ),
      if (driver.isBestMatch)
        Positioned(top: -1, right: -1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: _kTeal,
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(12))),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_outlined, color: Color(0xFF0A1628), size: 13),
              SizedBox(width: 4),
              Text('Best Match', style: TextStyle(color: Color(0xFF0A1628),
                  fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
          )),
    ]);
  }
}

// ══════════════════════════════════════════════════════
//  2. NO DRIVERS
// ══════════════════════════════════════════════════════
class NoDriversScreen extends StatefulWidget {
  const NoDriversScreen({super.key});
  @override
  State<NoDriversScreen> createState() => _NoDriversScreenState();
}

class _NoDriversScreenState extends State<NoDriversScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: _kSlow);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: _kEaseOutBack));
    _fade  = CurvedAnimation(parent: _ctrl, curve: _kEaseOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: Center(child: ScaleTransition(
        scale: _scale,
        child: FadeTransition(
          opacity: _fade,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 100, height: 100,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _kTeal.withOpacity(0.1)),
              child: const Icon(Icons.local_shipping_outlined,
                  color: _kTeal, size: 46)),
            const SizedBox(height: 32),
            Text('No drivers\navailable yet', textAlign: TextAlign.center,
                style: TextStyle(color: _text(d), fontSize: 26,
                    fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 14),
            Text('Please wait while we find\ndrivers for your shipment',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted(d), fontSize: 15)),
          ]),
        ),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════
//  3. LOADING SKELETON  (shimmer pulse — same as RN)
// ══════════════════════════════════════════════════════
class DriversLoadingScreen extends StatefulWidget {
  const DriversLoadingScreen({super.key});
  @override
  State<DriversLoadingScreen> createState() => _DriversLoadingState();
}

class _DriversLoadingState extends State<DriversLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Widget _shimmer(double h, double r, double op, bool d) => Opacity(
    opacity: op,
    child: Container(width: double.infinity, height: h,
      decoration: BoxDecoration(
        color: d ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0),
        borderRadius: BorderRadius.circular(r))),
  );

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const SizedBox(height: 12),
            _shimmer(48, 14, _anim.value, d),
            const SizedBox(height: 20),
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: _card(d),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border(d))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _shimmer(20, 6, _anim.value, d),
                  const SizedBox(height: 10),
                  _shimmer(14, 6, _anim.value * 0.7, d),
                  const SizedBox(height: 8),
                  _shimmer(14, 6, _anim.value * 0.5, d),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Container(height: 44,
                      decoration: BoxDecoration(color: _kTeal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(width: 12),
                    Expanded(child: Container(height: 44,
                      decoration: BoxDecoration(color: _kRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12)))),
                  ]),
                ]),
              ),
            )),
          ]),
        ),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════
//  4. ERROR
// ══════════════════════════════════════════════════════
class DriversErrorScreen extends StatefulWidget {
  const DriversErrorScreen({super.key});
  @override
  State<DriversErrorScreen> createState() => _DriversErrorScreenState();
}

class _DriversErrorScreenState extends State<DriversErrorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: _kSlow);
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: _kEaseOutBack));
    _fade  = CurvedAnimation(parent: _ctrl, curve: _kEaseOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    return Scaffold(
      backgroundColor: _bg(d),
      body: Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _fade,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _kRed.withOpacity(0.12)),
                child: const Icon(Icons.error_outline_rounded,
                    color: _kRed, size: 46)),
              const SizedBox(height: 32),
              Text('Failed to load\ndrivers', textAlign: TextAlign.center,
                  style: TextStyle(color: _text(d), fontSize: 26,
                      fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 14),
              Text('Unable to fetch available drivers. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted(d), fontSize: 15)),
              const SizedBox(height: 40),
              _GradBtn(label: 'Retry',
                  onTap: () => Navigator.pushReplacement(context,
                      _slideRightRoute(const SuggestedDriversScreen()))),
            ]),
          ),
        ),
      )),
    );
  }
}

// ══════════════════════════════════════════════════════
//  5. DRIVER OFFERS SCREEN
// ══════════════════════════════════════════════════════
class DriverOffersScreen extends StatefulWidget {
  final DriverModel? selectedDriver;
  final String pickup, dropoff;
  const DriverOffersScreen({
    super.key, this.selectedDriver,
    this.pickup = '', this.dropoff = '',
  });
  @override
  State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen>
    with TickerProviderStateMixin {
  int _tab = 0;

  // ── Header entry ──
  late AnimationController _headerCtrl;
  late Animation<double>   _headerFade;
  late Animation<Offset>   _headerSlide;

  // ── Tab bar entry ──
  late AnimationController _tabBarCtrl;
  late Animation<double>   _tabBarFade;
  late Animation<Offset>   _tabBarSlide;

  // ── Content fade on tab switch ──
  late AnimationController _contentCtrl;
  late Animation<double>   _contentFade;

  List<OfferModel> get _filtered => _kOffers.where((o) {
    if (_tab == 0) return o.status == OfferStatus.pending;
    if (_tab == 1) return o.status == OfferStatus.accepted;
    return o.status == OfferStatus.rejected;
  }).toList();

  int get _pc => _kOffers.where((o) => o.status == OfferStatus.pending).length;
  int get _ac => _kOffers.where((o) => o.status == OfferStatus.accepted).length;
  int get _rc => _kOffers.where((o) => o.status == OfferStatus.rejected).length;

  @override
  void initState() {
    super.initState();

    _headerCtrl  = AnimationController(vsync: this, duration: _kMed);
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: _kEaseOutCubic));

    _tabBarCtrl  = AnimationController(vsync: this, duration: _kMed);
    _tabBarFade  = CurvedAnimation(parent: _tabBarCtrl, curve: _kEaseOutCubic);
    _tabBarSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _tabBarCtrl, curve: _kEaseOutCubic));

    _contentCtrl = AnimationController(vsync: this, duration: _kFast);
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: _kEaseInOut);

    _runSequence();
  }

  void _runSequence() async {
    _headerCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _tabBarCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    _contentCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _tabBarCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _switchTab(int i) async {
    if (i == _tab) return;
    await _contentCtrl.reverse();
    setState(() => _tab = i);
    _contentCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(children: [

        // ── [0] Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FadeTransition(
            opacity: _headerFade,
            child: SlideTransition(
              position: _headerSlide,
              child: Row(children: [
                _backBtn(context, d),
                const SizedBox(width: 14),
                Text('Driver Offers', style: TextStyle(color: _text(d),
                    fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── [1] Tab bar — slide up ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FadeTransition(
            opacity: _tabBarFade,
            child: SlideTransition(
              position: _tabBarSlide,
              child: Row(children: [
                _tabChip(label: 'Pending',  count: _pc,
                    active: _tab == 0, onTap: () => _switchTab(0)),
                const SizedBox(width: 10),
                _tabChip(label: 'Accepted', count: _ac,
                    active: _tab == 1, onTap: () => _switchTab(1)),
                const SizedBox(width: 10),
                _tabChip(label: 'Rejected', count: _rc,
                    active: _tab == 2, onTap: () => _switchTab(2)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── [2] Offer cards — fade on switch + staggered entry ──
        Expanded(
          child: FadeTransition(
            opacity: _contentFade,
            child: filtered.isEmpty
              ? Center(child: Text('No offers here',
                  style: TextStyle(color: _muted(d))))
              : _StaggeredList(
                  count: filtered.length,
                  initialDelay: Duration.zero,
                  itemBuilder: (_, i) {
                    final offer = filtered[i];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16,
                          i < filtered.length - 1 ? 14 : 4),
                      child: _OfferCard(
                        offer: offer, isDark: d,
                        showActions: _tab == 0,
                        onAccept: () => Navigator.push(context,
                            _slideUpRoute(PaymentMethodsSelectScreen(
                              driverName: offer.name,
                              price: offer.price,
                            ))),
                      ),
                    );
                  },
                ),
          ),
        ),
      ])),
    );
  }

  Widget _tabChip({required String label, required int count,
      required bool active, required VoidCallback onTap}) =>
    _Tap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: _kFast,
        curve: _kEaseOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? _kGradient : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? Colors.transparent : const Color(0xFF1A3550))),
        child: Row(children: [
          Text(label, style: TextStyle(
              color: active ? Colors.white : const Color(0xFF6B8A9E),
              fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withOpacity(0.25)
                  : const Color(0xFF1A3550),
              shape: BoxShape.circle),
            child: Text('$count', style: TextStyle(
                color: active ? Colors.white : const Color(0xFF6B8A9E),
                fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    );
}

// ── Offer Card ──
class _OfferCard extends StatelessWidget {
  final OfferModel offer;
  final bool isDark, showActions;
  final VoidCallback? onAccept;
  const _OfferCard({required this.offer, required this.isDark,
      required this.showActions, this.onAccept});

  @override
  Widget build(BuildContext context) {
    final statusColor = offer.status == OfferStatus.accepted ? _kTeal
        : offer.status == OfferStatus.rejected ? _kRed : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card(isDark), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border(isDark)),
        boxShadow: isDark ? [] : [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 52, height: 52,
            decoration: const BoxDecoration(color: _kTeal, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(offer.initials, style: const TextStyle(
                color: Color(0xFF0A1628), fontWeight: FontWeight.w700, fontSize: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(offer.name, style: TextStyle(color: _text(isDark),
                fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star, color: _kAmber, size: 14),
              const SizedBox(width: 4),
              Text('${offer.rating}', style: const TextStyle(
                  color: _kAmber, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('  •  ${offer.timeAgo}',
                  style: TextStyle(color: _muted(isDark), fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined, color: _kTeal.withOpacity(0.7), size: 13),
              Text(' ${offer.distance} km  ',
                  style: TextStyle(color: _muted(isDark), fontSize: 12)),
              Text(offer.vehicle,
                  style: TextStyle(color: _muted(isDark), fontSize: 12)),
            ]),
          ])),
          if (statusColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.4))),
              child: Text(
                offer.status == OfferStatus.accepted ? 'Accepted' : 'Rejected',
                style: TextStyle(color: statusColor, fontSize: 12,
                    fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Offer Price', style: TextStyle(color: _muted(isDark), fontSize: 12)),
            const SizedBox(height: 4),
            Text('\$${offer.price.toInt()}', style: const TextStyle(
                color: _kTeal, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('ETA', style: TextStyle(color: _muted(isDark), fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.access_time_rounded, color: _kTeal.withOpacity(0.7), size: 16),
              const SizedBox(width: 4),
              Text('${offer.etaMins} mins', style: TextStyle(
                  color: _text(isDark), fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ]),
        if (showActions) ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Tap(
              onTap: () {},
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kRed.withOpacity(0.3))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.cancel_outlined, color: _kRed, size: 16),
                  SizedBox(width: 6),
                  Text('Reject', style: TextStyle(
                      color: _kRed, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: _Tap(
              onTap: onAccept,
              child: Container(
                height: 44,
                decoration: BoxDecoration(gradient: _kGradient,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Accept', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
                ]),
              ),
            )),
          ]),
        ],
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════
//  6. DRIVER DETAILS SCREEN
// ══════════════════════════════════════════════════════
class DriverDetailsScreen extends StatefulWidget {
  final DriverModel driver;
  final String pickup, dropoff, date, time, packages, weight;
  const DriverDetailsScreen({
    super.key, required this.driver,
    this.pickup = '', this.dropoff = '',
    this.date = '', this.time = '',
    this.packages = '', this.weight = '',
  });
  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen>
    with TickerProviderStateMixin {

  // ── Profile card — scale bounce from top ──
  late AnimationController _profileCtrl;
  late Animation<double>   _profileScale;
  late Animation<double>   _profileFade;

  // ── Stats row — counter-up feel (scale from 0.8) ──
  late AnimationController _statsCtrl;
  late Animation<double>   _statsScale;
  late Animation<double>   _statsFade;

  // ── Content sections — staggered ──
  late AnimationController _contentCtrl;
  late List<Animation<double>> _sectionFade;
  late List<Animation<Offset>> _sectionSlide;

  // ── Bottom button — slide up ──
  late AnimationController _btnCtrl;
  late Animation<Offset>   _btnSlide;
  late Animation<double>   _btnFade;

  static const int _kSections = 3; // truck info, reviews title, reviews list

  @override
  void initState() {
    super.initState();

    // Profile card
    _profileCtrl  = AnimationController(vsync: this, duration: _kMed);
    _profileScale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _profileCtrl, curve: _kEaseOutBack));
    _profileFade  = CurvedAnimation(parent: _profileCtrl, curve: _kEaseOutCubic);

    // Stats
    _statsCtrl  = AnimationController(vsync: this, duration: _kMed);
    _statsScale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: _kEaseOutBack));
    _statsFade  = CurvedAnimation(parent: _statsCtrl, curve: _kEaseOutCubic);

    // Content sections
    final totalMs = 350 + _kSections * _kStagger.inMilliseconds;
    _contentCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));
    _sectionFade  = List.generate(_kSections, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _contentCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _sectionSlide = List.generate(_kSections, (i) {
      final s = (i * _kStagger.inMilliseconds) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
          .animate(CurvedAnimation(parent: _contentCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    // Bottom button
    _btnCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic));
    _btnFade  = CurvedAnimation(parent: _btnCtrl, curve: _kEaseOutCubic);

    _runSequence();
  }

  void _runSequence() async {
    _profileCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _statsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _contentCtrl.forward();
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _profileCtrl.dispose();
    _statsCtrl.dispose();
    _contentCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  static const _reviews = [
    (name: 'Sarah Ahmed',  stars: 5, date: 'Dec 15, 2024',
     body: 'Very professional and delivered on time. Highly recommended!'),
    (name: 'Omar Khaled',  stars: 5, date: 'Dec 10, 2024',
     body: 'Excellent service, careful with packages.'),
    (name: 'Mona Hassan',  stars: 4, date: 'Dec 5, 2024',
     body: 'Good driver, arrived a bit late but overall good experience.'),
  ];

  Widget _section(int i, Widget child) => FadeTransition(
    opacity: _sectionFade[i],
    child: SlideTransition(position: _sectionSlide[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(children: [

        // ── Header (static, instant) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            _backBtn(context, d),
            const SizedBox(width: 14),
            Text('Driver Details', style: TextStyle(color: _text(d),
                fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 20),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── [0] Profile card — bounce scale ──
            ScaleTransition(
              scale: _profileScale,
              child: FadeTransition(
                opacity: _profileFade,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: _card(d),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border(d)),
                      boxShadow: d ? [] : [BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10, offset: const Offset(0, 3))]),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 72, height: 72,
                        decoration: const BoxDecoration(
                            color: _kTeal, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(widget.driver.initials, style: const TextStyle(
                            color: Color(0xFF0A1628),
                            fontWeight: FontWeight.w700, fontSize: 22))),
                      const SizedBox(width: 16),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.driver.name, style: TextStyle(
                              color: _text(d), fontSize: 20,
                              fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.star, color: _kAmber, size: 16),
                            const SizedBox(width: 4),
                            Text('${widget.driver.rating}', style: const TextStyle(
                                color: _kAmber, fontWeight: FontWeight.w600)),
                            Text('  (${widget.driver.reviews} reviews)',
                                style: TextStyle(color: _muted(d), fontSize: 13)),
                          ]),
                          const SizedBox(height: 6),
                          const Row(children: [
                            Icon(Icons.verified_outlined, color: _kTeal, size: 14),
                            SizedBox(width: 4),
                            Text('Verified Driver',
                                style: TextStyle(color: _kTeal, fontSize: 13)),
                          ]),
                        ],
                      )),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Total Cost',
                            style: TextStyle(color: _muted(d), fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('\$${widget.driver.price.toInt()}',
                            style: const TextStyle(color: _kTeal,
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ]),
                    ]),
                    const SizedBox(height: 20),

                    // ── Stats row — scale bounce ──
                    ScaleTransition(
                      scale: _statsScale,
                      child: FadeTransition(
                        opacity: _statsFade,
                        child: Row(children: [
                          _statItem('Trips', '189', d),
                          Container(width: 1, height: 40,
                              color: _border(d).withOpacity(0.5)),
                          _statItem('Years', '4', d),
                          Container(width: 1, height: 40,
                              color: _border(d).withOpacity(0.5)),
                          _statItem('Away', '${widget.driver.distance} km', d),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── [1] Truck info — staggered ──
            _section(0, Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card(d),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border(d))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: _kTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.local_shipping_outlined,
                        color: _kTeal, size: 20)),
                  const SizedBox(width: 12),
                  Text('Truck Information', style: TextStyle(color: _text(d),
                      fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 16),
                _infoRow('Type', widget.driver.vehicle, d),
                const SizedBox(height: 10),
                _infoRow('Model', '—', d),
                const SizedBox(height: 10),
                _infoRow('License Plate', '—', d),
              ]),
            )),
            const SizedBox(height: 20),

            // ── [2] Reviews title ──
            _section(1, Text('Recent Reviews', style: TextStyle(color: _text(d),
                fontSize: 18, fontWeight: FontWeight.bold))),
            const SizedBox(height: 12),

            // ── [3] Review cards — staggered ──
            _section(2, _StaggeredList(
              count: _reviews.length,
              initialDelay: const Duration(milliseconds: 100),
              itemBuilder: (_, i) {
                final r = _reviews[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _card(d),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border(d))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text(r.name, style: TextStyle(color: _text(d),
                            fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Row(children: List.generate(5, (j) => Icon(
                            j < r.stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: _kAmber, size: 14))),
                      ]),
                      const SizedBox(height: 6),
                      Text(r.body, style: TextStyle(color: _text(d), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(r.date,
                          style: TextStyle(color: _muted(d), fontSize: 11)),
                    ]),
                  ),
                );
              },
            )),
          ]),
        )),

        // ── Bottom button — slide up ──
        SlideTransition(
          position: _btnSlide,
          child: FadeTransition(
            opacity: _btnFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _GradBtn(
                label: 'Choose Driver',
                icon: Icons.check_circle_outline_rounded,
                onTap: () => Navigator.push(context,
                    _slideUpRoute(PaymentMethodsSelectScreen(
                      driverName: widget.driver.name,
                      price: widget.driver.price,
                    ))),
              ),
            ),
          ),
        ),
      ])),
    );
  }

  Widget _statItem(String label, String value, bool d) =>
    Expanded(child: Column(children: [
      Text(label, style: TextStyle(color: _muted(d), fontSize: 12)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: _kTeal, fontSize: 18,
          fontWeight: FontWeight.bold)),
    ]));

  Widget _infoRow(String label, String value, bool d) =>
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: _muted(d), fontSize: 14)),
      Text(value, style: TextStyle(color: _text(d), fontSize: 14,
          fontWeight: FontWeight.w600)),
    ]);
}

// ══════════════════════════════════════════════════════
//  7. SHIPMENT DETAILS SCREEN
// ══════════════════════════════════════════════════════
class ShipmentDetailsScreen extends StatefulWidget {
  final String shipmentId, pickup, dropoff, date, time, packages, weight;
  const ShipmentDetailsScreen({
    super.key,
    this.shipmentId = 'TM-2I8KIDJ70',
    this.pickup = 'Not set', this.dropoff = 'Not set',
    this.date = '2025-12-02', this.time = '02:23',
    this.packages = '1', this.weight = '11 lbs',
  });
  @override
  State<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<ShipmentDetailsScreen>
    with TickerProviderStateMixin {

  // ── Status badge — scale bounce ──
  late AnimationController _badgeCtrl;
  late Animation<double>   _badgeScale;
  late Animation<double>   _badgeFade;

  // ── Shipment ID — fade in ──
  late AnimationController _idCtrl;
  late Animation<double>   _idFade;

  // ── Cards — staggered slide up ──
  static const int _kCards = 3;
  late AnimationController _cardsCtrl;
  late List<Animation<double>> _cardFade;
  late List<Animation<Offset>> _cardSlide;

  // ── Bottom buttons — slide up together ──
  late AnimationController _btnsCtrl;
  late Animation<Offset>   _btnsSlide;
  late Animation<double>   _btnsFade;

  @override
  void initState() {
    super.initState();

    _badgeCtrl  = AnimationController(vsync: this, duration: _kMed);
    _badgeScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _badgeCtrl, curve: _kEaseOutBack));
    _badgeFade  = CurvedAnimation(parent: _badgeCtrl, curve: _kEaseOutCubic);

    _idCtrl = AnimationController(vsync: this, duration: _kMed);
    _idFade = CurvedAnimation(parent: _idCtrl, curve: _kEaseOutCubic);

    final totalMs = 400 + _kCards * 90;
    _cardsCtrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: totalMs));
    _cardFade  = List.generate(_kCards, (i) {
      final s = (i * 90) / totalMs;
      final e = (s + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _cardSlide = List.generate(_kCards, (i) {
      final s = (i * 90) / totalMs;
      final e = (s + 0.55).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _cardsCtrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    _btnsCtrl  = AnimationController(vsync: this, duration: _kMed);
    _btnsSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _btnsCtrl, curve: _kEaseOutCubic));
    _btnsFade  = CurvedAnimation(parent: _btnsCtrl, curve: _kEaseOutCubic);

    _runSequence();
  }

  void _runSequence() async {
    _badgeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 120));
    _idCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _cardsCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _btnsCtrl.forward();
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    _idCtrl.dispose();
    _cardsCtrl.dispose();
    _btnsCtrl.dispose();
    super.dispose();
  }

  Widget _card(int i, Widget child) => FadeTransition(
    opacity: _cardFade[i],
    child: SlideTransition(position: _cardSlide[i], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeProvider>().isDark;
    final kBg2  = d ? const Color(0xFF0A1628).withOpacity(0.6) : Colors.white;
    final kBdr2 = d
        ? const Color(0xFF00D5BE).withOpacity(0.1)
        : const Color(0xFFE2EAF0);

    cardDeco(Widget child) => Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kBg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBdr2),
          boxShadow: d ? [] : [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))]),
      child: child);

    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [

          // ── Header (instant) ──
          Row(children: [
            _backBtn(context, d),
            Expanded(child: Center(child: Text('Shipment Details',
                style: TextStyle(color: _text(d), fontSize: 20,
                    fontWeight: FontWeight.bold)))),
            const SizedBox(width: 42),
          ]),
          const SizedBox(height: 20),

          // ── Status badge — bounce ──
          ScaleTransition(
            scale: _badgeScale,
            child: FadeTransition(
              opacity: _badgeFade,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFB800).withOpacity(0.3))),
                child: const Text('Pending', style: TextStyle(
                    color: Color(0xFFFFB800),
                    fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Shipment ID — fade ──
          FadeTransition(
            opacity: _idFade,
            child: Column(children: [
              Text('Shipment ID', style: TextStyle(color: _muted(d), fontSize: 12)),
              const SizedBox(height: 4),
              Text(widget.shipmentId, style: TextStyle(color: _muted(d),
                  fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(height: 24),

          // ── [0] Timeline card ──
          _card(0, cardDeco(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Timeline', style: TextStyle(color: _text(d),
                fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _tl('Created', '4/16/2026, 12:00:40 AM', true, true, false, d),
            _tl('Pending Driver', 'Waiting...', false, false, false, d),
            _tl('In Progress', 'Pending', false, false, false, d),
            _tl('Delivered', 'Pending', false, false, true, d),
          ]))),
          const SizedBox(height: 20),

          // ── [1] Route card ──
          _card(1, cardDeco(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Route Details', style: TextStyle(color: _text(d),
                fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                _dot(_kTeal),
                Container(width: 2, height: 40, color: _kTeal),
                _dot(const Color(0xFF00B8DB)),
              ]),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pickup', style: TextStyle(color: _muted(d), fontSize: 12)),
                const SizedBox(height: 4),
                Text(widget.pickup, style: TextStyle(color: _text(d),
                    fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 18),
                Text('Drop-off', style: TextStyle(color: _muted(d), fontSize: 12)),
                const SizedBox(height: 4),
                Text(widget.dropoff, style: TextStyle(color: _text(d),
                    fontSize: 17, fontWeight: FontWeight.w600)),
              ])),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _dtItem(
                  'Scheduled Date', Icons.calendar_today, widget.date, d)),
              Expanded(child: _dtItem(
                  'Time', Icons.access_time, widget.time, d)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _dtItem(
                  'Packages', Icons.inventory_2_outlined, widget.packages, d)),
              Expanded(child: _dtItem(
                  'Weight', Icons.scale_outlined, widget.weight, d)),
            ]),
          ]))),
          const SizedBox(height: 20),

          // ── [2] Cost card ──
          _card(2, cardDeco(Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Cost', style: TextStyle(color: _muted(d), fontSize: 16)),
              const Text('240', style: TextStyle(color: _kTeal,
                  fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ))),
          const SizedBox(height: 20),

          // ── Bottom buttons — slide up ──
          SlideTransition(
            position: _btnsSlide,
            child: FadeTransition(
              opacity: _btnsFade,
              child: Column(children: [
                _GradBtn(
                  label: 'View Available Drivers',
                  icon: Icons.people_outline,
                  onTap: () => Navigator.push(context,
                      _slideRightRoute(SuggestedDriversScreen(
                        pickup: widget.pickup, dropoff: widget.dropoff,
                        date: widget.date, time: widget.time,
                        packages: widget.packages, weight: widget.weight,
                      ))),
                ),
                const SizedBox(height: 12),
                _Tap(
                  onTap: () => Navigator.push(context,
                      _slideRightRoute(const DriverOffersScreen())),
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      color: d ? const Color(0xFF0F2A3A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: d
                              ? _kTeal.withOpacity(0.2)
                              : const Color(0xFFE2EAF0))),
                    alignment: Alignment.center,
                    child: Text('View Offers', style: TextStyle(
                        color: _text(d), fontSize: 16,
                        fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      )),
    );
  }

  Widget _dot(Color c) => Container(width: 12, height: 12,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle));

  Widget _tl(String title, String sub, bool done, bool first, bool last, bool d) =>
    Row(children: [
      Column(children: [
        if (!first) Container(width: 2, height: 28,
            color: done ? _kTeal : _border(d)),
        Container(width: 26, height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: done ? _kTeal : Colors.transparent,
            border: Border.all(
                color: done ? _kTeal : _border(d), width: 2)),
          child: done
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null),
        if (!last) Container(width: 2, height: 28,
            color: done ? _kTeal : _border(d)),
      ]),
      const SizedBox(width: 16),
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(
              color: done ? _text(d) : _muted(d),
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: _muted(d), fontSize: 12)),
        ]),
      )),
    ]);

  Widget _dtItem(String label, IconData icon, String value, bool d) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _muted(d), fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        Icon(icon, color: _kTeal, size: 15),
        const SizedBox(width: 6),
        Text(value, style: TextStyle(color: _text(d), fontSize: 13,
            fontWeight: FontWeight.w600)),
      ]),
    ]);
}
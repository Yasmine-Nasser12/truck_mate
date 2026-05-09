import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '/providers/user_provider.dart';
import '/providers/theme_provider.dart';
import '/models/trader_models.dart';
import '/data/trader_dummy_data.dart';
import '/screen/trader/trader_ui.dart';
import '/screen/trader/trader_new_shipment_screen.dart';
import '/screen/trader/trader_rating_screen.dart';

// ══════════════════════════════════════════════════════════
//  ANIMATION CONSTANTS — same timing as RN driver home
// ══════════════════════════════════════════════════════════
const Duration _kFastAnim   = Duration(milliseconds: 350);
const Duration _kMedAnim    = Duration(milliseconds: 500);
const Duration _kSlowAnim   = Duration(milliseconds: 700);
const Duration _kStagger    = Duration(milliseconds: 80);

// ── Shared easing curves matching RN Easing.out(Easing.cubic) ──
const Curve _kEaseOutCubic  = Curves.easeOutCubic;
const Curve _kEaseOutBack   = Curves.easeOutBack;
const Curve _kEaseInOut     = Curves.easeInOutCubic;

class TraderHomeScreen extends StatefulWidget {
  const TraderHomeScreen({super.key});
  @override
  State<TraderHomeScreen> createState() => _TraderHomeScreenState();
}

class _TraderHomeScreenState extends State<TraderHomeScreen>
    with TickerProviderStateMixin {
  late List<Shipment> _shipments;
  late List<DriverOffer> _offers;
  late List<TraderNotification> _notifications;
  int _currentIndex = 0;

  // ── Page-level animation controllers ──
  late AnimationController _pageEnterCtrl;   // whole page fade+slide on mount
  late AnimationController _bottomNavCtrl;   // bottom nav slide-up on mount
  late AnimationController _tabSwitchCtrl;   // page-switch fade

  // ── Hero card specific ──
  late AnimationController _heroScaleCtrl;   // bounce scale on entry

  // ── Progress bar pulse ──
  late AnimationController _pulseCtrl;       // infinite pulse on progress bar

  // ── Staggered entry animations for dashboard elements ──
  late AnimationController _staggerCtrl;

  // ── Derived animations ──
  late Animation<double> _pageOpacity;
  late Animation<Offset> _pageSlide;
  late Animation<Offset> _bottomNavSlide;
  late Animation<double> _tabFade;
  late Animation<double> _heroScale;
  late Animation<double> _heroBounce;
  late Animation<double> _pulseOpacity;

  // ── Per-element stagger offsets (7 elements: header, hero, details, progress,
  //    driver row, create card, recent) ──
  static const int _kStaggerCount = 7;
  late List<Animation<double>> _staggerFade;
  late List<Animation<Offset>> _staggerSlide;

  @override
  void initState() {
    super.initState();

    _shipments     = TraderDummyData.shipments();
    _offers        = TraderDummyData.offers(_shipments);
    _notifications = TraderDummyData.notifications();

    // ─── Page enter ──────────────────────────────────────
    _pageEnterCtrl = AnimationController(vsync: this, duration: _kSlowAnim);
    _pageOpacity = CurvedAnimation(parent: _pageEnterCtrl, curve: _kEaseOutCubic);
    _pageSlide   = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _pageEnterCtrl, curve: _kEaseOutCubic));

    // ─── Bottom nav slide-up ─────────────────────────────
    _bottomNavCtrl = AnimationController(vsync: this, duration: _kMedAnim);
    _bottomNavSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bottomNavCtrl, curve: _kEaseOutCubic));

    // ─── Page / tab switch ───────────────────────────────
    _tabSwitchCtrl = AnimationController(vsync: this, duration: _kFastAnim);
    _tabFade = CurvedAnimation(parent: _tabSwitchCtrl, curve: _kEaseInOut);

    // ─── Hero card bounce ────────────────────────────────
    _heroScaleCtrl = AnimationController(vsync: this, duration: _kMedAnim);
    _heroScale  = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _heroScaleCtrl, curve: _kEaseOutBack));
    _heroBounce = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _heroScaleCtrl, curve: _kEaseOutCubic));

    // ─── Progress bar pulse ──────────────────────────────
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseOpacity = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ─── Staggered elements ──────────────────────────────
    _staggerCtrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 350 + _kStaggerCount * _kStagger.inMilliseconds));

    _staggerFade  = List.generate(_kStaggerCount, (i) {
      final start = (i * _kStagger.inMilliseconds) /
          _staggerCtrl.duration!.inMilliseconds;
      final end = math.min(start + 0.45, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
              parent: _staggerCtrl,
              curve: Interval(start, end, curve: _kEaseOutCubic)));
    });

    _staggerSlide = List.generate(_kStaggerCount, (i) {
      final start = (i * _kStagger.inMilliseconds) /
          _staggerCtrl.duration!.inMilliseconds;
      final end = math.min(start + 0.55, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(
          parent: _staggerCtrl,
          curve: Interval(start, end, curve: _kEaseOutCubic)));
    });

    // ─── Kick everything off ─────────────────────────────
    _runEnterSequence();
  }

  void _runEnterSequence() async {
    // Bottom nav slides up first (like RN)
    _bottomNavCtrl.forward();
    // Tiny delay, then page fades+slides in
    await Future.delayed(const Duration(milliseconds: 80));
    _pageEnterCtrl.forward();
    // Hero card bounces after page starts appearing
    await Future.delayed(const Duration(milliseconds: 200));
    _heroScaleCtrl.forward();
    // Stagger the dashboard content
    await Future.delayed(const Duration(milliseconds: 150));
    _staggerCtrl.forward();
    _tabSwitchCtrl.value = 1.0; // set tab as visible
  }

  @override
  void dispose() {
    _pageEnterCtrl.dispose();
    _bottomNavCtrl.dispose();
    _tabSwitchCtrl.dispose();
    _heroScaleCtrl.dispose();
    _pulseCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  void _acceptOffer(DriverOffer offer) {
    setState(() {
      _offers = _offers.map((item) => item.id == offer.id
          ? DriverOffer(
              id: item.id, shipmentId: item.shipmentId,
              driverName: item.driverName, rating: item.rating,
              completedTrips: item.completedTrips, price: item.price,
              etaHours: item.etaHours, vehicleType: item.vehicleType,
              status: OfferStatus.accepted, note: item.note)
          : item).toList();
    });
  }

  /// Animate tab switch — fade out → swap → fade in
  Future<void> _switchTab(int index) async {
    if (index == _currentIndex) return;
    await _tabSwitchCtrl.reverse();
    setState(() => _currentIndex = index);
    _tabSwitchCtrl.forward();

    // Re-run stagger if going back to dashboard
    if (index == 0) {
      _staggerCtrl.reset();
      _staggerCtrl.forward();
      _heroScaleCtrl.reset();
      _heroScaleCtrl.forward();
    }
  }

  Future<void> _logout() async {
    final t = TraderTheme(isDark: context.read<ThemeProvider>().isDark);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?',
            style: TextStyle(color: t.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: t.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout',
                  style: TextStyle(
                      color: TraderTheme.accent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('role');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = TraderTheme(isDark: context.watch<ThemeProvider>().isDark);
    final user = context.watch<UserProvider>();
    final displayName = user.fullName.isNotEmpty ? user.fullName : 'Trader';
    final summary = TraderDummyData.summary(_shipments, _offers);
    final featuredShipment = _shipments.firstWhere(
        (s) => s.isActive, orElse: () => _shipments.first);

    final pages = [
      _DashboardPage(
        t: t, displayName: displayName, summary: summary,
        featuredShipment: featuredShipment,
        recentShipments: _shipments.take(5).toList(),
        onOpenShipments: () => _switchTab(1),
        onOpenOffers:    () => _switchTab(2),
        onShowShipment:  _showShipmentDetails,
        onCreateShipment: _openCreateShipment,
        onLogout: _logout,
        // animation props
        heroScaleAnim:  _heroScale,
        heroBounceAnim: _heroBounce,
        staggerFade:    _staggerFade,
        staggerSlide:   _staggerSlide,
        pulseOpacity:   _pulseOpacity,
      ),
      _ShipmentsPage(
        t: t, shipments: _shipments,
        onBack: () => _switchTab(0),
        onShowDetails: _showShipmentDetails,
      ),
      _OffersPage(
        t: t, featuredShipment: featuredShipment, offers: _offers,
        onBack: () => _switchTab(0),
        onAccept: _acceptOffer,
      ),
      _NotificationsPage(
        t: t, notifications: _notifications,
        onBack: () => _switchTab(0),
      ),
    ];

    return WillPopScope(
      onWillPop: () async => false,
      child: FadeTransition(
        opacity: _pageOpacity,
        child: SlideTransition(
          position: _pageSlide,
          child: Scaffold(
            backgroundColor: t.bg,
            body: SafeArea(
              child: FadeTransition(
                opacity: _tabFade,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: pages[_currentIndex],
                ),
              ),
            ),
            // ── Bottom nav slides up on entry ──
            bottomNavigationBar: SlideTransition(
              position: _bottomNavSlide,
              child: _BottomNav(
                t: t, currentIndex: _currentIndex,
                onTap: (i) {
                  if (i == 4) {
                    Navigator.pushNamed(context, '/trader_advanced_settings');
                  } else {
                    _switchTab(i);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showShipmentDetails(Shipment shipment) async {
    await Navigator.push(context, _slideUpRoute(
      _ShipmentDetailsScreen(
        shipment: shipment,
        onCancel: () {
          Navigator.pop(context);
          _switchTab(1);
        },
      ),
    ));
  }

  Future<void> _openCreateShipment() async {
    await Navigator.push(context,
        _slideUpRoute(const TraderNewShipmentScreen()));
  }
}

// ── Custom slide-up page route (matches RN modal presentation) ──
Route<T> _slideUpRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => child,
  transitionDuration: _kMedAnim,
  reverseTransitionDuration: _kFastAnim,
  transitionsBuilder: (_, anim, secondaryAnim, child) {
    final slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: anim, curve: _kEaseOutCubic));
    final fade = CurvedAnimation(parent: anim, curve: _kEaseOutCubic);
    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: child),
    );
  },
);

// ══════════════════════════════════════════════════════════
//  BOTTOM NAV
// ══════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final TraderTheme t;
  const _BottomNav({required this.currentIndex, required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
        boxShadow: t.cardShadow,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex, onTap: onTap,
        backgroundColor: Colors.transparent, elevation: 0,
        selectedItemColor: TraderTheme.accent,
        unselectedItemColor: t.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11, unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded), label: 'Shipments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.handshake_outlined),
              activeIcon: Icon(Icons.handshake_rounded), label: 'Offers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded),
              activeIcon: Icon(Icons.notifications_rounded), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
//  DASHBOARD PAGE  (receives animation objects from parent)
// ══════════════════════════════════════════════════════════
class _DashboardPage extends StatelessWidget {
  final TraderTheme t;
  final String displayName;
  final TraderSummary summary;
  final Shipment featuredShipment;
  final List<Shipment> recentShipments;
  final VoidCallback onOpenShipments, onOpenOffers, onCreateShipment, onLogout;
  final ValueChanged<Shipment> onShowShipment;

  // ── Animation props ──
  final Animation<double> heroScaleAnim;
  final Animation<double> heroBounceAnim;
  final List<Animation<double>> staggerFade;
  final List<Animation<Offset>> staggerSlide;
  final Animation<double> pulseOpacity;

  const _DashboardPage({
    required this.t, required this.displayName, required this.summary,
    required this.featuredShipment, required this.recentShipments,
    required this.onOpenShipments, required this.onOpenOffers,
    required this.onShowShipment, required this.onCreateShipment,
    required this.onLogout,
    required this.heroScaleAnim,
    required this.heroBounceAnim,
    required this.staggerFade,
    required this.staggerSlide,
    required this.pulseOpacity,
  });

  // Helper: wrap a child in staggered fade+slide by index
  Widget _staggered(int index, Widget child) => FadeTransition(
    opacity: staggerFade[index],
    child: SlideTransition(position: staggerSlide[index], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning'
        : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ══ [0] HEADER ══
      _staggered(0, Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/trader_profile'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greeting, style: TextStyle(color: t.textMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(displayName,
                  style: TextStyle(color: t.textPrimary, fontSize: 24,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.read<ThemeProvider>().toggleTheme(),
          child: _HeaderBtn(
              icon: t.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              t: t, iconColor: TraderTheme.accent),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/trader_notifications'),
          child: Stack(clipBehavior: Clip.none, children: [
            _HeaderBtn(icon: Icons.notifications_none, t: t),
            Positioned(top: 6, right: 6,
              child: Container(width: 7, height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF476D), shape: BoxShape.circle)),
            ),
          ]),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/trader_profile'),
          child: CircleAvatar(
            radius: 17, backgroundColor: TraderTheme.accent,
            child: Text(initial, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onLogout,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: t.isDark ? const Color(0xFF1A0A0A) : const Color(0xFFFEE8EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF476D).withOpacity(0.4)),
            ),
            child: const Icon(Icons.logout, color: Color(0xFFFF476D), size: 15),
          ),
        ),
      ])),
      const SizedBox(height: 18),

      // ══ [1] HERO CARD — scale bounce ══
      _staggered(1,
        ScaleTransition(
          scale: heroScaleAnim,
          child: GestureDetector(
            onTap: () => onShowShipment(featuredShipment),
            child: _HeroCard(shipment: featuredShipment, t: t),
          ),
        ),
      ),
      const SizedBox(height: 18),

      // ══ [2] SHIPMENT DETAILS label ══
      _staggered(2, Text('SHIPMENT DETAILS',
          style: TextStyle(color: t.textMuted, fontSize: 10, letterSpacing: 1.4))),
      const SizedBox(height: 12),

      // ══ [3] PROGRESS BAR — with pulse ══
      _staggered(3, Column(children: [
        Row(children: [
          Text('Progress', style: TextStyle(color: t.textMuted, fontSize: 13)),
          const Spacer(),
          Text('${(featuredShipment.progress * 100).round()}%',
              style: const TextStyle(color: TraderTheme.accent,
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        // Pulsing progress bar (matches RN animated value looping)
        AnimatedBuilder(
          animation: pulseOpacity,
          builder: (_, __) => Opacity(
            opacity: pulseOpacity.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: featuredShipment.progress, minHeight: 5,
                backgroundColor: t.isDark ? Colors.white12 : const Color(0xFFDCEEF4),
                valueColor: const AlwaysStoppedAnimation<Color>(TraderTheme.accent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Text('Driver', style: TextStyle(color: t.textMuted, fontSize: 13)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 10, backgroundColor: TraderTheme.accent,
            child: Text(
              featuredShipment.driverName.split(' ').map((p) => p[0]).take(2).join(),
              style: const TextStyle(fontSize: 7, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Text(featuredShipment.driverName,
              style: TextStyle(color: t.textPrimary, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
                color: t.isDark ? const Color(0xFF3A3B2B) : const Color(0xFFFFF8E0),
                borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.star, color: Color(0xFFF4C14B), size: 10),
              SizedBox(width: 3),
              Text('4.8', style: TextStyle(color: Color(0xFFF4C14B), fontSize: 10)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text('Shipment ID', style: TextStyle(color: t.textMuted, fontSize: 13)),
          const Spacer(),
          Text(featuredShipment.reference,
              style: const TextStyle(color: TraderTheme.accent,
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ])),
      const SizedBox(height: 18),

      // ══ [4] CREATE SHIPMENT CARD ══
      _staggered(4,
        _AnimatedTapCard(
          onTap: onCreateShipment,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
              boxShadow: t.cardShadow,
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                    color: TraderTheme.accent,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.location_on_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create New\nShipment',
                      style: TextStyle(color: t.textPrimary,
                          fontWeight: FontWeight.w700, fontSize: 17, height: 1.2)),
                  const SizedBox(height: 4),
                  Text('Get instant driver matches',
                      style: TextStyle(color: t.textMuted, fontSize: 11)),
                ],
              )),
              const Icon(Icons.arrow_forward_rounded,
                  color: TraderTheme.accent, size: 20),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 20),

      // ══ [5] RECENT ACTIVITY header ══
      _staggered(5, Row(children: [
        Text('RECENT ACTIVITY',
            style: TextStyle(color: t.textMuted, fontSize: 10, letterSpacing: 1.3)),
        const Spacer(),
        GestureDetector(
          onTap: onOpenShipments,
          child: const Text('View All',
              style: TextStyle(color: TraderTheme.accent, fontSize: 13)),
        ),
      ])),
      const SizedBox(height: 12),

      // ══ [6] RECENT TILES — each tile has micro stagger ══
      _staggered(6, _StaggeredList(
        count: recentShipments.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RecentTile(
            shipment: recentShipments[i], t: t,
            onTap: () => onShowShipment(recentShipments[i]),
          ),
        ),
      )),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  STAGGERED LIST — animates each child with a delay
// ══════════════════════════════════════════════════════════
class _StaggeredList extends StatefulWidget {
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  const _StaggeredList({required this.count, required this.itemBuilder});
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
        milliseconds: 300 + widget.count * _kStagger.inMilliseconds);
    _ctrl = AnimationController(vsync: this, duration: total);

    _fades = List.generate(widget.count, (i) {
      final s = (i * _kStagger.inMilliseconds) / total.inMilliseconds;
      final e = math.min(s + 0.5, 1.0);
      return Tween<double>(begin: 0, end: 1)
          .animate(CurvedAnimation(parent: _ctrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });
    _slides = List.generate(widget.count, (i) {
      final s = (i * _kStagger.inMilliseconds) / total.inMilliseconds;
      final e = math.min(s + 0.55, 1.0);
      return Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _ctrl,
              curve: Interval(s, e, curve: _kEaseOutCubic)));
    });

    // Short delay so the dashboard stagger finishes first
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(widget.count, (i) => FadeTransition(
      opacity: _fades[i],
      child: SlideTransition(
          position: _slides[i],
          child: widget.itemBuilder(context, i)),
    )),
  );
}

// ══════════════════════════════════════════════════════════
//  ANIMATED TAP CARD — scale down on press (RN TouchableOpacity)
// ══════════════════════════════════════════════════════════
class _AnimatedTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedTapCard({required this.child, required this.onTap});
  @override
  State<_AnimatedTapCard> createState() => _AnimatedTapCardState();
}

class _AnimatedTapCardState extends State<_AnimatedTapCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:    (_) => _ctrl.forward(),
    onTapUp:      (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel:  ()  => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

// ── Header Button ──
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final TraderTheme t;
  final Color? iconColor;
  const _HeaderBtn({required this.icon, required this.t, this.iconColor});

  @override
  Widget build(BuildContext context) => Container(
    width: 32, height: 32,
    decoration: BoxDecoration(
      color: t.surfaceDeep,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: t.border),
    ),
    child: Icon(icon, color: iconColor ?? t.textPrimary, size: 16),
  );
}

// ══════════════════════════════════════════════════════════
//  HERO CARD
// ══════════════════════════════════════════════════════════
class _HeroCard extends StatelessWidget {
  final Shipment shipment;
  final TraderTheme t;
  const _HeroCard({required this.shipment, required this.t});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: t.border),
      boxShadow: t.cardShadow,
    ),
    child: Column(children: [
      Row(children: [
        StatusPill(
            label: shipmentStatusLabel(shipment.status).toUpperCase(),
            color: shipmentStatusColor(shipment.status)),
        const Spacer(),
        StatusPill(
            label: '${shipment.origin}  →  ${shipment.destination}',
            color: TraderTheme.accentSoft),
      ]),
      const SizedBox(height: 10),
      Container(
        height: 120, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: t.isDark
                ? [const Color(0xFF0A2A45), const Color(0xFF123E4E)]
                : [const Color(0xFFD4F5E2), const Color(0xFFEAFBFF)],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(
              painter: _RoutePainter(isDark: t.isDark))),
          const Positioned(left: 20, bottom: 30,
              child: _RouteNode(active: false)),
          Positioned(right: 20, top: 20,
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(shipment.destination,
                    style: const TextStyle(color: Color(0xFF1A2A3A),
                        fontSize: 10, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              const _RouteNode(active: true),
            ]),
          ),
          Center(child: CircleAvatar(
            radius: 16,
            backgroundColor: t.isDark ? const Color(0xFF3A73FF) : const Color(0xFF2A9EB3),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
          )),
        ]),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
              color: TraderTheme.accent, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.bolt, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ESTIMATED TIME', style: TextStyle(color: t.textMuted, fontSize: 9)),
          const Text('45 min',
              style: TextStyle(color: TraderTheme.accent,
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        _AnimatedTapCard(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [TraderTheme.accentSoft, TraderTheme.accent]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: TraderTheme.accent.withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Text('View Live  →',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ),
      ]),
    ]),
  );
}

class _RouteNode extends StatelessWidget {
  final bool active;
  const _RouteNode({required this.active});
  @override
  Widget build(BuildContext context) => Container(
    width: active ? 16 : 12, height: active ? 16 : 12,
    decoration: BoxDecoration(
      color: active ? TraderTheme.accent : Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: TraderTheme.accent, width: 2),
      boxShadow: active
          ? [BoxShadow(color: TraderTheme.accent.withOpacity(0.45), blurRadius: 10)]
          : null,
    ),
  );
}

class _RoutePainter extends CustomPainter {
  final bool isDark;
  _RoutePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(24, size.height - 36)
        ..quadraticBezierTo(
            size.width * 0.45, size.height * 0.55, size.width - 26, 28),
      Paint()
        ..color = TraderTheme.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ══════════════════════════════════════════════════════════
//  SHIPMENTS PAGE
// ══════════════════════════════════════════════════════════
class _ShipmentsPage extends StatefulWidget {
  final List<Shipment> shipments;
  final VoidCallback onBack;
  final ValueChanged<Shipment> onShowDetails;
  final TraderTheme t;
  const _ShipmentsPage({required this.shipments, required this.onBack,
      required this.onShowDetails, required this.t});
  @override
  State<_ShipmentsPage> createState() => _ShipmentsPageState();
}

class _ShipmentsPageState extends State<_ShipmentsPage> {
  int _page = 0;
  static const int _pageSize = 6;
  @override
  Widget build(BuildContext context) {
    final total = (widget.shipments.length / _pageSize).ceil().clamp(1, 999);
    final items = widget.shipments.skip(_page * _pageSize).take(_pageSize).toList();
    final spent = items.fold<double>(0, (s, x) => s + x.price) / 1000;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScreenTopBar(
        title: 'My Shipments',
        subtitle: '${widget.shipments.length} total shipments',
        leading: TraderIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: widget.onBack),
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: MetricMiniCard(
            icon: Icons.calendar_today_outlined,
            label: 'This Month', value: '12')),
        const SizedBox(width: 12),
        Expanded(child: MetricMiniCard(
            icon: Icons.attach_money_rounded,
            label: 'Total Spent',
            value: '\$${spent.toStringAsFixed(1)}K')),
      ]),
      const SizedBox(height: 16),
      _StaggeredList(
        count: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ShipTile(shipment: items[i], t: widget.t,
              onTap: () => widget.onShowDetails(items[i])),
        ),
      ),
      const SizedBox(height: 8),
      _Pager(t: widget.t, page: _page, total: total,
        onPrev: _page == 0 ? null : () => setState(() => _page--),
        onNext: _page >= total - 1 ? null : () => setState(() => _page++),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════
//  OFFERS PAGE
// ══════════════════════════════════════════════════════════
class _OffersPage extends StatefulWidget {
  final Shipment featuredShipment;
  final List<DriverOffer> offers;
  final VoidCallback onBack;
  final ValueChanged<DriverOffer> onAccept;
  final TraderTheme t;
  const _OffersPage({required this.featuredShipment, required this.offers,
      required this.onBack, required this.onAccept, required this.t});
  @override
  State<_OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<_OffersPage> {
  int _page = 0;
  int _filterIndex = 0;
  static const int _pageSize = 4;

  List<DriverOffer> get _filtered {
    switch (_filterIndex) {
      case 0: return widget.offers.where((o) => o.status == OfferStatus.pending).toList();
      case 1: return widget.offers.where((o) => o.status == OfferStatus.accepted).toList();
      case 2: return widget.offers.where((o) => o.status == OfferStatus.rejected).toList();
      default: return widget.offers;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = (filtered.length / _pageSize).ceil().clamp(1, 999);
    final items = filtered.skip(_page * _pageSize).take(_pageSize).toList();
    final pendingCount  = widget.offers.where((o) => o.status == OfferStatus.pending).length;
    final acceptedCount = widget.offers.where((o) => o.status == OfferStatus.accepted).length;
    final rejectedCount = widget.offers.where((o) => o.status == OfferStatus.rejected).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ScreenTopBar(
        title: 'Driver Offers',
        subtitle: '${widget.offers.length} drivers available',
        leading: TraderIconButton(
            icon: Icons.arrow_back_ios_new_rounded, onTap: widget.onBack),
      ),
      const SizedBox(height: 16),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _FilterTab(label: 'Pending', count: pendingCount,
              selected: _filterIndex == 0, t: widget.t,
              onTap: () => setState(() { _filterIndex = 0; _page = 0; })),
          const SizedBox(width: 8),
          _FilterTab(label: 'Accepted', count: acceptedCount,
              selected: _filterIndex == 1, t: widget.t,
              onTap: () => setState(() { _filterIndex = 1; _page = 0; })),
          const SizedBox(width: 8),
          _FilterTab(label: 'Rejected', count: rejectedCount,
              selected: _filterIndex == 2, t: widget.t,
              onTap: () => setState(() { _filterIndex = 2; _page = 0; })),
        ]),
      ),
      const SizedBox(height: 16),
      if (items.isEmpty)
        Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('No offers in this category',
              style: TextStyle(color: widget.t.textMuted)),
        ))
      else ...[
        _StaggeredList(
          count: items.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OfferTile(offer: items[i], t: widget.t,
                onAccept: () => widget.onAccept(items[i])),
          ),
        ),
        _Pager(t: widget.t, page: _page, total: total,
          onPrev: _page == 0 ? null : () => setState(() => _page--),
          onNext: _page >= total - 1 ? null : () => setState(() => _page++),
        ),
      ],
    ]);
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final TraderTheme t;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.count,
      required this.selected, required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: _kFastAnim,
      curve: _kEaseOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? TraderTheme.accent : t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: selected ? TraderTheme.accent : t.border, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(
            color: selected ? Colors.white : t.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: selected ? Colors.white.withOpacity(0.25) : t.surfaceDeep,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: TextStyle(
              color: selected ? Colors.white : t.textMuted,
              fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════
//  NOTIFICATIONS PAGE
// ══════════════════════════════════════════════════════════
class _NotificationsPage extends StatelessWidget {
  final List<TraderNotification> notifications;
  final VoidCallback onBack;
  final TraderTheme t;
  const _NotificationsPage({required this.notifications,
      required this.onBack, required this.t});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
    ScreenTopBar(
      title: 'Alerts',
      subtitle: '${notifications.length} recent updates',
      leading: TraderIconButton(
          icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
    ),
    const SizedBox(height: 18),
    _StaggeredList(
      count: notifications.length,
      itemBuilder: (_, i) {
        final item = notifications[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border),
              boxShadow: t.cardShadow,
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: TraderTheme.accent.withOpacity(0.14),
                child: Icon(notificationIcon(item.type),
                    color: TraderTheme.accent, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(color: t.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(item.subtitle,
                      style: TextStyle(color: t.textMuted, fontSize: 11)),
                ],
              )),
              const SizedBox(width: 8),
              Text(item.timeLabel,
                  style: const TextStyle(color: TraderTheme.accent, fontSize: 11)),
            ]),
          ),
        );
      },
    ),
  ]);
}

// ══════════════════════════════════════════════════════════
//  SHIPMENT DETAILS SCREEN
// ══════════════════════════════════════════════════════════
class _ShipmentDetailsScreen extends StatefulWidget {
  final Shipment shipment;
  final VoidCallback onCancel;
  const _ShipmentDetailsScreen({required this.shipment, required this.onCancel});
  @override
  State<_ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends State<_ShipmentDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late AnimationController _mapCtrl;
  late AnimationController _dotCtrl;  // animated dot along route

  late Animation<double> _sheetSlide;
  late Animation<double> _mapFade;
  late Animation<double> _dotProgress; // 0→1 along route path

  @override
  void initState() {
    super.initState();

    // Bottom sheet slides up
    _enterCtrl = AnimationController(vsync: this, duration: _kMedAnim);
    _sheetSlide = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: _kEaseOutBack));

    // Map fades in
    _mapCtrl = AnimationController(vsync: this, duration: _kSlowAnim);
    _mapFade = CurvedAnimation(parent: _mapCtrl, curve: _kEaseOutCubic);

    // Animated dot travels route (like RN Animated.timing on location)
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _dotProgress = Tween<double>(begin: 0.0, end: widget.shipment.progress)
        .animate(CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut));

    _runDetailSequence();
  }

  void _runDetailSequence() async {
    _mapCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _enterCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _dotCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _mapCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = TraderTheme(isDark: context.watch<ThemeProvider>().isDark);
    final eta = math.max((widget.shipment.progress * 70).round(), 45);

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Header ──
            Row(children: [
              TraderIconButton(icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.shipment.reference,
                      style: TextStyle(color: t.textMuted,
                          fontSize: 10, letterSpacing: 1.1)),
                  const SizedBox(height: 3),
                  StatusPill(
                      label: shipmentStatusLabel(widget.shipment.status),
                      color: shipmentStatusColor(widget.shipment.status)),
                ],
              )),
              Text('ETA', style: TextStyle(
                  color: t.textMuted.withOpacity(0.7), fontSize: 11)),
              const SizedBox(width: 6),
              Text('${eta}m', style: const TextStyle(
                  color: TraderTheme.accent, fontSize: 22,
                  fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 14),

            // ── Animated map ──
            FadeTransition(
              opacity: _mapFade,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: t.isDark
                        ? [const Color(0xFF0B2237), const Color(0xFF133A5A)]
                        : [const Color(0xFFD4F5E2), const Color(0xFFEAFBFF)],
                  ),
                ),
                child: Stack(children: [
                  Positioned(top: 20, left: 16,
                      child: Text(widget.shipment.origin,
                          style: TextStyle(color: t.textPrimary, fontSize: 10))),
                  Positioned(top: 40, right: 20,
                      child: Text(widget.shipment.destination,
                          style: TextStyle(color: t.textPrimary, fontSize: 10))),
                  Positioned.fill(child: CustomPaint(painter: _TrackingPainter())),
                  // Animated dot along route
                  AnimatedBuilder(
                    animation: _dotProgress,
                    builder: (_, __) {
                      // Quadratic bezier interpolation matching _TrackingPainter
                      final p = _dotProgress.value;
                      // Same bezier as painter: from (56, h-88) to (w-42, 74)
                      // via (w*0.45, h*0.55)
                      final sz = Size(double.infinity, 260);
                      final t0 = 1 - p;
                      final px = t0 * t0 * 56 + 2 * t0 * p * (sz.width * 0.45) + p * p * (sz.width - 42);
                      final py = t0 * t0 * (sz.height - 88) + 2 * t0 * p * (sz.height * 0.55) + p * p * 74;
                      return Positioned(
                        left: px - 18, top: py - 18,
                        child: CircleAvatar(radius: 18,
                            backgroundColor: const Color(0xFF3A73FF),
                            child: const Icon(Icons.navigation_rounded,
                                color: Colors.white)),
                      );
                    },
                  ),
                  const Positioned(top: 66, right: 36,
                      child: CircleAvatar(radius: 11,
                          backgroundColor: TraderTheme.accent)),
                  const Positioned(left: 48, bottom: 80,
                      child: CircleAvatar(radius: 8,
                          backgroundColor: TraderTheme.accent)),
                ]),
              ),
            ),
            const SizedBox(height: 4),

            // ── Bottom sheet slides up ──
            AnimatedBuilder(
              animation: _sheetSlide,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, 40 * (1 - _sheetSlide.value)),
                child: Opacity(opacity: _sheetSlide.value.clamp(0, 1), child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.border),
                  boxShadow: t.cardShadow,
                ),
                child: Column(children: [
                  Container(
                    width: 48, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: t.isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(999)),
                  ),
                  Row(children: [
                    CircleAvatar(
                      radius: 22, backgroundColor: TraderTheme.accent,
                      child: Text(
                        widget.shipment.driverName.split(' ').map((p) => p[0]).take(2).join(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.shipment.driverName, style: TextStyle(
                            color: t.textPrimary, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('4.8  ·  ${widget.shipment.vehicleInfo}',
                            style: TextStyle(color: t.textMuted, fontSize: 12)),
                      ],
                    )),
                    CircleAvatar(radius: 18, backgroundColor: TraderTheme.accent,
                        child: const Icon(Icons.phone_outlined,
                            color: Colors.white, size: 16)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _InfoBox(t: t, label: 'ROUTE',
                        value: '${widget.shipment.origin} → ${widget.shipment.destination}')),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoBox(t: t, label: 'WEIGHT',
                        value: '${widget.shipment.weightTons.toStringAsFixed(1)} tons')),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoBox(t: t, label: 'PRICE',
                        value: '\$${widget.shipment.price.toStringAsFixed(0)}')),
                  ]),
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerLeft,
                    child: Text('STATUS TIMELINE', style: TextStyle(
                        color: t.textMuted, fontSize: 10, letterSpacing: 1.1)),
                  ),
                  const SizedBox(height: 12),
                  ...widget.shipment.timeline.map((item) =>
                      _TimelineRow(item: item, t: t)),
                  const SizedBox(height: 12),
                  if (widget.shipment.status == ShipmentStatus.delivered)
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, _slideUpRoute(
                            RateDriverScreen(
                              driverName: widget.shipment.driverName,
                              driverInitials: widget.shipment.driverName
                                  .split(' ').map((p) => p[0]).take(2).join(),
                            ))),
                        icon: const Icon(Icons.star_outline_rounded, size: 20),
                        label: const Text('Rate Driver',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: TraderTheme.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: widget.onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D1525),
                          foregroundColor: const Color(0xFFFF7E8E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel Shipment',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══ SHARED WIDGETS ══
class _RecentTile extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;
  final TraderTheme t;
  const _RecentTile({required this.shipment, required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) => _AnimatedTapCard(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surfaceDeep,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Row(children: [
        CircleAvatar(radius: 16,
            backgroundColor: TraderTheme.accent.withOpacity(0.16),
            child: const Icon(Icons.local_shipping_outlined,
                color: TraderTheme.accent, size: 15)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${shipment.origin}  →  ${shipment.destination}',
                style: TextStyle(color: t.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${shipment.departureDate.replaceAll('2026-', 'Jan ')}  ·  Delivered',
                style: TextStyle(color: t.textMuted, fontSize: 10)),
          ],
        )),
        Text('\$${shipment.price.toStringAsFixed(0)}',
            style: const TextStyle(color: TraderTheme.accent,
                fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _ShipTile extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback onTap;
  final TraderTheme t;
  const _ShipTile({required this.shipment, required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) => _AnimatedTapCard(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
        boxShadow: t.cardShadow,
      ),
      child: Column(children: [
        Row(children: [
          Text(shipment.departureDate
              .replaceAll('2026-01-', 'Jan ').replaceAll('-', '/'),
              style: TextStyle(color: t.textMuted, fontSize: 11)),
          const Spacer(),
          StatusPill(label: shipmentStatusLabel(shipment.status),
              color: shipmentStatusColor(shipment.status)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.circle, color: TraderTheme.accent, size: 7),
          const SizedBox(width: 6),
          Expanded(child: Text(
              '${shipment.origin}  →  ${shipment.destination}',
              style: TextStyle(color: t.textPrimary,
                  fontWeight: FontWeight.w600))),
          Text('\$${shipment.price.toStringAsFixed(0)}',
              style: const TextStyle(color: TraderTheme.accent,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft,
          child: Text('Driver: ${shipment.driverName}',
              style: TextStyle(color: t.textMuted, fontSize: 11)),
        ),
      ]),
    ),
  );
}

class _OfferTile extends StatelessWidget {
  final DriverOffer offer;
  final VoidCallback onAccept;
  final TraderTheme t;
  const _OfferTile({required this.offer, required this.onAccept, required this.t});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: t.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: t.border),
      boxShadow: t.cardShadow,
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        CircleAvatar(
          radius: 22, backgroundColor: TraderTheme.accent,
          child: Text(
            offer.driverName.split(' ').map((p) => p[0]).take(2).join(),
            style: const TextStyle(color: Colors.white,
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(offer.driverName, style: TextStyle(
                color: t.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.star, color: Color(0xFFF4C14B), size: 13),
              const SizedBox(width: 3),
              Text(offer.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Color(0xFFF4C14B), fontSize: 12)),
              Text('  ·  ${offer.etaHours} mins ago',
                  style: TextStyle(color: t.textMuted, fontSize: 12)),
            ]),
            Row(children: [
              Icon(Icons.location_on_outlined, color: t.textMuted, size: 13),
              Text(' ${(offer.etaHours * 1.2).toStringAsFixed(1)} km  ${offer.vehicleType}',
                  style: TextStyle(color: t.textMuted, fontSize: 12)),
            ]),
          ],
        )),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Offer Price', style: TextStyle(color: t.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text('\$${offer.price.toStringAsFixed(0)}',
              style: const TextStyle(color: TraderTheme.accent,
                  fontSize: 26, fontWeight: FontWeight.w700)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('ETA', style: TextStyle(color: t.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Row(children: [
            Icon(Icons.access_time_outlined, color: t.textMuted, size: 14),
            const SizedBox(width: 4),
            Text('${offer.etaHours * 5} mins',
                style: TextStyle(color: t.textPrimary,
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
        ]),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFF476D),
            side: BorderSide(color: const Color(0xFFFF476D).withOpacity(0.5)),
            backgroundColor: const Color(0xFFFF476D).withOpacity(0.07),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.cancel_outlined, size: 16),
          label: const Text('Reject',
              style: TextStyle(fontWeight: FontWeight.w600)),
        )),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: TraderTheme.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Accept',
              style: TextStyle(fontWeight: FontWeight.w700)),
        )),
      ]),
    ]),
  );
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  final TraderTheme t;
  const _InfoBox({required this.label, required this.value, required this.t});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: t.surfaceDeep,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: t.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: t.textMuted, fontSize: 9)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(color: t.textPrimary,
          fontWeight: FontWeight.w700, fontSize: 11)),
    ]),
  );
}

class _TimelineRow extends StatelessWidget {
  final ShipmentMilestone item;
  final TraderTheme t;
  const _TimelineRow({required this.item, required this.t});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      AnimatedContainer(
        duration: _kMedAnim,
        width: 22, height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: item.isDone ? TraderTheme.accent : t.border, width: 2),
        ),
        child: item.isDone
            ? const Icon(Icons.circle, size: 8, color: TraderTheme.accent)
            : null,
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: TextStyle(color: t.textPrimary)),
          const SizedBox(height: 2),
          Text(item.time, style: TextStyle(color: t.textMuted, fontSize: 11)),
        ],
      )),
    ]),
  );
}

class _Pager extends StatelessWidget {
  final int page, total;
  final VoidCallback? onPrev, onNext;
  final TraderTheme t;
  const _Pager({required this.page, required this.total,
      required this.onPrev, required this.onNext, required this.t});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text('Page ${page + 1} / $total',
        style: TextStyle(color: t.textMuted, fontSize: 11)),
    const Spacer(),
    TraderIconButton(icon: Icons.chevron_left_rounded, onTap: onPrev),
    const SizedBox(width: 8),
    TraderIconButton(icon: Icons.chevron_right_rounded, onTap: onNext),
  ]);
}

class _TrackingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(56, size.height - 88)
        ..quadraticBezierTo(
            size.width * 0.45, size.height * 0.55, size.width - 42, 74),
      Paint()
        ..color = TraderTheme.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// ══ HELPERS ══
String shipmentStatusLabel(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.pending:   return 'Pending';
    case ShipmentStatus.inTransit: return 'In Transit';
    case ShipmentStatus.delivered: return 'Delivered';
    case ShipmentStatus.cancelled: return 'Cancelled';
  }
}

Color shipmentStatusColor(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.pending:   return const Color(0xFFF3B64C);
    case ShipmentStatus.inTransit: return const Color(0xFF3A73FF);
    case ShipmentStatus.delivered: return TraderTheme.accent;
    case ShipmentStatus.cancelled: return TraderTheme.danger;
  }
}

IconData notificationIcon(NotificationType t) {
  switch (t) {
    case NotificationType.offer:    return Icons.handshake_outlined;
    case NotificationType.shipment: return Icons.local_shipping_outlined;
    case NotificationType.payment:  return Icons.payments_outlined;
    case NotificationType.system:   return Icons.info_outline;
  }
}
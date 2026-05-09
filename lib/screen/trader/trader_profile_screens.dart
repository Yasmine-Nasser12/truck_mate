import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/user_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  TraderProfileScreen — animations ported 1:1 from ProfileDriver.tsx (RN)
//
//  RN patterns used:
//  • Header:     opacity + x(-20→0) easeOut 500ms
//  • User card:  opacity + scale(0.95→1) spring, delay 100ms
//  • Stats row:  opacity + y(20→0) delay 200ms + counter 0→value 800ms
//  • Option rows: stagger opacity + y(20→0), delay 300ms + i*60ms each
//  • whileTap scale:0.97 → _TapScaleButton on every tappable row
//  • Background radial glow blob (static — matches ProfileDriver bg pattern)
// ══════════════════════════════════════════════════════════════════════════════

class TraderProfileScreen extends StatefulWidget {
  const TraderProfileScreen({super.key});

  @override
  State<TraderProfileScreen> createState() => _TraderProfileScreenState();
}

class _TraderProfileScreenState extends State<TraderProfileScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ──
  late final AnimationController _headerCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _statsCtrl;
  late final AnimationController _counterCtrl;
  late final List<AnimationController> _rowCtrls;

  // ── Animations ──
  late final Animation<double> _headerFade;
  late final Animation<Offset>  _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _cardScale;
  late final Animation<double> _statsFade;
  late final Animation<Offset>  _statsSlide;

  // Counter animations for stats
  late final Animation<int> _totalCount;
  late final Animation<int> _activeCount;
  late final Animation<int> _completedCount;
  late final Animation<int> _driversCount;

  late final List<Animation<double>> _rowFades;
  late final List<Animation<Offset>>  _rowSlides;

  static const int _optionCount = 9;

  @override
  void initState() {
    super.initState();

    // ── Header: opacity + x -20→0, easeOut 500ms ──
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(
        parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // ── User card: scale 0.95→1 (easeOutBack spring feel), delay 100ms ──
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardScale = Tween<double>(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutBack));

    // ── Stats row: opacity + y 20→0, delay 200ms ──
    _statsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _statsFade = CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut);
    _statsSlide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _statsCtrl, curve: Curves.easeOut));

    // ── Counter: 0 → final value, 800ms easeOut, delay 300ms ──
    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _totalCount =
        IntTween(begin: 0, end: 70).animate(
            CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _activeCount =
        IntTween(begin: 0, end: 12).animate(
            CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _completedCount =
        IntTween(begin: 0, end: 50).animate(
            CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));
    _driversCount =
        IntTween(begin: 0, end: 45).animate(
            CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOut));

    // ── Option rows: stagger delay 300ms + i * 60ms ──
    _rowCtrls = List.generate(
        _optionCount,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 400)));
    _rowFades = _rowCtrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut)
            as Animation<double>)
        .toList();
    _rowSlides = _rowCtrls
        .map((c) => Tween<Offset>(
                begin: const Offset(0, 0.06), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    // ── Stagger start ──
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 100),
        () { if (mounted) _cardCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 200),
        () { if (mounted) _statsCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _counterCtrl.forward(); });
    for (int i = 0; i < _optionCount; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 60),
          () { if (mounted) _rowCtrls[i].forward(); });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _cardCtrl.dispose();
    _statsCtrl.dispose();
    _counterCtrl.dispose();
    for (final c in _rowCtrls) { c.dispose(); }
    super.dispose();
  }

  // Wraps a widget in its row's stagger animation
  Widget _animRow(int i, Widget child) {
    final idx = i.clamp(0, _rowSlides.length - 1);
    return SlideTransition(
      position: _rowSlides[idx],
      child: FadeTransition(opacity: _rowFades[idx], child: child),
    );
  }

  // Fade page transition (like RN navigate animation)
  Route<void> _fadeRoute(Widget page) => PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  void _confirmLogout(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDark;
    final kCard  = isDark ? const Color(0xFF152232) : Colors.white;
    final kText  = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out',
            style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out?',
            style: TextStyle(color: kMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: kMuted))),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false);
              },
              child: const Text('Log out',
                  style: TextStyle(
                      color: Color(0xFF00BFA5),
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final user   = context.watch<UserProvider>();
    final name   = user.fullName.isNotEmpty ? user.fullName : 'Maro Ahmed';
    final email  = user.email.isNotEmpty    ? user.email    : 'Trader@truckmate.com';
    final initials = name.trim().split(' ').take(2)
        .map((w) => w[0].toUpperCase()).join();

    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF112236) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00BFA5);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _TapScaleButton(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: kCard,
                shape: BoxShape.circle,
                border: Border.all(color: kBorder)),
            child: const Icon(Icons.arrow_back, color: kTeal, size: 20)),
        ),
        title: Text('Profile',
            style: TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Stack(children: [

        // ── Background radial glow (ProfileDriver pattern) ──
        Positioned(
          top: 160, left: -8,
          child: Container(
            width: 369, height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(200),
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00D5BE).withOpacity(0.07),
                  const Color(0xFF00D3F2).withOpacity(0.04),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(children: [
            const SizedBox(height: 16),

            // ── User card: scale spring + fade ──
            ScaleTransition(
              scale: _cardScale,
              child: FadeTransition(
                opacity: _cardFade,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kBorder),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ],
                  ),
                  child: Column(children: [
                    Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        width: 90, height: 90,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: kTeal, width: 2)),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF8A00), Color(0xFFE52EE5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                            color: kTeal,
                            shape: BoxShape.circle,
                            border: Border.all(color: kCard, width: 2)),
                        child: const Icon(Icons.camera_alt,
                            size: 13, color: Colors.white)),
                    ]),
                    const SizedBox(height: 14),
                    Text(name,
                        style: TextStyle(
                            color: kText,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: kMuted, fontSize: 13)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Stats row with counter animation ──
            SlideTransition(
              position: _statsSlide,
              child: FadeTransition(
                opacity: _statsFade,
                child: AnimatedBuilder(
                  animation: _counterCtrl,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatItem(
                          icon: Icons.inventory_2_outlined,
                          value: '${_totalCount.value}',
                          label: 'Total Ships',
                          kCard: kCard, kTeal: kTeal, kText: kText,
                          kBorder: kBorder, isDark: isDark),
                      _StatItem(
                          icon: Icons.access_time,
                          value: '${_activeCount.value}',
                          label: 'Active',
                          kCard: kCard, kTeal: kTeal, kText: kText,
                          kBorder: kBorder, isDark: isDark),
                      _StatItem(
                          icon: Icons.check_circle_outline,
                          value: '${_completedCount.value}',
                          label: 'Completed',
                          kCard: kCard, kTeal: kTeal, kText: kText,
                          kBorder: kBorder, isDark: isDark),
                      _StatItem(
                          icon: Icons.people_outline,
                          value: '${_driversCount.value}',
                          label: 'Drivers',
                          kCard: kCard, kTeal: kTeal, kText: kText,
                          kBorder: kBorder, isDark: isDark),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Option rows: staggered ──
            _animRow(0, _ProfileOption(
              icon: Icons.person_outline, title: 'Your profile',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
              onTap: () => Navigator.push(context,
                  _fadeRoute(const TraderDetailsScreen())),
            )),
            _animRow(1, _ProfileOption(
              icon: Icons.payment_outlined, title: 'Payment Methods',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
            )),
            _animRow(2, _DarkModeSwitch(
              isDark: isDark, kCard: kCard, kText: kText,
              kBorder: kBorder, kTeal: kTeal,
            )),
            _animRow(3, _ProfileOption(
              icon: Icons.language_outlined, title: 'Language',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
            )),
            _animRow(4, _ProfileOption(
              icon: Icons.account_balance_wallet_outlined, title: 'My Wallet',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
            )),
            _animRow(5, _ProfileOption(
              icon: Icons.person_add_outlined, title: 'Invite Friends',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
            )),
            _animRow(6, _ProfileOption(
              icon: Icons.settings_outlined, title: 'Settings',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
              onTap: () => Navigator.pushNamed(
                  context, '/trader_advanced_settings'),
            )),
            _animRow(7, _ProfileOption(
              icon: Icons.help_outline, title: 'Support Setting',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
            )),
            _animRow(8, _ProfileOption(
              icon: Icons.logout, title: 'Log out',
              isDark: isDark, kCard: kCard, kText: kText,
              kMuted: kMuted, kBorder: kBorder, kTeal: kTeal,
              isLogout: true,
              onTap: () => _confirmLogout(context),
            )),
            const SizedBox(height: 30),
          ]),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _StatItem
// ══════════════════════════════════════════════════════════════════════════════
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color kCard, kTeal, kText, kBorder;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.kCard,
    required this.kTeal,
    required this.kText,
    required this.kBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          shape: BoxShape.circle,
          border: Border.all(color: kBorder),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8)
                ],
        ),
        child: Icon(icon, color: kTeal, size: 22),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: TextStyle(
              color: kTeal, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _DarkModeSwitch
// ══════════════════════════════════════════════════════════════════════════════
class _DarkModeSwitch extends StatelessWidget {
  final bool isDark;
  final Color kCard, kText, kBorder, kTeal;

  const _DarkModeSwitch({
    required this.isDark,
    required this.kCard,
    required this.kText,
    required this.kBorder,
    required this.kTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(children: [
        Icon(Icons.dark_mode_outlined, color: kTeal, size: 22),
        const SizedBox(width: 14),
        Expanded(
            child: Text('Dark Mode',
                style: TextStyle(color: kText, fontSize: 14))),
        Switch(
          value: isDark,
          onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
          activeColor: kTeal,
          activeTrackColor: kTeal.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _ProfileOption
// ══════════════════════════════════════════════════════════════════════════════
class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark, isLogout;
  final Color kCard, kText, kMuted, kBorder, kTeal;
  final VoidCallback? onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.kCard,
    required this.kText,
    required this.kMuted,
    required this.kBorder,
    required this.kTeal,
    this.isLogout = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _TapScaleButton(
      onTap: onTap ?? () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Row(children: [
          Icon(icon,
              color: isLogout ? const Color(0xFF00BFA5) : kTeal,
              size: 22),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: TextStyle(color: kText, fontSize: 14))),
          Icon(Icons.arrow_forward_ios_rounded,
              color: kMuted, size: 14),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TraderDetailsScreen  (About + Shipments tabs)
// ══════════════════════════════════════════════════════════════════════════════
class TraderDetailsScreen extends StatefulWidget {
  const TraderDetailsScreen({super.key});

  @override
  State<TraderDetailsScreen> createState() => _TraderDetailsScreenState();
}

class _TraderDetailsScreenState extends State<TraderDetailsScreen>
    with TickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final AnimationController _avatarCtrl;
  late final AnimationController _statsCtrl;
  late final AnimationController _counterCtrl;
  late final AnimationController _tabContentCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset>  _headerSlide;
  late final Animation<double> _avatarScale;
  late final Animation<double> _statsFade;
  late final Animation<Offset>  _statsSlide;
  late final Animation<int>    _tripsCount;
  late final Animation<int>    _completedCount;
  late final Animation<double> _tabContentFade;
  late final Animation<Offset>  _tabContentSlide;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade = CurvedAnimation(
        parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
            begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerCtrl, curve: Curves.easeOut));

    _avatarCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _avatarScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
            parent: _avatarCtrl, curve: Curves.elasticOut));

    _statsCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _statsFade = CurvedAnimation(
        parent: _statsCtrl, curve: Curves.easeOut);
    _statsSlide = Tween<Offset>(
            begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _statsCtrl, curve: Curves.easeOut));

    _counterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _tripsCount = IntTween(begin: 0, end: 70)
        .animate(CurvedAnimation(
            parent: _counterCtrl, curve: Curves.easeOut));
    _completedCount = IntTween(begin: 0, end: 50)
        .animate(CurvedAnimation(
            parent: _counterCtrl, curve: Curves.easeOut));

    _tabContentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _tabContentFade = CurvedAnimation(
        parent: _tabContentCtrl, curve: Curves.easeOut);
    _tabContentSlide = Tween<Offset>(
            begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _tabContentCtrl, curve: Curves.easeOut));

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150),
        () { if (mounted) _avatarCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) _statsCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 350),
        () { if (mounted) _counterCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _tabContentCtrl.forward(); });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _avatarCtrl.dispose();
    _statsCtrl.dispose();
    _counterCtrl.dispose();
    _tabContentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final user   = context.watch<UserProvider>();
    final name   = user.fullName.isNotEmpty ? user.fullName : 'Maro Ahmed';

    final kBg     = isDark ? const Color(0xFF0A1520) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF0F2030) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? Colors.grey             : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00BFA5);

    final initials = name.trim().split(' ').take(2)
        .map((w) => w[0].toUpperCase()).join();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: SlideTransition(
            position: _headerSlide,
            child: FadeTransition(
              opacity: _headerFade,
              child: _TapScaleButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.arrow_back, color: kTeal, size: 20)),
              ),
            ),
          ),
          actions: [
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: kTeal, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(children: [
          // Avatar + name (scale spring)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              ScaleTransition(
                scale: _avatarScale,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kTeal, width: 2)),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF8A00), Color(0xFFE52EE5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Container(
                    width: 26, height: 26,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: kTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: kBg, width: 2)),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 13)),
                ]),
              ),
              const SizedBox(height: 12),
              FadeTransition(
                opacity: _statsFade,
                child: Column(children: [
                  Text(name,
                      style: TextStyle(
                          color: kText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Trader@truckmate.com',
                      style: TextStyle(color: kMuted, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 24),

              // Stats with counter
              SlideTransition(
                position: _statsSlide,
                child: FadeTransition(
                  opacity: _statsFade,
                  child: AnimatedBuilder(
                    animation: _counterCtrl,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailsStatItem(
                            icon: Icons.inventory_2_outlined,
                            value: '${_tripsCount.value}',
                            label: 'Total Ships',
                            kCard: kCard, kTeal: kTeal,
                            kText: kText, kBorder: kBorder, isDark: isDark),
                        _DetailsStatItem(
                            icon: Icons.access_time,
                            value: '12', label: 'Active',
                            kCard: kCard, kTeal: kTeal,
                            kText: kText, kBorder: kBorder, isDark: isDark),
                        _DetailsStatItem(
                            icon: Icons.check_circle_outline,
                            value: '${_completedCount.value}',
                            label: 'Completed',
                            kCard: kCard, kTeal: kTeal,
                            kText: kText, kBorder: kBorder, isDark: isDark),
                        _DetailsStatItem(
                            icon: Icons.people_outline,
                            value: '45', label: 'Drivers',
                            kCard: kCard, kTeal: kTeal,
                            kText: kText, kBorder: kBorder, isDark: isDark),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),

          // Tabs
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: kTeal,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: kTeal,
            unselectedLabelColor: kMuted,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
            tabs: const [Tab(text: 'About'), Tab(text: 'Shipments')],
          ),
          Divider(height: 1, color: kBorder),

          Expanded(
            child: SlideTransition(
              position: _tabContentSlide,
              child: FadeTransition(
                opacity: _tabContentFade,
                child: TabBarView(children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _AboutTab(
                        kCard: kCard, kText: kText, kMuted: kMuted,
                        kBorder: kBorder, isDark: isDark, user: user),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _ShipmentsTab(
                        kCard: kCard, kText: kText, kMuted: kMuted,
                        kBorder: kBorder, kTeal: kTeal, isDark: isDark),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DetailsStatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color kCard, kTeal, kText, kBorder;
  final bool isDark;

  const _DetailsStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.kCard,
    required this.kTeal,
    required this.kText,
    required this.kBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCard,
          shape: BoxShape.circle,
          border: Border.all(color: kBorder),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8)
                ],
        ),
        child: Icon(icon, color: kTeal, size: 22),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: TextStyle(
              color: kTeal,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
      Text(label,
          style: const TextStyle(color: Colors.grey, fontSize: 10)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  About Tab
// ══════════════════════════════════════════════════════════════════════════════
class _AboutTab extends StatelessWidget {
  final Color kCard, kText, kMuted, kBorder;
  final bool isDark;
  final UserProvider user;

  const _AboutTab({
    required this.kCard,
    required this.kText,
    required this.kMuted,
    required this.kBorder,
    required this.isDark,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final name  = user.fullName.isNotEmpty ? user.fullName  : 'Maro Ahmed Sameh';
    final email = user.email.isNotEmpty    ? user.email     : 'Maroahmed@truckmate.com';
    final phone = user.phone.isNotEmpty    ? user.phone     : '+2 01284892003';

    final items = <String, String>{
      'Full Name':          name,
      'Business Name':      'Smith Logistics Co.',
      'Email':              email,
      'Phone Number':       phone,
      'Total Shipments':    '70 Shipments',
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Trader Information',
          style: TextStyle(
              color: kText, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10)
                ],
        ),
        child: Column(
          children: items.entries.toList().asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            final kv     = entry.value;
            return Column(children: [
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(kv.key,
                        style:
                            TextStyle(color: kMuted, fontSize: 13)),
                    Flexible(
                      child: Text(kv.value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: kText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(color: kBorder, height: 1),
              if (!isLast) const SizedBox(height: 16),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Shipments Tab
// ══════════════════════════════════════════════════════════════════════════════
class _ShipmentsTab extends StatelessWidget {
  final Color kCard, kText, kMuted, kBorder, kTeal;
  final bool isDark;

  const _ShipmentsTab({
    required this.kCard,
    required this.kText,
    required this.kMuted,
    required this.kBorder,
    required this.kTeal,
    required this.isDark,
  });

  static const _shipments = [
    (id: '#2145', type: 'Heavy Duty',   from: 'Cairo',      to: 'Fayoum',  price: '\$220', status: 'Completed', duration: '3h 45m', km: 380),
    (id: '#2144', type: 'Medium Truck', from: 'Cairo',      to: 'Maadi',   price: '\$310', status: 'Pending',   duration: '4h 15m', km: 50),
    (id: '#2143', type: 'Heavy Duty',   from: 'Alexandria', to: 'Cairo',   price: '\$450', status: 'Completed', duration: '3h 30m', km: 385),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Shipments',
              style: TextStyle(
                  color: kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          _TapScaleButton(
            onTap: () {},
            child: Text('View All',
                style: TextStyle(color: kTeal, fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ..._shipments.map((s) => _ShipCard(
            s: s,
            kCard: kCard,
            kText: kText,
            kMuted: kMuted,
            kBorder: kBorder,
            kTeal: kTeal,
            isDark: isDark,
          )),
    ]);
  }
}

class _ShipCard extends StatelessWidget {
  final dynamic s;
  final Color kCard, kText, kMuted, kBorder, kTeal;
  final bool isDark;

  const _ShipCard({
    required this.s,
    required this.kCard,
    required this.kText,
    required this.kMuted,
    required this.kBorder,
    required this.kTeal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted  = s.status == 'Completed';
    final statusColor  = isCompleted ? kTeal : const Color(0xFFFF8C00);

    return _TapScaleButton(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8)
                ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Shipment ${s.id}',
                  style: TextStyle(color: kTeal, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(s.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.type,
              style: TextStyle(
                  color: kText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.location_on_outlined, color: kTeal, size: 14),
            const SizedBox(width: 4),
            Text('${s.from} → ${s.to}',
                style: TextStyle(color: kMuted, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.price,
                  style: TextStyle(
                      color: kText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Row(children: [
                Icon(Icons.access_time, color: kMuted, size: 14),
                const SizedBox(width: 4),
                Text(s.duration,
                    style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(width: 10),
                Icon(Icons.trending_up_rounded,
                    color: kMuted, size: 14),
                const SizedBox(width: 4),
                Text('${s.km} km',
                    style: TextStyle(color: kMuted, fontSize: 11)),
              ]),
            ],
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  _TapScaleButton  —  whileTap scale:0.97  (exact RN whileTap pattern)
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
        onTapDown: (_) => _ctrl.forward(),
        onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}
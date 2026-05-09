import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/providers/user_provider.dart';

// RN animations ported:
// • Header: opacity+x -20→0, easeOut 500ms
// • Profile card: opacity+y 20→0, delay 100ms, spring
// • Section groups: stagger opacity+y delay 200/350/500/650ms
// • Delete button: opacity+scale 0.9→1, delay 700ms
// • Save button: shimmer sweep x[-300→300] 2s linear infinite
// • whileTap scale:0.98 على كل row + save button

class TraderAdvancedSettingsScreen extends StatefulWidget {
  const TraderAdvancedSettingsScreen({super.key});
  @override
  State<TraderAdvancedSettingsScreen> createState() => _TraderAdvancedSettingsScreenState();
}

class _TraderAdvancedSettingsScreenState extends State<TraderAdvancedSettingsScreen>
    with TickerProviderStateMixin {

  late final AnimationController _headerCtrl;
  late final List<AnimationController> _sectionCtrls;  // 5 sections
  late final AnimationController _deleteBtnCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;
  late final Animation<double> _deleteFade, _deleteScale;
  late final Animation<double> _shimmerX;

  @override
  void initState() {
    super.initState();

    // Header
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // 5 sections: profile card + 3 setting cards + delete
    _sectionCtrls = List.generate(5,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _sectionFades = _sectionCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>).toList();
    _sectionSlides = _sectionCtrls.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Delete button: scale 0.9→1
    _deleteBtnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _deleteFade  = CurvedAnimation(parent: _deleteBtnCtrl, curve: Curves.easeOut);
    _deleteScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _deleteBtnCtrl, curve: Curves.easeOutBack));

    // Shimmer: x[-300→300] 2s linear infinite
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(_shimmerCtrl);

    // Stagger
    _headerCtrl.forward();
    final delays = [100, 200, 350, 500, 650];
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) _sectionCtrls[i].forward();
      });
    }
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _deleteBtnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _sectionCtrls) { c.dispose(); }
    _deleteBtnCtrl.dispose(); _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final user   = context.watch<UserProvider>();
    final name   = user.fullName.isNotEmpty ? user.fullName : 'Maro Ahmed';
    final initials = name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF152232) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00D5BE);
    const kRed    = Color(0xFFFF476D);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [
        // Header: x -20→0
        SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(children: [
                _TapScaleButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: kCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: kTeal, size: 16))),
                const SizedBox(width: 14),
                Text('Advanced Settings', style: TextStyle(
                    color: kText, fontSize: 20, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Profile card: delay 100ms
            SlideTransition(position: _sectionSlides[0], child: FadeTransition(
              opacity: _sectionFades[0],
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kBorder),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04),
                        blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: kTeal, width: 2),
                        color: isDark ? const Color(0xFF1A3550) : const Color(0xFFE8F5F4)),
                    alignment: Alignment.center,
                    child: Text(initials, style: const TextStyle(
                        color: kTeal, fontSize: 16, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                          color: kTeal.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kTeal.withOpacity(0.3))),
                      child: const Text('Trader', style: TextStyle(
                          color: kTeal, fontSize: 11, fontWeight: FontWeight.w600))),
                  ]),
                ]),
              ),
            )),
            const SizedBox(height: 28),

            // Section 1: Account Security — delay 200ms
            SlideTransition(position: _sectionSlides[1], child: FadeTransition(
              opacity: _sectionFades[1],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('ACCOUNT SECURITY', kMuted),
                const SizedBox(height: 10),
                _SettingsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _SettingsItem(icon: Icons.lock_outline_rounded,
                      title: 'Change Password', subtitle: 'Update your account password',
                      kText: kText, kMuted: kMuted, kTeal: kTeal, isDark: isDark, onTap: () {}),
                  _SettingsItem(icon: Icons.mail_outline_rounded,
                      title: 'Update Email / Phone', subtitle: 'Manage your contact information',
                      kText: kText, kMuted: kMuted, kTeal: kTeal, isDark: isDark,
                      onTap: () {}, isLast: true),
                ]),
              ]),
            )),
            const SizedBox(height: 24),

            // Section 2: Preferences — delay 350ms
            SlideTransition(position: _sectionSlides[2], child: FadeTransition(
              opacity: _sectionFades[2],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('PREFERENCES', kMuted),
                const SizedBox(height: 10),
                _SettingsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _SettingsItem(icon: Icons.notifications_none_rounded,
                      title: 'Notification Preferences',
                      subtitle: 'Control how and when you receive notifications',
                      kText: kText, kMuted: kMuted, kTeal: kTeal, isDark: isDark,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const TraderNotifPreferencesScreen())),
                      isLast: true),
                ]),
              ]),
            )),
            const SizedBox(height: 24),

            // Section 3: Privacy & Legal — delay 500ms
            SlideTransition(position: _sectionSlides[3], child: FadeTransition(
              opacity: _sectionFades[3],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('PRIVACY & LEGAL', kMuted),
                const SizedBox(height: 10),
                _SettingsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _SettingsItem(icon: Icons.shield_outlined,
                      title: 'Privacy & Security', subtitle: 'Manage privacy and data permissions',
                      kText: kText, kMuted: kMuted, kTeal: kTeal, isDark: isDark, onTap: () {}),
                  _SettingsItem(icon: Icons.description_outlined,
                      title: 'Terms & Policies', subtitle: 'View terms, privacy policy, and agreements',
                      kText: kText, kMuted: kMuted, kTeal: kTeal, isDark: isDark,
                      onTap: () {}, isLast: true),
                ]),
              ]),
            )),
            const SizedBox(height: 24),

            // Delete button: scale 0.9→1, delay 700ms
            ScaleTransition(
              scale: _deleteScale,
              child: FadeTransition(
                opacity: _deleteFade,
                child: _TapScaleButton(
                  onTap: () => _showDeleteDialog(context, isDark),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kRed.withOpacity(0.3))),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: kRed.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.delete_outline_rounded, color: kRed, size: 20)),
                      const SizedBox(width: 14),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Delete Account', style: TextStyle(
                            color: kRed, fontSize: 15, fontWeight: FontWeight.w700)),
                        SizedBox(height: 2),
                        Text('Permanently remove your account and data',
                            style: TextStyle(color: kRed, fontSize: 12)),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, color: kRed, size: 14),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        )),
      ])),
    );
  }

  void _showDeleteDialog(BuildContext context, bool isDark) {
    final kCard  = isDark ? const Color(0xFF152232) : Colors.white;
    final kText  = isDark ? Colors.white : const Color(0xFF1A2A3A);
    final kMuted = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: TextStyle(color: kText, fontWeight: FontWeight.bold)),
        content: Text('Are you sure? This action cannot be undone.', style: TextStyle(color: kMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: kMuted))),
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Delete', style: TextStyle(
                  color: Color(0xFFFF476D), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// ── Notification Preferences Screen ───────────────────

class TraderNotifPreferencesScreen extends StatefulWidget {
  const TraderNotifPreferencesScreen({super.key});
  @override
  State<TraderNotifPreferencesScreen> createState() => _TraderNotifPreferencesScreenState();
}

class _TraderNotifPreferencesScreenState extends State<TraderNotifPreferencesScreen>
    with TickerProviderStateMixin {

  // Toggles
  bool _shipmentAccepted = true, _driverAssigned = true, _driverOnTheWay = true;
  bool _shipmentPickedUp = false, _shipmentDelivered = true, _shipmentCancelled = false;
  bool _newOfferFromDriver = true, _priceUpdates = false, _recommendedDrivers = true;
  bool _messagesChat = true, _emailNotifs = true, _smsNotifs = false;
  bool _appAnnouncements = true, _maintenanceAlerts = false;

  late final AnimationController _headerCtrl;
  late final List<AnimationController> _sectionCtrls;
  late final AnimationController _saveBtnCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;
  late final Animation<double> _saveFade, _saveScale, _shimmerX;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _headerFade  = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(begin: const Offset(-0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut));

    // 4 sections: Shipment, Offers, Communication, System
    _sectionCtrls = List.generate(4,
        (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 450)));
    _sectionFades = _sectionCtrls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut) as Animation<double>).toList();
    _sectionSlides = _sectionCtrls.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut))).toList();

    // Save button
    _saveBtnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _saveFade  = CurvedAnimation(parent: _saveBtnCtrl, curve: Curves.easeOut);
    _saveScale = Tween<double>(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _saveBtnCtrl, curve: Curves.easeOutBack));

    // Shimmer على save button
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _shimmerX = Tween<double>(begin: -300, end: 300).animate(_shimmerCtrl);

    _headerCtrl.forward();
    final delays = [100, 250, 400, 550];
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: delays[i]), () {
        if (mounted) _sectionCtrls[i].forward();
      });
    }
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _saveBtnCtrl.forward();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    for (final c in _sectionCtrls) { c.dispose(); }
    _saveBtnCtrl.dispose(); _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final user   = context.watch<UserProvider>();
    final name   = user.fullName.isNotEmpty ? user.fullName : 'Maro Ahmed';
    final initials = name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join();

    final kBg     = isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA);
    final kCard   = isDark ? const Color(0xFF152232) : Colors.white;
    final kText   = isDark ? Colors.white            : const Color(0xFF1A2A3A);
    final kMuted  = isDark ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);
    final kBorder = isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
    const kTeal   = Color(0xFF00D5BE);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [

        // Header
        SlideTransition(position: _headerSlide, child: FadeTransition(
          opacity: _headerFade,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(children: [
              _TapScaleButton(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: kTeal, size: 16))),
              const SizedBox(width: 14),
              Text('Notification Preferences', style: TextStyle(
                  color: kText, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
          ),
        )),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Shipment Updates: delay 100ms
            SlideTransition(position: _sectionSlides[0], child: FadeTransition(
              opacity: _sectionFades[0],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('Shipment Updates', kMuted),
                const SizedBox(height: 10),
                _PrefsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _PrefItem(icon: Icons.check_circle_outline, title: 'Shipment Accepted',
                      value: _shipmentAccepted, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _shipmentAccepted = v)),
                  _PrefItem(icon: Icons.person_outline, title: 'Driver Assigned',
                      value: _driverAssigned, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _driverAssigned = v)),
                  _PrefItem(icon: Icons.local_shipping_outlined, title: 'Driver On The Way',
                      value: _driverOnTheWay, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _driverOnTheWay = v)),
                  _PrefItem(icon: Icons.inventory_2_outlined, title: 'Shipment Picked Up',
                      value: _shipmentPickedUp, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _shipmentPickedUp = v)),
                  _PrefItem(icon: Icons.done_all_rounded, title: 'Shipment Delivered',
                      value: _shipmentDelivered, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _shipmentDelivered = v)),
                  _PrefItem(icon: Icons.cancel_outlined, title: 'Shipment Cancelled',
                      value: _shipmentCancelled, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _shipmentCancelled = v), isLast: true),
                ]),
              ]),
            )),
            const SizedBox(height: 22),

            // Offers: delay 250ms
            SlideTransition(position: _sectionSlides[1], child: FadeTransition(
              opacity: _sectionFades[1],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('Offers & Matching', kMuted),
                const SizedBox(height: 10),
                _PrefsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _PrefItem(icon: Icons.notifications_none_rounded, title: 'New Offer From a Driver',
                      value: _newOfferFromDriver, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _newOfferFromDriver = v)),
                  _PrefItem(icon: Icons.attach_money_rounded, title: 'Price Updates',
                      value: _priceUpdates, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _priceUpdates = v)),
                  _PrefItem(icon: Icons.star_outline_rounded, title: 'Recommended Drivers',
                      value: _recommendedDrivers, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _recommendedDrivers = v), isLast: true),
                ]),
              ]),
            )),
            const SizedBox(height: 22),

            // Communication: delay 400ms
            SlideTransition(position: _sectionSlides[2], child: FadeTransition(
              opacity: _sectionFades[2],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('Communication', kMuted),
                const SizedBox(height: 10),
                _PrefsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _PrefItem(icon: Icons.chat_bubble_outline_rounded, title: 'Messages / Chat Notifications',
                      value: _messagesChat, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _messagesChat = v)),
                  _PrefItem(icon: Icons.mail_outline_rounded, title: 'Email Notifications',
                      value: _emailNotifs, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _emailNotifs = v)),
                  _PrefItem(icon: Icons.sms_outlined, title: 'SMS Notifications',
                      value: _smsNotifs, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _smsNotifs = v), isLast: true),
                ]),
              ]),
            )),
            const SizedBox(height: 22),

            // System: delay 550ms
            SlideTransition(position: _sectionSlides[3], child: FadeTransition(
              opacity: _sectionFades[3],
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('System', kMuted),
                const SizedBox(height: 10),
                _PrefsCard(isDark: isDark, kCard: kCard, kBorder: kBorder, items: [
                  _PrefItem(icon: Icons.campaign_outlined, title: 'App Announcements',
                      value: _appAnnouncements, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _appAnnouncements = v)),
                  _PrefItem(icon: Icons.warning_amber_outlined, title: 'Maintenance Alerts',
                      value: _maintenanceAlerts, kText: kText, kTeal: kTeal, isDark: isDark,
                      onChanged: (v) => setState(() => _maintenanceAlerts = v), isLast: true),
                ]),
              ]),
            )),
          ]),
        )),
      ])),

      // Save button: scale + shimmer
      bottomNavigationBar: ScaleTransition(
        scale: _saveScale,
        child: FadeTransition(
          opacity: _saveFade,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1F2D) : const Color(0xFFF5F8FA),
              border: Border(top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0)))),
            child: _TapScaleButton(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Preferences saved!'),
                  backgroundColor: const Color(0xFF00D5BE),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
                Navigator.pop(context);
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF009EA3), Color(0xFF00D5BE)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF00D5BE).withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 6))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(alignment: Alignment.center, children: [
                    // Shimmer sweep
                    AnimatedBuilder(
                      animation: _shimmerX,
                      builder: (_, __) => Positioned(
                        left: _shimmerX.value - 40, top: 0, bottom: 0,
                        child: Container(width: 80,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [
                            Colors.transparent, Colors.white.withOpacity(0.15), Colors.transparent])))),
                    ),
                    const Text('Save Preferences', style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text; final Color color;
  const _SectionLabel(this.text, this.color);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2));
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items; final bool isDark; final Color kCard, kBorder;
  const _SettingsCard({required this.items, required this.isDark, required this.kCard, required this.kBorder});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(children: items));
}

class _SettingsItem extends StatelessWidget {
  final IconData icon; final String title, subtitle;
  final bool isLast, isDark; final Color kText, kMuted, kTeal;
  final VoidCallback? onTap;
  const _SettingsItem({required this.icon, required this.title, required this.subtitle,
    required this.kText, required this.kMuted, required this.kTeal, required this.isDark,
    this.isLast = false, this.onTap});
  Color get _border => isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
  @override
  Widget build(BuildContext context) => Column(children: [
    _TapScaleButton(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: kTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: kTeal, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: kMuted, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: kMuted, size: 14),
        ]),
      ),
    ),
    if (!isLast) Divider(height: 1, color: _border, indent: 70),
  ]);
}

class _PrefsCard extends StatelessWidget {
  final List<_PrefItem> items; final bool isDark; final Color kCard, kBorder;
  const _PrefsCard({required this.items, required this.isDark, required this.kCard, required this.kBorder});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder)),
    child: Column(children: items));
}

class _PrefItem extends StatelessWidget {
  final IconData icon; final String title;
  final bool value, isLast, isDark; final Color kText, kTeal;
  final ValueChanged<bool> onChanged;
  const _PrefItem({required this.icon, required this.title, required this.value,
    required this.kText, required this.kTeal, required this.isDark,
    required this.onChanged, this.isLast = false});
  Color get _border => isDark ? const Color(0xFF1A3550) : const Color(0xFFE2EAF0);
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: kTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: kTeal, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(
            color: kText, fontSize: 13, fontWeight: FontWeight.w500))),
        Switch(value: value, onChanged: onChanged,
          activeColor: kTeal, activeTrackColor: kTeal.withOpacity(0.3),
          inactiveThumbColor: isDark ? Colors.grey[600] : Colors.grey[400],
          inactiveTrackColor: isDark ? const Color(0xFF1A3550) : Colors.grey[200]),
      ]),
    ),
    if (!isLast) Divider(height: 1, color: _border, indent: 62),
  ]);
}

// whileTap scale:0.98
class _TapScaleButton extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _TapScaleButton({required this.child, required this.onTap});
  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}
class _TapScaleButtonState extends State<_TapScaleButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
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
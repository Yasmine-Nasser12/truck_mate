// ════════════════════════════════════════════════════════════
//  trips_screen.dart  — Full Animations
// ════════════════════════════════════════════════════════════

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

const Color _kTeal  = Color(0xFF00D5BE);
const Color _kAmber = Color(0xFFF59E0B);

Color _bg(bool d)     => d ? const Color(0xFF0F2334) : const Color(0xFFF5F8FA);
Color _card(bool d)   => d ? const Color(0xFF112236) : Colors.white;
Color _border(bool d) => d ? Colors.white.withOpacity(0.06) : const Color(0xFFE2EAF0);
Color _text(bool d)   => d ? const Color(0xFFE8F0F8) : const Color(0xFF1A2A3A);
Color _muted(bool d)  => d ? const Color(0xFF5F7E97) : const Color(0xFF8A9BB0);

enum TripStatus { inProgress, scheduled, completed }
enum FilterType { all, upcoming, completed }

class TripModel {
  final String id, date, from, to;
  final int miles;
  final TripStatus status;
  final double? progress;
  const TripModel({
    required this.id, required this.date,
    required this.from, required this.to,
    required this.miles, required this.status,
    this.progress,
  });
}

const List<TripModel> kTrips = [
  TripModel(id: 'TR-4721', date: 'Dec 16, 2025', from: 'Nasr City',
      to: 'Maadi', miles: 382, status: TripStatus.inProgress, progress: 0.47),
  TripModel(id: 'TR-4722', date: 'Dec 17, 2025', from: 'Maadi',
      to: 'Nasr City', miles: 124, status: TripStatus.scheduled),
  TripModel(id: 'TR-4723', date: 'Dec 17, 2025', from: 'Maadi',
      to: 'Zamalik', miles: 355, status: TripStatus.scheduled),
  TripModel(id: 'TR-4718', date: 'Dec 14, 2025', from: 'Zamalik',
      to: 'Dokki', miles: 87, status: TripStatus.completed),
  TripModel(id: 'TR-4715', date: 'Dec 14, 2025', from: 'Zamalik',
      to: 'Dokki', miles: 52, status: TripStatus.completed),
];

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with TickerProviderStateMixin {
  FilterType _filter = FilterType.all;

  late AnimationController _pageCtrl;
  late List<Animation<double>> _itemAnims;

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _itemAnims = List.generate(8, (i) {
      final s = (i * 0.09).clamp(0.0, 0.8);
      final e = (s + 0.4).clamp(0.0, 1.0);
      return CurvedAnimation(parent: _pageCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic));
    });
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  List<TripModel> get _filteredOthers {
    final others = kTrips.where((t) => t.status != TripStatus.inProgress).toList();
    switch (_filter) {
      case FilterType.upcoming:
        return others.where((t) => t.status == TripStatus.scheduled).toList();
      case FilterType.completed:
        return others.where((t) => t.status == TripStatus.completed).toList();
      case FilterType.all: return others;
    }
  }

  bool get _showActive =>
      _filter == FilterType.all || _filter == FilterType.upcoming;

  void _openFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Spring transition matching React Native spring(damping:35, stiffness:400)
      transitionAnimationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
      builder: (_) => FilterSheet(
        current: _filter,
        onSelect: (f) { setState(() => _filter = f); Navigator.pop(context); },
      ),
    );
  }

  Widget _animItem(int idx, Widget child) {
    final anim = _itemAnims[idx.clamp(0, _itemAnims.length - 1)];
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
    final d = context.watch<ThemeProvider>().isDark;
    final active = kTrips.firstWhere((t) => t.status == TripStatus.inProgress);
    final others = _filteredOthers;

    return Scaffold(
      backgroundColor: _bg(d),
      body: SafeArea(child: Column(children: [
        // Header
        _animItem(0, Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 16, 0),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: _card(d), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border(d))),
                child: const Icon(Icons.arrow_back_rounded, color: _kTeal, size: 18),
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trips', style: TextStyle(
                  color: _text(d), fontSize: 22, fontWeight: FontWeight.w700)),
              Text('Manage your deliveries',
                  style: TextStyle(color: _muted(d), fontSize: 12.5)),
            ]),
            const Spacer(),
            _FilterButton(active: _filter != FilterType.all,
                onTap: _openFilter, isDark: d),
          ]),
        )),

        if (_filter != FilterType.all)
          _animItem(1, Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _FilterTag(
                label: _filter == FilterType.upcoming ? 'Upcoming' : 'Completed',
                onRemove: () => setState(() => _filter = FilterType.all),
              ),
            ),
          )),

        const SizedBox(height: 20),

        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            if (_showActive) ...[
              _animItem(1, _SectionLabel('Active Now', muted: _muted(d))),
              const SizedBox(height: 10),
              _animItem(2, _ActiveCard(
                trip: active, onTap: () {}, isDark: d,
                cardBg: _card(d), textColor: _text(d),
                mutedColor: _muted(d), borderColor: _border(d))),
              const SizedBox(height: 20),
            ],
            _animItem(3, _SectionLabel('Other Trips', muted: _muted(d))),
            const SizedBox(height: 10),
            // AnimatePresence popLayout → AnimatedList equivalent
            for (int i = 0; i < others.length; i++)
              _animItem(4 + i, Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OtherCard(
                  trip: others[i], onTap: () {}, isDark: d,
                  cardBg: _card(d), textColor: _text(d),
                  mutedColor: _muted(d), borderColor: _border(d)),
              )),
            const SizedBox(height: 8),
          ],
        )),
      ])),
    );
  }
}

// ── Filter Button (bounce on tap) ──
class _FilterButton extends StatefulWidget {
  final bool active, isDark;
  final VoidCallback onTap;
  const _FilterButton({required this.active, required this.onTap, required this.isDark});
  @override
  State<_FilterButton> createState() => _FilterButtonState();
}

class _FilterButtonState extends State<_FilterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { _ctrl.forward(from: 0); widget.onTap(); },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: widget.active
                ? _kTeal.withOpacity(widget.isDark ? 0.3 : 0.15)
                : _card(widget.isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.active
                ? _kTeal.withOpacity(0.4) : _border(widget.isDark))),
          child: const Icon(Icons.filter_alt_outlined, color: _kTeal, size: 20),
        ),
      ),
    );
  }
}

// ── Filter Tag ──
class _FilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterTag({required this.label, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
    decoration: BoxDecoration(
      color: _kTeal.withOpacity(0.12),
      border: Border.all(color: _kTeal.withOpacity(0.35)),
      borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: const TextStyle(
          color: _kTeal, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: onRemove,
        child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
              color: _kTeal.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.close, color: _kTeal, size: 10)),
      ),
    ]),
  );
}

// ── Active Card (with animated progress bar) ──
class _ActiveCard extends StatefulWidget {
  final TripModel trip;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardBg, textColor, mutedColor, borderColor;
  const _ActiveCard({
    required this.trip, required this.onTap, required this.isDark,
    required this.cardBg, required this.textColor,
    required this.mutedColor, required this.borderColor,
  });
  @override
  State<_ActiveCard> createState() => _ActiveCardState();
}

class _ActiveCardState extends State<_ActiveCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _prog;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1100));
    _prog = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pct = ((widget.trip.progress ?? 0) * 100).round();
    final progressBg = widget.isDark
        ? const Color(0xFF1B3A52) : const Color(0xFFDFF4F2);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: widget.borderColor),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 12, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: _kTeal.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.navigation_rounded, color: _kTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trip #${widget.trip.id}',
                    style: TextStyle(color: widget.textColor,
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                Text(widget.trip.date,
                    style: TextStyle(color: widget.mutedColor, fontSize: 11.5)),
              ]),
              const Spacer(),
              _StatusBadge(status: widget.trip.status),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  color: _kTeal.withOpacity(0.6), size: 14),
              const SizedBox(width: 5),
              Text('${widget.trip.from}  →  ${widget.trip.to}',
                  style: TextStyle(color: widget.textColor, fontSize: 13)),
              const Spacer(),
              Text('${widget.trip.miles} mi',
                  style: TextStyle(color: widget.mutedColor, fontSize: 12.5)),
            ]),
            const SizedBox(height: 13),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progress',
                  style: TextStyle(color: widget.mutedColor, fontSize: 11.5)),
              Text('$pct%', style: const TextStyle(
                  color: _kTeal, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            // Animated progress bar (width: 0 → progress%)
            AnimatedBuilder(
              animation: _prog,
              builder: (_, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: [
                  Container(height: 5, color: progressBg),
                  FractionallySizedBox(
                    widthFactor: (widget.trip.progress ?? 0) * _prog.value,
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kTeal, Color(0xFF00D3F2)]),
                        borderRadius: BorderRadius.all(Radius.circular(4))),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 13),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('View Details', style: TextStyle(
                  color: _kTeal, fontSize: 12.5, fontWeight: FontWeight.w500)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: _kTeal, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Other Card ──
class _OtherCard extends StatefulWidget {
  final TripModel trip;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardBg, textColor, mutedColor, borderColor;
  const _OtherCard({
    required this.trip, required this.onTap, required this.isDark,
    required this.cardBg, required this.textColor,
    required this.mutedColor, required this.borderColor,
  });
  @override
  State<_OtherCard> createState() => _OtherCardState();
}

class _OtherCardState extends State<_OtherCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: widget.borderColor),
            boxShadow: widget.isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 8, offset: const Offset(0, 2))],
          ),
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Trip #${widget.trip.id}',
                  style: TextStyle(color: widget.textColor,
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
              const Spacer(),
              _StatusBadge(status: widget.trip.status),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.calendar_today_outlined,
                  color: widget.mutedColor, size: 13),
              const SizedBox(width: 5),
              Text(widget.trip.date,
                  style: TextStyle(color: widget.mutedColor, fontSize: 11.5)),
            ]),
            const SizedBox(height: 5),
            Row(children: [
              Icon(Icons.location_on_outlined,
                  color: _kTeal.withOpacity(0.6), size: 13),
              const SizedBox(width: 5),
              Text('${widget.trip.from}  →  ${widget.trip.to}',
                  style: TextStyle(color: widget.textColor, fontSize: 12.5)),
              const Spacer(),
              Text('${widget.trip.miles} mi',
                  style: TextStyle(color: widget.mutedColor, fontSize: 11.5)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: widget.mutedColor, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── Status Badge ──
class _StatusBadge extends StatelessWidget {
  final TripStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    late Color color; late String label;
    switch (status) {
      case TripStatus.inProgress: color = const Color(0xFF00D4E0); label = 'In Progress'; break;
      case TripStatus.scheduled:  color = const Color(0xFFFF8904); label = 'Scheduled'; break;
      case TripStatus.completed:  color = _kTeal; label = 'Completed'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(
          color: color, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Filter Bottom Sheet (spring animation) ──
class FilterSheet extends StatelessWidget {
  final FilterType current;
  final ValueChanged<FilterType> onSelect;
  const FilterSheet({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final sheetBg = isDark ? const Color(0xFF0D1E2E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE8F0F8) : const Color(0xFF1A2A3A);
    final handleColor = isDark
        ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.10);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: handleColor, borderRadius: BorderRadius.circular(3))),
        Row(children: [
          Text('Filter Trips', style: TextStyle(
              color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A3550) : const Color(0xFFF0F4F8),
                shape: BoxShape.circle),
              child: Icon(Icons.close, color: textColor, size: 14)),
          ),
        ]),
        const SizedBox(height: 18),
        _FilterOption(label: 'All Trips',
            selected: current == FilterType.all,
            onTap: () => onSelect(FilterType.all), isDark: isDark),
        const SizedBox(height: 10),
        _FilterOption(label: 'Upcoming',
            selected: current == FilterType.upcoming,
            onTap: () => onSelect(FilterType.upcoming), isDark: isDark),
        const SizedBox(height: 10),
        _FilterOption(label: 'Completed',
            selected: current == FilterType.completed,
            onTap: () => onSelect(FilterType.completed), isDark: isDark),
      ]),
    );
  }
}

class _FilterOption extends StatefulWidget {
  final String label;
  final bool selected, isDark;
  final VoidCallback onTap;
  const _FilterOption({
    required this.label, required this.selected,
    required this.onTap, required this.isDark,
  });
  @override
  State<_FilterOption> createState() => _FilterOptionState();
}

class _FilterOptionState extends State<_FilterOption> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final unselBg = widget.isDark ? const Color(0xFF112236) : const Color(0xFFF5F8FA);
    final textColor = widget.isDark ? const Color(0xFFE8F0F8) : const Color(0xFF1A2A3A);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: widget.selected
                ? _kTeal.withOpacity(widget.isDark ? 0.3 : 0.12)
                : unselBg,
            border: Border.all(
              color: widget.selected ? _kTeal : Colors.transparent,
              width: 1.5),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text(widget.label, style: TextStyle(
                color: textColor, fontSize: 14,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.selected ? _kTeal : Colors.transparent,
                border: Border.all(
                  color: widget.selected ? _kTeal
                      : (widget.isDark
                          ? Colors.white.withOpacity(0.25)
                          : Colors.black.withOpacity(0.2)),
                  width: 2)),
              child: widget.selected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color muted;
  const _SectionLabel(this.text, {required this.muted});
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w500));
}
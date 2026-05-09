import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/providers/user_provider.dart';

// ══════════════════════════════════════════
//  TRADER OTP SCREEN - same design as Driver OTP
// ══════════════════════════════════════════
class TraderOtpScreen extends StatefulWidget {
  final String fullName;
  final String phone;
  final String email;
  final String nationalId;
  final String password;
  final String businessName;
  final String address;

  const TraderOtpScreen({
    super.key,
    this.fullName = '',
    this.phone = '',
    this.email = '',
    this.nationalId = '',
    this.password = '',
    this.businessName = '',
    this.address = '',
  });

  @override
  State<TraderOtpScreen> createState() => _TraderOtpScreenState();
}

class _TraderOtpScreenState extends State<TraderOtpScreen>
    with TickerProviderStateMixin {
  static const String _defaultOtp = '0000';

  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;
  bool _isSubmitting = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  late final AnimationController _rotateCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _entranceCtrl;
  late final List<Animation<double>> _fadeSeries;
  late final List<Animation<Offset>> _slideSeries;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(4, (_) => TextEditingController());
    _focusNodes     = List.generate(4, (_) => FocusNode());

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();

    _dotsCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..forward();

    final intervals = [
      const Interval(0.0, 0.45),
      const Interval(0.15, 0.60),
      const Interval(0.28, 0.72),
      const Interval(0.40, 0.85),
      const Interval(0.55, 1.0),
    ];
    _fadeSeries = intervals
        .map((iv) => CurvedAnimation(
            parent: _entranceCtrl,
            curve: Interval(iv.begin, iv.end, curve: Curves.easeOut)))
        .toList();
    _slideSeries = _fadeSeries
        .map((a) => Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(a))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _otpControllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _dotsCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (value.isNotEmpty && index < _focusNodes.length - 1)
      _focusNodes[index + 1].requestFocus();
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length == 4) _submitOtp();
  }

  void _submitOtp() async {
    if (_isSubmitting) return;
    final entered = _otpControllers.map((c) => c.text).join();
    if (entered.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit OTP.')));
      return;
    }
    if (entered != _defaultOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Default OTP is 0000.')));
      return;
    }
    _isSubmitting = true;
    // Save to UserProvider
    context.read<UserProvider>().update(
      fullName:   widget.fullName,
      phone:      widget.phone,
      email:      widget.email,
      nationalId: widget.nationalId,
    );
    // ✅ حفظ الـ role عشان الـ Login يعرف
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastRole', 'trader');
    // ✅ حفظ الـ email مع الـ role عشان نمنع التسجيل مرتين
    final registeredEmails = prefs.getStringList('registeredEmails') ?? [];
    if (!registeredEmails.contains(widget.email)) {
      registeredEmails.add('${widget.email}:trader');
    }
    await prefs.setStringList('registeredEmails', registeredEmails);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/driver_otp_7', (route) => false);
  }

  Widget _stagger(int i, Widget child) => FadeTransition(
        opacity: _fadeSeries[i],
        child: SlideTransition(position: _slideSeries[i], child: child),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: t.isDark ? const Color(0xFF0F2334) : const Color(0xFFF4F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // ── Animated Shield ──
                    _stagger(0,
                      SizedBox(
                        width: 130, height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // outer rotating ring
                            AnimatedBuilder(
                              animation: _rotateCtrl,
                              builder: (_, __) => Transform.rotate(
                                angle: _rotateCtrl.value * 2 * pi,
                                child: Container(
                                  width: 185, height: 185,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF00D5BE).withOpacity(0.15),
                                      width: 1),
                                  ),
                                ),
                              ),
                            ),
                            // inner counter-rotating ring
                            AnimatedBuilder(
                              animation: _rotateCtrl,
                              builder: (_, __) => Transform.rotate(
                                angle: -_rotateCtrl.value * 2 * pi * 0.65,
                                child: Container(
                                  width: 150, height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFF8904).withOpacity(0.12),
                                      width: 1),
                                  ),
                                ),
                              ),
                            ),
                            // pulsing circle
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  width: 132, height: 132,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.isDark ? const Color(0xFF0D1E2E) : const Color(0xFFFFFFFF),
                                    border: Border.all(
                                      color: const Color(0xFF00D5BE).withOpacity(0.35),
                                      width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D5BE)
                                            .withOpacity(0.1 + 0.12 * _pulseAnim.value),
                                        blurRadius: 26,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // shield icon
                            const Icon(Icons.shield_outlined,
                                color: Color(0xFF00D5BE), size: 52),
                            // floating dots
                            ..._buildDots(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Title ──
                    _stagger(1,
                      Column(children: [
                        Text('OTP Verification',
                            style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'We sent a verification code to\n${widget.email.isEmpty ? 'your email' : widget.email}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: t.textMuted, fontSize: 13.5),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 36),

                    // ── OTP Boxes ──
                    _stagger(2,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(4, (i) => _AnimatedOtpBox(
                            controller: _otpControllers[i],
                            focusNode: _focusNodes[i],
                            enterDelay: Duration(milliseconds: 60 * i),
                            onChanged: (v) => _onOtpChanged(i, v),
                            onBackspaceWhenEmpty: () {
                              if (i > 0) _focusNodes[i - 1].requestFocus();
                            },
                          )),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Hint ──
                    _stagger(2,
                      Text('Default OTP: 0000',
                          style: TextStyle(
                              color: t.textMuted, fontSize: 12)),
                    ),

                    const SizedBox(height: 28),

                    // ── Verify Button ──
                    _stagger(3,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _PressableButton(
                          label: 'Verify & Create Account',
                          onTap: _submitOtp,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Resend ──
                    _stagger(4,
                      Column(children: [
                        Text('Default OTP: 0000',
                            style: TextStyle(color: t.textMuted, fontSize: 11)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            for (final c in _otpControllers) c.clear();
                            _focusNodes[0].requestFocus();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('OTP resent! Default: 0000'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Color(0xFF00D5BE),
                              ));
                          },
                          child: const Text('Resend OTP',
                              style: TextStyle(
                                  color: Color(0xFF00D5BE), fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDots() {
    final positions = [
      {'top': 42.0, 'left': 26.0},
      {'top': 26.0, 'left': 46.0},
      {'top': 42.0, 'right': 26.0},
      {'top': 26.0, 'right': 46.0},
      {'bottom': 42.0, 'left': 26.0},
      {'bottom': 26.0, 'left': 46.0},
      {'bottom': 42.0, 'right': 26.0},
      {'bottom': 26.0, 'right': 46.0},
    ];
    return positions.asMap().entries.map((entry) {
      final i = entry.key;
      final pos = entry.value;
      final color = i % 3 == 0 ? const Color(0xFFFF8904) : const Color(0xFF00D5BE);
      return Positioned(
        top: pos['top'], bottom: pos['bottom'],
        left: pos['left'], right: pos['right'],
        child: AnimatedBuilder(
          animation: _dotsCtrl,
          builder: (_, __) {
            final t = (_dotsCtrl.value + i * 0.13) % 1.0;
            final opacity = 0.28 + 0.6 * sin(t * pi);
            final scale = 0.75 + 0.45 * sin(t * pi);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(
                    color: color.withOpacity(opacity * 0.55),
                    blurRadius: 5)],
                ),
              ),
            );
          },
        ),
      );
    }).toList();
  }
}

// ── Pressable gradient button ──
class _PressableButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PressableButton({required this.label, required this.onTap});
  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity, height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D5BE).withOpacity(0.85),
                const Color(0xFF00D3F2).withOpacity(0.85),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: const Color(0xFF00D5BE).withOpacity(0.3),
              blurRadius: 18, offset: const Offset(0, 6))],
          ),
          alignment: Alignment.center,
          child: Text(widget.label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ── Animated OTP Box ──
class _AnimatedOtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceWhenEmpty;
  final Duration enterDelay;
  const _AnimatedOtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspaceWhenEmpty,
    this.enterDelay = Duration.zero,
  });
  @override
  State<_AnimatedOtpBox> createState() => _AnimatedOtpBoxState();
}

class _AnimatedOtpBoxState extends State<_AnimatedOtpBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final Animation<double> _enterScale;
  late final Animation<double> _enterFade;
  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _enterScale = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.elasticOut));
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    Future.delayed(widget.enterDelay, () { if (mounted) _enterCtrl.forward(); });
  }
  @override
  void dispose() { _enterCtrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
      final t = context.watch<ThemeProvider>().theme;
    return FadeTransition(
      opacity: _enterFade,
      child: ScaleTransition(
        scale: _enterScale,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (_, __, ___) => AnimatedBuilder(
            animation: widget.focusNode,
            builder: (_, __) {
              final isFocused = widget.focusNode.hasFocus;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 55, height: 55,
                decoration: BoxDecoration(
                  color: t.isDark ? const Color(0xFF0A1828) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFocused
                        ? const Color(0xFF00D5BE)
                        : const Color(0xFF00D5BE).withOpacity(0.45),
                    width: isFocused ? 2 : 1.5,
                  ),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF00D5BE)
                        .withOpacity(isFocused ? 0.35 : 0.12),
                    blurRadius: isFocused ? 16 : 6,
                    spreadRadius: isFocused ? 2 : 0,
                  )],
                ),
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace &&
                        widget.controller.text.isEmpty) {
                      widget.onBackspaceWhenEmpty();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: widget.onChanged,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                        color: t.isDark ? Colors.white : const Color(0xFF1A2A3A), fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      isCollapsed: false,
                    ),
                    cursorColor: Color(0xFF00D5BE),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
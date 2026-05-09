import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';
import '/screen/trader/trader_otp_screen.dart';

class TraderReviewConfirmScreen extends StatelessWidget {
  final String fullName, phone, email, nationalId, password, businessName, address;
  const TraderReviewConfirmScreen({super.key,
    this.fullName='', this.phone='', this.email='',
    this.nationalId='', this.password='',
    this.businessName='', this.address=''});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().theme;
    return Scaffold(
      backgroundColor: t.regBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(children: [
              // ── Back ──
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(
                      color: t.fieldBg, shape: BoxShape.circle,
                      border: Border.all(color: t.border),
                      boxShadow: t.cardShadow),
                    child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 22)),
                ),
              ),
              const SizedBox(height: 15),
              Text('Create Account', style: TextStyle(fontSize: 24,
                  fontWeight: FontWeight.bold, color: t.textPrimary)),
              const SizedBox(height: 8),
              Text('Trader Registration', style: TextStyle(fontSize: 16, color: t.textMuted)),
              const SizedBox(height: 40),
              TraderStepperReview(activeStep: 3, theme: t),
              const SizedBox(height: 40),

              // ── Card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
                  boxShadow: t.cardShadow),
                child: Column(children: [
                  Text('Review & Confirm', style: TextStyle(fontSize: 18,
                      color: t.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  _reviewSection(context, t, 'Personal Information',
                    {'Full Name': fullName, 'Phone': phone,
                     'Email': email, 'National ID': nationalId},
                    onEdit: () => Navigator.pop(context)),
                  const SizedBox(height: 16),
                  _reviewSection(context, t, 'Business Details',
                    {'Business Name': businessName, 'Address': address},
                    onEdit: () => Navigator.pop(context)),
                  const SizedBox(height: 30),
                  _createBtn(context),
                ]),
              ),
              const SizedBox(height: 30),
              Text('© 2025 TruckMate',
                  style: TextStyle(color: t.textMuted, fontSize: 14)),
              const SizedBox(height: 10),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _reviewSection(BuildContext context, AppTheme t, String title,
      Map<String, String> data, {required VoidCallback onEdit}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: TextStyle(color: t.textMuted, fontSize: 13,
              fontWeight: FontWeight.w600)),
          GestureDetector(onTap: onEdit,
            child: Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18)),
        ]),
        const SizedBox(height: 12),
        ...data.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Text('${e.key} : ', style: TextStyle(color: t.textMuted, fontSize: 13)),
            Expanded(child: Text(e.value,
                style: TextStyle(color: t.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis)),
          ]),
        )),
      ]),
    );
  }

  Widget _createBtn(BuildContext context) => SizedBox(
    width: double.infinity, height: 55,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF009EA3), AppTheme.primary],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 15, offset: const Offset(0, 5))]),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TraderOtpScreen(
            fullName: fullName, phone: phone, email: email,
            nationalId: nationalId, password: password,
            businessName: businessName, address: address))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        child: const Text('Create Account',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ),
  );
}

class TraderStepperReview extends StatelessWidget {
  final int activeStep;
  final AppTheme theme;
  const TraderStepperReview({super.key, required this.activeStep, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _dot(Icons.person, activeStep >= 1, t),
      _line(activeStep >= 2, t),
      _dot(Icons.business_center_outlined, activeStep >= 2, t),
      _line(activeStep >= 3, t),
      _dot(Icons.check_circle_outline, activeStep >= 3, t),
    ]);
  }

  Widget _dot(IconData icon, bool active, AppTheme t) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? AppTheme.primaryLight.withOpacity(t.isDark ? 0.1 : 0.3) : t.fieldBg,
      border: Border.all(color: active ? AppTheme.primary : t.border, width: 1.5),
      boxShadow: active ? [BoxShadow(color: AppTheme.primary.withOpacity(0.25),
          blurRadius: 10, spreadRadius: 1)] : null),
    child: Icon(icon, color: active ? AppTheme.primary : t.textMuted, size: 24),
  );

  Widget _line(bool active, AppTheme t) => Container(
    width: 45, height: 1.5,
    color: active ? AppTheme.primary : t.border);
}
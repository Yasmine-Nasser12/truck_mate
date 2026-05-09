import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/user_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/theme_provider.dart';

import 'splash_screen.dart';
import 'onboarding_screen.dart';

import 'screen/auth/login_screen.dart';
import 'screen/auth/Registration_Screen.dart';
import 'screen/auth/select_role.dart';
import 'screen/auth/driver_reset_password.dart';

import 'screen/driver/driver_otp_screen.dart';
import 'screen/driver/driver_otp_screen_v2.dart';
import 'screen/driver/driver_otp_screen4.dart';
import 'screen/driver/driver_otp_screen5.dart';
import 'screen/driver/driver_otp_screen7.dart';
import 'screen/driver/license_details_screen.dart';
import 'screen/driver/vehicle_details_screen.dart';
import 'screen/driver/driver_home_screen.dart';
import 'screen/driver/trip_assigned_screen.dart';
import 'screen/driver/trip_active_screen.dart';
import 'screen/driver/live_navigation_screen.dart';
import 'screen/driver/trips_screen.dart';
import 'screen/driver/driver_earnings_screen.dart';
import 'screen/driver/driver_profile_screens.dart';

// Driver Trip Screens (Available, Request Details, Accepted, etc.)
import 'screen/driver/driver_trip_screens.dart';

// Driver State Screens (Earnings Empty/Error, Alerts, Logout Dialog)
import 'screen/driver/driver_state_screens.dart';

// NEW — Driver Pickup Flow Screens
import 'screen/driver/driver_pickup_screens.dart';

import 'screen/trader/Trader_registration_screen.dart';
import 'screen/trader/TraderBusiness_Details_Screen.dart';
import 'screen/trader/TraderReviewConfirmScreen.dart';
import 'screen/trader/trader_home_screen.dart';
import 'screen/trader/trader_home_active_screen.dart';
import 'screen/trader/trader_new_shipment_screen.dart';
import 'screen/trader/trader_otp_screen.dart';
import 'screen/trader/trader_rating_screen.dart';
import 'screen/trader/trader_shipment_scheduled.dart';
import 'screen/trader/trader_notifications_screen.dart';
import 'screen/trader/trader_profile_screens.dart';
import 'screen/trader/trader_settings_screens.dart';
import 'screen/trader/trader_driver_screens.dart';
import 'screen/trader/payment_screens.dart';
import 'screen/trader/trader_state_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => DriverProvider()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TruckMate',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/splash',
      routes: {
        // ── Core ──
        '/splash':                    (_) => const SplashScreen(),
        '/onboarding':                (_) => const OnboardingScreen(),
        '/select_role':               (_) => const SelectRole(),

        // ── Auth ──
        '/login':                     (_) => const LoginScreen(),
        '/signup':                    (_) => const RegistrationScreen(),
        '/driver_reset_password':     (_) => const DriverResetPassword(),

        // ── Driver OTP ──
        '/driver_otp_v2':             (_) => const DriverOtpScreenV2(),
        '/driver_otp_basic':          (_) => const DriverOtpScreen(),
        '/driver_otp_4':              (_) => const DriverOtpScreen4(),
        '/driver_otp_5':              (_) => const DriverOTPScreen5(),
        '/driver_otp_7':              (_) => const DriverOTPScreen7(),

        // ── Driver Registration ──
        '/license_details':           (_) => const LicenseDetailsScreen(),
        '/vehicle_details':           (_) => const VehicleDetailsScreen(),

        // ── Driver Home ──
        '/driver_home':               (_) => const DriverHomeScreen(),
        '/trip_assigned':             (_) => const TripAssignedScreen(),
        '/trip_active':               (_) => const TripActiveScreen(),
        '/live_navigation':           (_) => const LiveNavigationScreen(),
        '/trips':                     (_) => const TripsScreen(),
        '/available_trips':           (_) => const AvailableTripsScreen(),
        '/driver_earnings':           (_) => const DriverEarningsScreen(),
        '/driver_earnings_history':   (_) => const DriverEarningsHistoryScreen(),
        '/driver_earnings_breakdown': (_) => const DriverEarningsBreakdownScreen(),

        // ── Driver Profile ──
        '/driver_profile':            (_) => const DriverProfileScreen(),
        '/driver_settings':           (_) => const DriverSettingsScreen(),
        '/reviews_ratings':           (_) => const ReviewsRatingsScreen(),
        '/advanced_settings':         (_) => const AdvancedSettingsScreen(),
        '/driver_notifications':      (_) => const DriverNotificationsScreen(),
        '/notification_preferences':  (_) => const NotificationPreferencesScreen(),

        // ── Driver Trip State Screens ──
        '/finding_shipments':         (_) => const FindingShipmentsScreen(),
        '/no_requests':               (_) => const NoRequestsScreen(),
        '/request_expired':           (_) => const RequestExpiredScreen(),
        '/connection_lost':           (_) => const ConnectionLostScreen(),
        '/failed_to_load':            (_) => const FailedToLoadScreen(),

        // ── Driver State Screens ──
        '/earnings_empty':            (_) => const DriverEarningsEmptyScreen(),
        '/earnings_error':            (_) => const DriverEarningsErrorScreen(),
        '/earnings_loading':          (_) => const DriverEarningsLoadingScreen(),
        '/alerts_empty':              (_) => const DriverAlertsEmptyScreen(),
        '/alerts_error':              (_) => const DriverAlertsErrorScreen(),
        '/alerts_loading':            (_) => const DriverAlertsLoadingScreen(),

        // ── NEW: Driver Pickup Flow ──
        '/heading_to_pickup':         (_) => const PickupScreen(),
        '/arrived_at_pickup':         (_) => const ArrivedAtPickupScreen(),
        '/pickup_confirmed':          (_) => const PickupConfirmationScreen(),
        '/in_transit':                (_) => const InTransitScreen(),
        '/delivery_success':          (_) => const DeliverySuccessScreen(),

        // ── Trader Registration ──
        '/trader_registration':       (_) => const TraderRegistrationScreen(),
        '/trader_business_details':   (_) => const TraderBusinessDetailsScreen(),
        '/trader_review_confirm':     (_) => const TraderReviewConfirmScreen(),
        '/trader_otp':                (_) => const TraderOtpScreen(),

        // ── Trader Home ──
        '/trader_home':               (_) => const TraderHomeScreen(),
        '/trader_home_active':        (_) => const TraderHomeActiveScreen(),
        '/trader_new_shipment':       (_) => const TraderNewShipmentScreen(),

        // ── Trader Rating ──
        '/rate_driver':               (_) => const RateDriverScreen(),
        '/write_review':              (_) => const WriteReviewScreen(),
        '/review_submitted':          (_) => const ReviewSubmittedScreen(),
        '/reviews_list':              (_) => const ReviewsListScreen(),

        // ── Trader Notifications ──
        '/trader_notifications':      (_) => const TraderNotificationsScreen(),

        // ── Trader Profile ──
        '/trader_profile':            (_) => const TraderProfileScreen(),
        '/trader_details':            (_) => const TraderDetailsScreen(),

        // ── Trader Settings ──
        '/trader_advanced_settings':  (_) => const TraderAdvancedSettingsScreen(),
        '/trader_notif_preferences':  (_) => const TraderNotifPreferencesScreen(),

        // ── Trader Driver & Shipment ──
        '/suggested_drivers':         (_) => const SuggestedDriversScreen(),
        '/no_drivers':                (_) => const NoDriversScreen(),
        '/drivers_loading':           (_) => const DriversLoadingScreen(),
        '/drivers_error':             (_) => const DriversErrorScreen(),
        '/driver_offers':             (_) => const DriverOffersScreen(),
        '/shipment_details':          (_) => const ShipmentDetailsScreen(),

        // ── Payment ──
        '/payment_processing':        (_) => const PaymentProcessingScreen(),
        '/payment_success_simple':    (_) => const PaymentSuccessSimpleScreen(),
        '/payment_success':           (_) => const PaymentSuccessScreen(),
        '/payment_failed':            (_) => const PaymentFailedScreen(),
        '/payment_methods':           (_) => const PaymentMethodsListScreen(),
        '/payment_methods_select':    (_) => const PaymentMethodsSelectScreen(),
        '/add_card':                  (_) => const AddCardScreen(),

        // ── State Screens ──
        '/shipments_state':           (_) => const ShipmentsStateScreen(),
        '/notifications_state':       (_) => const NotificationsStateScreen(),
        '/offers_state':              (_) => const OffersStateScreen(),
        '/payment_state':             (_) => const PaymentStateScreen(),
      },

      onGenerateRoute: (settings) {
        // TripAvailableScreen — needs TripData object
        if (settings.name == '/trip_available') {
          final trip = settings.arguments as TripData?;
          return MaterialPageRoute(
              builder: (_) => TripAvailableScreen(trip: trip ?? _kDummy));
        }

        // RequestDetailsScreen — needs TripData object
        if (settings.name == '/request_details') {
          final trip = settings.arguments as TripData?;
          return MaterialPageRoute(
              builder: (_) => RequestDetailsScreen(trip: trip ?? _kDummy));
        }

        // RequestAcceptedScreen — needs TripData object
        if (settings.name == '/request_accepted') {
          final trip = settings.arguments as TripData?;
          return MaterialPageRoute(
              builder: (_) => RequestAcceptedScreen(trip: trip ?? _kDummy));
        }

        // TraderShipmentScheduled
        if (settings.name == '/trader_shipment_scheduled') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => TraderShipmentScheduled(
                pickup:   args['pickup']   ?? '',
                dropoff:  args['dropoff']  ?? '',
                date:     args['date']     ?? '',
                time:     args['time']     ?? '',
                packages: args['packages'] ?? '',
                weight:   args['weight']   ?? '',
              ));
        }

        // ShipmentDetailsScreen with args
        if (settings.name == '/shipment_details_args') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
              builder: (_) => ShipmentDetailsScreen(
                shipmentId: args['shipmentId'] ?? 'TM-000000',
                pickup:     args['pickup']     ?? 'Not set',
                dropoff:    args['dropoff']    ?? 'Not set',
                date:       args['date']       ?? '-',
                time:       args['time']       ?? '-',
                packages:   args['packages']   ?? '0',
                weight:     args['weight']     ?? '0',
              ));
        }

        return null;
      },
    );
  }
}

// Fallback dummy trip used when navigating without arguments
const _kDummy = TripData(
  id: 'REQ-0000',
  pickup: 'Cairo Distribution Hub',
  dropoff: 'Alexandria Port Terminal',
  distance: '120 km',
  estTime: '2 hr 30 min',
  cargoType: 'General Cargo',
  trader: 'TruckMate Trader',
  price: 240,
);
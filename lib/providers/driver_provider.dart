import 'package:flutter/material.dart';
import '/models/driver_models.dart';

class DriverProvider with ChangeNotifier {
  // ── Online State ──
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // ── Active Trip ──
  AvailableTrip? _activeTrip;
  AvailableTrip? get activeTrip => _activeTrip;
  bool get hasActiveTrip => _activeTrip != null;

  // ── Daily Stats ──
  DailyStats _todayStats = const DailyStats(
    tripsCompleted: 0,
    earnings: 0.0,
    onlineTime: '0h 0m',
  );
  DailyStats get todayStats => _todayStats;

  // ── Available Trips (من الـ Traders) ──
  final List<AvailableTrip> _availableTrips = [
    AvailableTrip(
      id: 'SHP-5001',
      traderName: 'Mohamed El-Sayed',
      traderRating: '4.9',
      origin: 'Maadi Distribution Center',
      destination: 'New Cairo Tech Hub',
      distance: '18.4 km',
      estimatedTime: '35 min',
      price: 320.0,
      goodsType: 'Electronics – Fragile',
      weightTons: 1.2,
      isFragile: true,
      isRefrigerated: false,
      scheduledDate: '2026-03-11',
      scheduledTime: '10:00',
    ),
    AvailableTrip(
      id: 'SHP-5002',
      traderName: 'Sara Hossam',
      traderRating: '4.7',
      origin: 'Nasr City Hub',
      destination: 'Heliopolis Plaza',
      distance: '8.2 km',
      estimatedTime: '20 min',
      price: 185.0,
      goodsType: 'Food & Beverages',
      weightTons: 0.8,
      isFragile: false,
      isRefrigerated: true,
      scheduledDate: '2026-03-11',
      scheduledTime: '11:30',
    ),
    AvailableTrip(
      id: 'SHP-5003',
      traderName: 'Ahmed Farouk',
      traderRating: '4.5',
      origin: 'Zamalek Station',
      destination: '6th of October Terminal',
      distance: '32.7 km',
      estimatedTime: '55 min',
      price: 490.0,
      goodsType: 'Construction Materials',
      weightTons: 5.0,
      isFragile: false,
      isRefrigerated: false,
      scheduledDate: '2026-03-11',
      scheduledTime: '09:00',
    ),
    AvailableTrip(
      id: 'SHP-5004',
      traderName: 'Nour Khaled',
      traderRating: '4.8',
      origin: 'Dokki Warehouse',
      destination: 'Mohandessin Center',
      distance: '4.1 km',
      estimatedTime: '12 min',
      price: 140.0,
      goodsType: 'Medical Supplies',
      weightTons: 0.3,
      isFragile: true,
      isRefrigerated: true,
      scheduledDate: '2026-03-11',
      scheduledTime: '14:00',
    ),
    AvailableTrip(
      id: 'SHP-5005',
      traderName: 'Karim Mostafa',
      traderRating: '4.6',
      origin: 'Shubra Depot',
      destination: 'Downtown Cairo',
      distance: '11.5 km',
      estimatedTime: '28 min',
      price: 255.0,
      goodsType: 'Furniture',
      weightTons: 2.1,
      isFragile: false,
      isRefrigerated: false,
      scheduledDate: '2026-03-11',
      scheduledTime: '13:00',
    ),
  ];

  List<AvailableTrip> get availableTrips =>
      _availableTrips.where((t) => t.status == TripStatus.available).toList();

  // ── Recent Trips ──
  final List<CompletedTrip> _recentTrips = [
    const CompletedTrip(
      id: 'SHP-4519',
      date: 'Jan 30, 2026',
      time: '2:30 PM',
      origin: 'Nasr City Hub',
      destination: 'Heliopolis Plaza',
      earnings: 185.0,
      miles: 8,
      status: TripStatus.completed,
    ),
    const CompletedTrip(
      id: 'SHP-4518',
      date: 'Jan 30, 2026',
      time: '11:15 AM',
      origin: 'Zamalek Station',
      destination: '6th of October Terminal',
      earnings: 490.0,
      miles: 32,
      status: TripStatus.completed,
    ),
    const CompletedTrip(
      id: 'SHP-4517',
      date: 'Jan 29, 2026',
      time: '3:00 PM',
      origin: 'Maadi Center',
      destination: 'New Cairo',
      earnings: 320.0,
      miles: 18,
      status: TripStatus.completed,
    ),
    const CompletedTrip(
      id: 'SHP-4516',
      date: 'Jan 29, 2026',
      time: '9:45 AM',
      origin: 'Dokki Warehouse',
      destination: 'Mohandessin',
      earnings: 140.0,
      miles: 4,
      status: TripStatus.completed,
    ),
  ];

  List<CompletedTrip> get recentTrips => List.unmodifiable(_recentTrips);

  // ── Total Earnings ──
  double get totalEarnings =>
      _recentTrips.fold(0.0, (sum, t) => sum + t.earnings);

  // ── Actions ──

  void toggleOnline() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  void acceptTrip(AvailableTrip trip) {
    // Mark as accepted
    final index = _availableTrips.indexWhere((t) => t.id == trip.id);
    if (index == -1) return;
    _availableTrips[index].status = TripStatus.accepted;
    _activeTrip = _availableTrips[index];
    notifyListeners();
  }

  void rejectTrip(AvailableTrip trip) {
    final index = _availableTrips.indexWhere((t) => t.id == trip.id);
    if (index == -1) return;
    _availableTrips[index].status = TripStatus.cancelled;
    notifyListeners();
  }

  void startTrip() {
    if (_activeTrip == null) return;
    final index = _availableTrips.indexWhere((t) => t.id == _activeTrip!.id);
    if (index != -1) {
      _availableTrips[index].status = TripStatus.inProgress;
      _activeTrip = _availableTrips[index];
    }
    notifyListeners();
  }

  void completeTrip() {
    if (_activeTrip == null) return;

    // Add to recent trips
    final trip = _activeTrip!;
    _recentTrips.insert(
      0,
      CompletedTrip(
        id: trip.id,
        date: _todayDate(),
        time: _currentTime(),
        origin: trip.origin,
        destination: trip.destination,
        earnings: trip.price,
        miles: int.tryParse(
                trip.distance.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0,
        status: TripStatus.completed,
      ),
    );

    // Update daily stats
    _todayStats = DailyStats(
      tripsCompleted: _todayStats.tripsCompleted + 1,
      earnings: _todayStats.earnings + trip.price,
      onlineTime: _todayStats.onlineTime,
    );

    // Mark trip as completed
    final index = _availableTrips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _availableTrips[index].status = TripStatus.completed;
    }

    _activeTrip = null;
    notifyListeners();
  }

  // ── Helpers ──
  String _todayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
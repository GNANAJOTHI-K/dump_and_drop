// lib/driver_flow/driver_home_intro_page.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../role_selection_screen.dart';
import 'orders_panel.dart';
import 'inbox_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
// NOTE: removed import of order_in_progress_page.dart — navigation is not handled here anymore.

const Color kPrimaryColor = Color(0xFF446FA8);
const Color kSecondaryColor = Color(0xFF6C63FF);
const Color kBackgroundColor = Color(0xFFF8F9FF);

class DriverHomeIntroPage extends StatefulWidget {
  const DriverHomeIntroPage({super.key});

  @override
  State<DriverHomeIntroPage> createState() => _DriverHomeIntroPageState();
}

class _DriverHomeIntroPageState extends State<DriverHomeIntroPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final MapController _mapController = MapController();
  LatLng? _driverLatLng;
  bool _isOnline = false;
  double _currentZoom = 15.0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverLocationSub;
  String _driverName = 'Driver';
  int _currentPageIndex = 0; // 0 = Home, 1 = Inbox, 2 = History, 3 = Profile

  @override
  void initState() {
    super.initState();
    if (user != null) _listenDriverDoc();
  }

  @override
  void dispose() {
    _driverLocationSub?.cancel();
    super.dispose();
  }

  void _listenDriverDoc() {
    final docRef = FirebaseFirestore.instance.collection('drivers').doc(user!.uid);
    _driverLocationSub = docRef.snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() ?? {};
      final online = (data['online'] ?? false) as bool;

      // Get driver name
      final details = (data['passengerVehicleDetails'] ?? {}) as Map<String, dynamic>;
      final name = (details['fullName'] ?? data['name'] ?? 'Driver') as String;

      if (mounted) {
        setState(() {
          _isOnline = online;
          _driverName = name;
        });
      }

      final GeoPoint? gp = data['location'] as GeoPoint?;
      if (gp != null) _updateDriverLocation(LatLng(gp.latitude, gp.longitude));
    }, onError: (e) {});
  }

  void _updateDriverLocation(LatLng pos) {
    setState(() => _driverLatLng = pos);
    try {
      _mapController.move(pos, _currentZoom);
    } catch (_) {}
  }

  Future<void> _setOnline(bool value) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('drivers').doc(user!.uid).update({"online": value});
    } catch (_) {
      // ignore update errors for now (rules/offline). Still update UI.
    }
    if (!mounted) return;
    setState(() => _isOnline = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? "You are now Online" : "You are now Offline"),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }

  /// Post-claim hook: OrdersPanel will perform the atomic claim transaction,
  /// then call this function. This function MUST NOT attempt to claim the ride
  /// again or perform navigation to OrderInProgressPage (per your request).
  Future<void> _acceptRide(DocumentReference<Map<String, dynamic>> bookingRef) async {
    // Optional place for analytics or logging after a successful claim.
    // Keep this lightweight and avoid re-writing booking.status or doing another transaction.
    try {
      // Example: write a simple analytics doc (non-critical)
      final userId = user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('analytics').add({
          'event': 'ride_claimed',
          'bookingId': bookingRef.id,
          'driverId': userId,
          'ts': FieldValue.serverTimestamp(),
        }).catchError((_) {
          // ignore analytics errors
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride claimed — check your trips list.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      // swallow errors from hook — OrdersPanel already handled claim outcome
    }
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentPageIndex = index;
    });

    // Navigate to different pages
    switch (index) {
      case 1: // Inbox
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InboxPage()),
        );
        break;
      case 2: // History
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryPage()),
        );
        break;
      case 3: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }

    // Reset to home after navigation (so when we come back, home is selected)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _currentPageIndex = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fallbackLatLng = LatLng(12.9716, 77.5946);
    final initialCenter = _driverLatLng ?? fallbackLatLng;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (Reduced height)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Profile Avatar (Smaller)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.person, color: kPrimaryColor, size: 22),
                  ),
                  const SizedBox(width: 10),

                  // Driver Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _driverName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Online Status (Compact)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _isOnline ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isOnline ? "Online" : "Offline",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isOnline ? Colors.green.shade800 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Welcome Message (Compact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kPrimaryColor.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: kPrimaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Account approved. Start accepting trips.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Map Section (Smaller)
            Expanded(
              flex: 4, // Reduced from 5
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: _currentZoom,
                      maxZoom: 19.0,
                      minZoom: 3.0,
                      onPositionChanged: (pos, hasGesture) {
                        final zoomVal = pos.zoom;
                        if (zoomVal != null) _currentZoom = zoomVal;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.dump_and_drop',
                      ),
                      MarkerLayer(
                        markers: _driverLatLng != null
                            ? [
                                Marker(
                                  point: _driverLatLng!,
                                  width: 48,
                                  height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: kPrimaryColor.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1.5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.local_taxi,
                                      color: kPrimaryColor,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ]
                            : [],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Online/Offline Toggle (Compact)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.power_settings_new,
                          color: _isOnline ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Driver Status",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              _isOnline ? "Active" : "Inactive",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isOnline ? Colors.green.shade800 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: _isOnline,
                      onChanged: _setOnline,
                      activeColor: kPrimaryColor,
                      inactiveTrackColor: Colors.grey.shade300,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),

            // Ride Requests Section (More space)
            Expanded(
              flex: 6, // Increased from 5 to give more space for ride cards
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with count
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "🚕 Available Rides",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collectionGroup('bookings')
                              .where('service', isEqualTo: 'ride')
                              .where('status', isEqualTo: 'pending')
                              .snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.docs.length ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$count available",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 8),

                    // Ride requests - Takes most of the space
                    Expanded(
                      child: OrdersPanel(
                        isOnline: _isOnline,
                        onAccept: _acceptRide, // parent hook only; OrdersPanel handles the claim
                      ),
                    ),

                    // Bottom padding
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60, // Slightly smaller nav bar
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentPageIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          iconSize: 22,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: _currentPageIndex == 0
                    ? BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  Icons.home,
                  size: 22,
                  color: _currentPageIndex == 0 ? kPrimaryColor : Colors.grey.shade600,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: _currentPageIndex == 1
                    ? BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  Icons.inbox,
                  size: 22,
                  color: _currentPageIndex == 1 ? kPrimaryColor : Colors.grey.shade600,
                ),
              ),
              label: 'Inbox',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: _currentPageIndex == 2
                    ? BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  Icons.history,
                  size: 22,
                  color: _currentPageIndex == 2 ? kPrimaryColor : Colors.grey.shade600,
                ),
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: _currentPageIndex == 3
                    ? BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Icon(
                  Icons.person,
                  size: 22,
                  color: _currentPageIndex == 3 ? kPrimaryColor : Colors.grey.shade600,
                ),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

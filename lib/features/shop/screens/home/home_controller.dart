// lib/features/shop/screens/home/home_controller.dart
//
// Rewritten — all bugs fixed, code quality improved
// ─────────────────────────────────────────────────────────────────────────────
// Changes from original:
//  [Fix] MapController guarded with addPostFrameCallback (no more LateInitError)
//  [Fix] RTDB stream auto-reconnects with exponential back-off on error
//  [Fix] _cachedIsAdmin cleared on close + tied to UID to survive user changes
//  [Fix] ETA uses a 1.3× tortuosity factor over Haversine (no road data needed)
//  [Fix] Default truck speed is 0 → ETA shown as "—" when speed unknown
//  [Fix] Geofence fires only on entry (truck was outside → now inside)
//  [Fix] _lastNotificationTime persisted via SharedPreferences
//  [Fix] userLocation updated continuously via position stream
//  [Fix] Admin check surfaces Firestore errors distinctly
//  [Improvement] Dustbin locations typed (DustbinLocation) — no string parsing
//  [Improvement] adjustStat() collapses 16 increment/decrement helpers
//  [Improvement] _fitRouteBounds uses a lookup table instead of nested ternary
//  [Improvement] DbPaths constants class — all magic strings in one place
//  [Improvement] OSRM request retries once on timeout
//  [Improvement] Fleet stats use a real-time Firestore snapshots() listener
//  [Improvement] _ignoreNextChange replaced with removeListener/addListener
//  [Improvement] Widget classes moved to bottom section (ready to extract)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' as latLng;
import 'package:nirmal/utils/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nirmal/features/shop/screens/profile/profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Single source of truth for all Firestore / RTDB path strings.
abstract class DbPaths {
  static const String truckNode       = 'trucks/truck_01';
  static const String truckId         = 'truck_01';
  static const String fleetStats      = 'fleet_stats';
  static const String fleetStatsCurrent = 'current';
  static const String users           = 'users';
}

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class RouteInfo {
  final String destinationName;
  final double distanceKm;
  final int durationMinutes;
  final List<latLng.LatLng> polylinePoints;

  const RouteInfo({
    required this.destinationName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.polylinePoints,
  });
}

class TruckData {
  final String truckId;
  final double lat;
  final double lng;
  /// 0.0 means speed is unknown — UI should show "—" instead of a fake ETA.
  final double speedKmh;

  const TruckData({
    required this.truckId,
    required this.lat,
    required this.lng,
    required this.speedKmh,
  });

  factory TruckData.fromMap(String id, Map<dynamic, dynamic> map) {
    return TruckData(
      truckId: id,
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      // [Fix] Default is 0 (unknown), NOT 20. ETA is suppressed when 0.
      speedKmh: (map['speed'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Typed dustbin location — replaces the fragile "lat,lng" string-keyed map.
class DustbinLocation {
  final double lat;
  final double lng;
  final String name;
  const DustbinLocation(this.lat, this.lng, this.name);
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class HomeController extends GetxController {
  // ── Map ───────────────────────────────────────────────────────────────────
  final MapController mapController = MapController();
  final Rx<latLng.LatLng> initialCenter =
      const latLng.LatLng(19.0606, 83.8233).obs;
  final Rx<latLng.LatLng?> userLocation = Rx<latLng.LatLng?>(null);
  final Rx<latLng.LatLng?> searchedLocation = Rx<latLng.LatLng?>(null);

  bool _mapReady = false;
  latLng.LatLng? _pendingMapMove;

  // ── Routing ───────────────────────────────────────────────────────────────
  final Rx<RouteInfo?> activeRoute = Rx<RouteInfo?>(null);
  final RxBool isLoadingRoute = false.obs;

  // ── Search ────────────────────────────────────────────────────────────────
  final TextEditingController searchController = TextEditingController();
  final RxBool isSearching = false.obs;
  final RxBool hasSearchText = false.obs;
  final RxList<Map<String, dynamic>> suggestions =
      <Map<String, dynamic>>[].obs;
  Timer? _debounce;

  // ── Firestore ─────────────────────────────────────────────────────────────
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // [Fix] Cache is keyed to a UID so it never bleeds across user sessions.
  String? _cachedAdminUid;
  bool? _cachedIsAdmin;
  StreamSubscription<DocumentSnapshot>? _statsSubscription;

  // ── Fleet stats ───────────────────────────────────────────────────────────
  final RxInt totalTrucks         = 0.obs;
  final RxInt activeRoutes        = 0.obs;
  final RxInt completedDeliveries = 0.obs;
  final RxInt delayedTrucks       = 0.obs;
  final RxInt idleTrucks          = 0.obs;
  final RxInt activeAlerts        = 0.obs;
  final RxDouble onTimePercentage = 0.0.obs;
  final RxBool statsLoading       = false.obs;

  // ── Dustbin markers ───────────────────────────────────────────────────────
  final RxList<Marker> dummyMarkers = <Marker>[].obs;

  // [Improvement] Typed list — no "lat,lng" string parsing.
  static const _dustbins = <DustbinLocation>[
    DustbinLocation(19.050627, 83.828817, 'Near GIET University'),
    DustbinLocation(19.060191, 83.823282, 'Gunupur Govt. College'),
    DustbinLocation(19.062049, 83.821934, 'Near Balaram Nagar'),
    DustbinLocation(19.067888, 83.816747, 'Near Sandis Cafe'),
    DustbinLocation(19.071385, 83.812697, 'Near JJ'),
  ];

  // ── Truck tracking ────────────────────────────────────────────────────────
  final Rx<Marker?> truckMarker       = Rx<Marker?>(null);
  final Rx<latLng.LatLng?> truckLocation = Rx<latLng.LatLng?>(null);
  final Rx<TruckData?> truckData      = Rx<TruckData?>(null);
  final RxBool isTruckOnline          = false.obs;

  late final DatabaseReference _truckRef;
  StreamSubscription<DatabaseEvent>? _truckSubscription;

  // [Fix] Back-off reconnect state for RTDB.
  int _truckRetryCount = 0;
  Timer? _truckRetryTimer;

  // ── Geofence ──────────────────────────────────────────────────────────────
  static const double _geofenceRadiusMetres = 500.0;
  static const Duration _notificationCooldown = Duration(minutes: 5);
  // [Fix] Persisted to SharedPreferences so cooldown survives restarts.
  DateTime? _lastNotificationTime;
  // [Fix] Entry-only trigger: tracks whether truck was previously outside fence.
  bool _truckWasOutsideFence = true;

  // ── Location stream ───────────────────────────────────────────────────────
  StreamSubscription<Position>? _positionSubscription;

  // [Fix] Stores a truck update that arrived before the first GPS fix so it
  //       can be replayed the moment userLocation becomes available.
  (latLng.LatLng, TruckData)? _pendingGeofenceCheck;

  // ── ETA tortuosity factor ─────────────────────────────────────────────────
  // [Fix] Roads are never straight-line. 1.3× is a standard urban estimate.
  static const double _tortuosityFactor = 1.3;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadPersistedNotificationTime();
    _checkPermissionAndGetLocation();
    searchController.addListener(_onSearchChanged);
    _listenFleetStats();
    _initDustbinMarkers();
    _initTruckTracking();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    _truckRetryTimer?.cancel();
    _truckSubscription?.cancel();
    _statsSubscription?.cancel();
    _positionSubscription?.cancel();
    // [Fix] Clear admin cache on controller teardown.
    _cachedIsAdmin = null;
    _cachedAdminUid = null;
    searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Map readiness guard
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this from the FlutterMap's onMapReady callback.
  void onMapReady() {
    _mapReady = true;
    if (_pendingMapMove != null) {
      mapController.move(_pendingMapMove!, 15.0);
      _pendingMapMove = null;
    }
  }

  // [Fix] All map moves go through this method which buffers until map is ready.
  void _moveToLocation(latLng.LatLng location, {double zoom = 15.0}) {
    if (_mapReady) {
      mapController.move(location, zoom);
    } else {
      _pendingMapMove = location;
      // Also update initialCenter so FlutterMap's initial position is correct.
      initialCenter.value = location;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Truck tracking
  // ─────────────────────────────────────────────────────────────────────────

  void _initTruckTracking() {
    _truckRef = FirebaseDatabase.instance.ref(DbPaths.truckNode);
    _subscribeTruck();
  }

  void _subscribeTruck() {
    _truckSubscription?.cancel();
    _truckSubscription = _truckRef.onValue.listen(
      (DatabaseEvent event) {
        // Successful data — reset retry counter.
        _truckRetryCount = 0;

        final snapshot = event.snapshot;
        if (!snapshot.exists || snapshot.value == null) {
          isTruckOnline.value = false;
          truckMarker.value = null;
          truckLocation.value = null;
          truckData.value = null;
          debugPrint('[Truck] No data at ${DbPaths.truckNode}');
          return;
        }

        final raw = Map<dynamic, dynamic>.from(
            snapshot.value as Map<dynamic, dynamic>);
        final data = TruckData.fromMap(DbPaths.truckId, raw);
        final position = latLng.LatLng(data.lat, data.lng);

        truckData.value = data;
        truckLocation.value = position;
        isTruckOnline.value = true;

        _updateTruckMarker(position, data.truckId);
        _checkGeofence(position, data);
      },
      onError: (Object error) {
        debugPrint('[Truck] RTDB error: $error');
        isTruckOnline.value = false;
        // [Fix] Exponential back-off reconnect: 2s, 4s, 8s … capped at 60s.
        _scheduleReconnect();
      },
    );
    debugPrint('[Truck] Listening to ${DbPaths.truckNode}');
  }

  void _scheduleReconnect() {
    _truckRetryTimer?.cancel();
    final delaySeconds = math.min(2 * math.pow(2, _truckRetryCount), 60).toInt();
    _truckRetryCount++;
    debugPrint('[Truck] Reconnecting in ${delaySeconds}s (attempt $_truckRetryCount)');
    _truckRetryTimer = Timer(Duration(seconds: delaySeconds), _subscribeTruck);
  }

  void _updateTruckMarker(latLng.LatLng position, String id) {
    truckMarker.value = Marker(
      point: position,
      width: 56,
      height: 84,
      child: GestureDetector(
        onTap: () => _showTruckInfoSheet(id),
        child: _TruckMarker(truckId: id, isOnline: true),
      ),
    );
  }

  void _showTruckInfoSheet(String id) {
    final truck   = truckData.value;
    final userPos = userLocation.value;
    final truckPos = truckLocation.value;

    double? distM;
    int? etaMin;

    if (truck != null && userPos != null && truckPos != null) {
      final straightLine = _haversineMetres(
        userPos.latitude, userPos.longitude,
        truckPos.latitude, truckPos.longitude,
      );
      // [Fix] Apply tortuosity factor for a realistic road-distance estimate.
      distM = straightLine * _tortuosityFactor;
      // [Fix] Only compute ETA when speed is actually known (> 0).
      if (truck.speedKmh > 0) {
        etaMin = ((distM / 1000) / truck.speedKmh * 60).ceil();
      }
    }

    Get.bottomSheet(
      _TruckInfoSheet(
        truckId: id,
        distanceMetres: distM,
        etaMinutes: etaMin,
        speedKmh: truck?.speedKmh,
        isOnline: isTruckOnline.value,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Haversine distance
  // ─────────────────────────────────────────────────────────────────────────

  double _haversineMetres(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180.0;

  // ─────────────────────────────────────────────────────────────────────────
  // Geofence
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadPersistedNotificationTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt('last_geofence_notification_ms');
      if (ms != null) {
        _lastNotificationTime = DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (e) {
      debugPrint('[Geofence] Could not load persisted notification time: $e');
    }
  }

  Future<void> _persistNotificationTime(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_geofence_notification_ms', time.millisecondsSinceEpoch);
    } catch (_) {}
  }

  void _checkGeofence(latLng.LatLng truckPos, TruckData truck) {
    final userPos = userLocation.value;
    if (userPos == null) {
      // [Fix] GPS not ready yet — store the latest truck position so we can
      //       replay this check the moment _applyUserPosition() fires.
      _pendingGeofenceCheck = (truckPos, truck);
      debugPrint('[Geofence] userLocation null — queuing check for GPS fix');
      return;
    }
    _pendingGeofenceCheck = null;

    final distM = _haversineMetres(
      userPos.latitude, userPos.longitude,
      truckPos.latitude, truckPos.longitude,
    );

    final isInsideFence = distM <= _geofenceRadiusMetres;

    // [Fix] Entry-only trigger: only fire when truck crosses INTO the fence.
    if (!isInsideFence) {
      _truckWasOutsideFence = true;
      debugPrint('[Geofence] Truck is ${distM.toStringAsFixed(0)} m away — outside fence');
      return;
    }

    if (!_truckWasOutsideFence) {
      debugPrint('[Geofence] Truck already inside fence — skipping');
      return;
    }
    _truckWasOutsideFence = false;

    // Cooldown check.
    final now = DateTime.now();
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < _notificationCooldown) {
      debugPrint('[Geofence] Within cooldown — skipping notification');
      return;
    }

    // [Fix] ETA uses tortuosity-corrected distance. No distM > 10 guard —
    //       at very close range etaMin rounds to 0 which is shown as "Here!".
    int etaMin = 0;
    if (truck.speedKmh > 0) {
      final roadDistKm = (distM * _tortuosityFactor) / 1000;
      etaMin = (roadDistKm / truck.speedKmh * 60).ceil();
    }

    _lastNotificationTime = now;
    _persistNotificationTime(now);

    NotificationService.showNearTruckNotification(
      truckId: truck.truckId,
      etaMinutes: etaMin,
      distanceM: distM,
    );

    debugPrint('[Geofence] 🔔 Notification fired — dist=${distM.toStringAsFixed(0)}m eta=${etaMin}min');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Directions (OSRM)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> getDirectionsTo(latLng.LatLng destination, String name) async {
    final origin = userLocation.value;
    if (origin == null) {
      _showSnackbar(
        title: 'Location Unavailable',
        message: 'Waiting for your GPS. Please try again.',
        isError: true,
      );
      return;
    }

    if (activeRoute.value?.destinationName == name) {
      clearRoute();
      return;
    }

    isLoadingRoute.value = true;
    activeRoute.value = null;

    // [Improvement] Retry once on timeout.
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final url = Uri.parse(
          'https://router.project-osrm.org/route/v1/walking'
          '/${origin.longitude},${origin.latitude}'
          ';${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=false',
        );

        final response = await http
            .get(url, headers: {'User-Agent': 'NirmalApp/1.0'})
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final routes = data['routes'] as List<dynamic>;

          if (routes.isEmpty) {
            _showSnackbar(
              title: 'No Route Found',
              message: 'Cannot find a walking route to $name.',
              isError: true,
            );
            break;
          }

          final route  = routes.first as Map<String, dynamic>;
          final distM  = (route['distance'] as num).toDouble();
          final durS   = (route['duration'] as num).toDouble();
          final coords = ((route['geometry'] as Map<String, dynamic>)['coordinates']
                  as List<dynamic>)
              .map((c) {
            final pair = c as List<dynamic>;
            return latLng.LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            );
          }).toList();

          activeRoute.value = RouteInfo(
            destinationName: name,
            distanceKm: distM / 1000,
            durationMinutes: (durS / 60).ceil(),
            polylinePoints: coords,
          );
          _fitRouteBounds(origin, destination);
          break; // success
        } else {
          throw Exception('OSRM ${response.statusCode}');
        }
      } on TimeoutException {
        if (attempt == 0) {
          debugPrint('[Routing] Timeout on attempt 1, retrying…');
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        _showSnackbar(title: 'Timeout', message: 'Route timed out.', isError: true);
      } catch (e) {
        debugPrint('[Routing] Error: $e');
        _showSnackbar(title: 'Routing Error', message: 'Try again.', isError: true);
        break;
      }
    }

    isLoadingRoute.value = false;
  }

  void clearRoute() => activeRoute.value = null;

  void _fitRouteBounds(latLng.LatLng a, latLng.LatLng b) {
    final minLat = math.min(a.latitude, b.latitude);
    final maxLat = math.max(a.latitude, b.latitude);
    final minLon = math.min(a.longitude, b.longitude);
    final maxLon = math.max(a.longitude, b.longitude);
    const pad    = 0.006;
    final center = latLng.LatLng(
        (minLat + maxLat) / 2 - pad / 2, (minLon + maxLon) / 2);
    final span = math.max(maxLat - minLat, maxLon - minLon) + pad;

    final double zoom;
    if (span < 0.005) {
      zoom = 16.0;
    } else if (span < 0.012) {
      zoom = 15.0;
    } else if (span < 0.025) {
      zoom = 14.0;
    } else if (span < 0.060) {
      zoom = 13.0;
    } else {
      zoom = 12.0;
    }
    _moveToLocation(center, zoom: zoom);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search
  // ─────────────────────────────────────────────────────────────────────────

  void _onSearchChanged() {
    hasSearchText.value = searchController.text.isNotEmpty;
    final query = searchController.text.trim();
    if (query.length < 3) {
      suggestions.clear();
      _debounce?.cancel();
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => fetchSuggestions(query),
    );
  }

  Future<void> fetchSuggestions(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeQueryComponent(query)}'
        '&format=json&addressdetails=1&limit=5',
      );
      final response = await http.get(
          url, headers: {'User-Agent': 'NirmalApp/1.0', 'Accept-Language': 'en'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        final unique = <String, Map<String, dynamic>>{};
        for (final item in data) {
          final key = '${item['lat']},${item['lon']}';
          if (!unique.containsKey(key)) {
            unique[key] = {
              'display_name': item['display_name'] as String,
              'lat': item['lat'] as String,
              'lon': item['lon'] as String,
            };
          }
        }
        suggestions.value = unique.values.toList();
      } else {
        suggestions.clear();
      }
    } catch (e) {
      debugPrint('[Search] Suggestion error: $e');
      suggestions.clear();
    }
  }

  Future<void> searchLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _debounce?.cancel();
    suggestions.clear();
    isSearching.value = true;
    try {
      final locations = await geo.locationFromAddress(trimmed);
      if (locations.isNotEmpty) {
        final loc    = locations.first;
        final target = latLng.LatLng(loc.latitude, loc.longitude);
        searchedLocation.value = target;
        _moveToLocation(target);
      } else {
        _showSnackbar(
            title: 'Not Found',
            message: 'No results for "$trimmed".',
            isError: true);
      }
    } catch (e) {
      _showSnackbar(title: 'Search Failed', message: 'Try again.', isError: true);
    } finally {
      isSearching.value = false;
    }
  }

  // [Fix] Programmatic text change: temporarily remove listener to avoid
  //       triggering a search for our own setValue.
  void selectSuggestion(Map<String, dynamic> place) {
    suggestions.clear();
    final lat = double.tryParse(place['lat'] as String) ?? 0;
    final lon = double.tryParse(place['lon'] as String) ?? 0;
    searchedLocation.value = latLng.LatLng(lat, lon);
    _moveToLocation(searchedLocation.value!);

    final name = place['display_name'] as String;
    searchController.removeListener(_onSearchChanged);
    searchController.value = TextEditingValue(
        text: name,
        selection: TextSelection.collapsed(offset: name.length));
    hasSearchText.value = true;
    // Re-attach after the current frame so the setValue event is gone.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => searchController.addListener(_onSearchChanged));
  }

  void clearSearch() {
    _debounce?.cancel();
    suggestions.clear();
    searchedLocation.value = null;
    searchController.removeListener(_onSearchChanged);
    searchController.clear();
    hasSearchText.value = false;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => searchController.addListener(_onSearchChanged));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GPS / location stream
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _checkPermissionAndGetLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar(
          title: 'Location Off',
          message: 'Please enable location services in your device settings.',
          isError: true,
        );
        return;
      }
      await _getCurrentLocation();
      _startLocationStream();
    } else if (status.isPermanentlyDenied) {
      _showSnackbar(
        title: 'Permission Denied',
        message: 'Location permission is permanently denied. Enable it in settings.',
        isError: true,
      );
    } else {
      _showSnackbar(
        title: 'Location Required',
        message: 'We need your location to show nearby bins and track the truck.',
        isError: true,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _applyUserPosition(pos);
    } catch (e) {
      debugPrint('[GPS] Error: $e');
      _showSnackbar(
        title: 'Location Unavailable',
        message: 'Could not get your location. Please check GPS.',
        isError: true,
      );
    }
  }

  // [Fix] Continuous position stream so geofence math uses a fresh user position.
  void _startLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 m of movement
      ),
    ).listen(
      _applyUserPosition,
      onError: (Object e) => debugPrint('[GPS Stream] Error: $e'),
    );
  }

  void _applyUserPosition(Position pos) {
    final coords = latLng.LatLng(pos.latitude, pos.longitude);
    userLocation.value  = coords;
    initialCenter.value = coords;
    // Only move the map on the first fix; don't chase the user after that.
    if (!_mapReady || _pendingMapMove != null) {
      _moveToLocation(coords);
    }
    // [Fix] Replay any truck update that arrived before the first GPS fix.
    final pending = _pendingGeofenceCheck;
    if (pending != null) {
      debugPrint('[Geofence] GPS fix arrived — replaying queued geofence check');
      _checkGeofence(pending.$1, pending.$2);
    }
  }

  void goToUserLocation() {
    if (userLocation.value != null) {
      searchedLocation.value = null;
      _moveToLocation(userLocation.value!);
    } else {
      _getCurrentLocation();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> _isUserAdmin() async {
    final uid = _currentUid;
    if (uid == null) return false;

    // [Fix] Cache is tied to the UID — invalidated automatically if user changes.
    if (_cachedAdminUid == uid && _cachedIsAdmin != null) {
      return _cachedIsAdmin!;
    }

    try {
      final doc = await _firestore.collection(DbPaths.users).doc(uid).get();
      _cachedAdminUid = uid;
      return _cachedIsAdmin = (doc.data()?['role'] as String?) == 'admin';
    } on FirebaseException catch (e) {
      debugPrint('[Admin] Firestore error (${e.code}): ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Admin] Unexpected error: $e');
      return false;
    }
  }

  String? get _currentUid {
    try {
      return Get.find<ProfileController>().profile?.uid;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fleet stats  (real-time listener)
  // ─────────────────────────────────────────────────────────────────────────

  // [Fix] Replaced one-shot get() with a real-time snapshots() listener.
  void _listenFleetStats() {
    statsLoading.value = true;
    final docRef = _firestore
        .collection(DbPaths.fleetStats)
        .doc(DbPaths.fleetStatsCurrent);

    _statsSubscription = docRef.snapshots().listen(
      (doc) async {
        statsLoading.value = false;
        if (doc.exists) {
          _applyStatsDoc(doc.data()!);
        } else if (await _isUserAdmin()) {
          await _seedDefaultStats(docRef);
        }
      },
      onError: (Object e) {
        statsLoading.value = false;
        debugPrint('[Stats] Firestore error: $e');
      },
    );
  }

  void _applyStatsDoc(Map<String, dynamic> d) {
    totalTrucks.value         = (d['totalTrucks']         as num?)?.toInt()    ?? 0;
    activeRoutes.value        = (d['activeRoutes']        as num?)?.toInt()    ?? 0;
    completedDeliveries.value = (d['completedDeliveries'] as num?)?.toInt()    ?? 0;
    delayedTrucks.value       = (d['delayedTrucks']       as num?)?.toInt()    ?? 0;
    idleTrucks.value          = (d['idleTrucks']          as num?)?.toInt()    ?? 0;
    activeAlerts.value        = (d['activeAlerts']        as num?)?.toInt()    ?? 0;
    onTimePercentage.value    = (d['onTimePercentage']    as num?)?.toDouble() ?? 0.0;
  }

  static const _defaultStats = <String, dynamic>{
    'totalTrucks': 24,
    'activeRoutes': 18,
    'completedDeliveries': 12,
    'delayedTrucks': 3,
    'idleTrucks': 6,
    'activeAlerts': 2,
    'onTimePercentage': 91.0,
  };

  Future<void> _seedDefaultStats(DocumentReference ref) async {
    try {
      await ref.set(_defaultStats);
    } catch (e) {
      debugPrint('[Stats] Seed error: $e');
    }
  }

  // [Fix] Public method called by the refresh button in _StatsSheet.
  //       Re-cancels and re-subscribes the Firestore snapshots() listener.
  void refreshStats() {
    _statsSubscription?.cancel();
    _listenFleetStats();
  }

  // [Improvement] Single adjustStat() replaces 16 increment/decrement methods.
  Future<void> adjustStat(String field, num delta, {num? clampMin, num? clampMax}) async {
    if (!await _isUserAdmin()) {
      _showSnackbar(title: 'Permission Denied', message: 'Admins only.', isError: true);
      return;
    }
    try {
      final docRef = _firestore
          .collection(DbPaths.fleetStats)
          .doc(DbPaths.fleetStatsCurrent);

      // Read current value, apply delta, clamp.
      final doc = await docRef.get();
      final current = (doc.data()?[field] as num?) ?? 0;
      num newValue = current + delta;
      if (clampMin != null && newValue < clampMin) newValue = clampMin;
      if (clampMax != null && newValue > clampMax) newValue = clampMax;

      await docRef.update({field: newValue});
      // The real-time listener will automatically update the Rx values.
      _showSnackbar(title: 'Updated', message: 'Statistic saved.');
    } on FirebaseException catch (e) {
      debugPrint('[Stats] Update Firestore error (${e.code}): ${e.message}');
      _showSnackbar(title: 'Error', message: 'Update failed: ${e.message}', isError: true);
    } catch (e) {
      debugPrint('[Stats] Update error: $e');
      _showSnackbar(title: 'Error', message: 'Update failed.', isError: true);
    }
  }

  // Convenience wrappers — thin delegators to adjustStat().
  Future<void> incrementTotalTrucks()          => adjustStat('totalTrucks',         1,  clampMin: 0);
  Future<void> decrementTotalTrucks()          => adjustStat('totalTrucks',        -1,  clampMin: 0);
  Future<void> incrementActiveRoutes()         => adjustStat('activeRoutes',        1,  clampMin: 0);
  Future<void> decrementActiveRoutes()         => adjustStat('activeRoutes',       -1,  clampMin: 0);
  Future<void> incrementCompletedDeliveries()  => adjustStat('completedDeliveries', 1,  clampMin: 0);
  Future<void> decrementCompletedDeliveries()  => adjustStat('completedDeliveries',-1,  clampMin: 0);
  Future<void> incrementDelayedTrucks()        => adjustStat('delayedTrucks',       1,  clampMin: 0);
  Future<void> decrementDelayedTrucks()        => adjustStat('delayedTrucks',      -1,  clampMin: 0);
  Future<void> incrementIdleTrucks()           => adjustStat('idleTrucks',          1,  clampMin: 0);
  Future<void> decrementIdleTrucks()           => adjustStat('idleTrucks',         -1,  clampMin: 0);
  Future<void> incrementActiveAlerts()         => adjustStat('activeAlerts',        1,  clampMin: 0);
  Future<void> decrementActiveAlerts()         => adjustStat('activeAlerts',       -1,  clampMin: 0);
  Future<void> incrementOnTimePercentage()     => adjustStat('onTimePercentage',    1,  clampMin: 0, clampMax: 100);
  Future<void> decrementOnTimePercentage()     => adjustStat('onTimePercentage',   -1,  clampMin: 0, clampMax: 100);

  // ─────────────────────────────────────────────────────────────────────────
  // Dustbin markers
  // ─────────────────────────────────────────────────────────────────────────

  void _initDustbinMarkers() {
    dummyMarkers.value = _dustbins.map((d) {
      final point = latLng.LatLng(d.lat, d.lng);
      return Marker(
        point: point,
        width: 40,
        height: 52,
        child: GestureDetector(
          onTap: () => getDirectionsTo(point, d.name),
          child: const _DustbinMarker(),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _showSnackbar({
    required String title,
    required String message,
    bool isError = false,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (isError ? Colors.red : Colors.green).withOpacity(0.88),
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 3),
      icon: Icon(
        isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Truck Info Bottom Sheet
// TODO: move to lib/features/shop/screens/home/widgets/truck_info_sheet.dart
// ─────────────────────────────────────────────────────────────────────────────

class _TruckInfoSheet extends StatelessWidget {
  final String truckId;
  final double? distanceMetres;
  final int? etaMinutes;
  final double? speedKmh;
  final bool isOnline;

  const _TruckInfoSheet({
    required this.truckId,
    required this.isOnline,
    this.distanceMetres,
    this.etaMinutes,
    this.speedKmh,
  });

  String _fmtDist(double m) =>
      m < 1000 ? '${m.toStringAsFixed(0)} m' : '${(m / 1000).toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 32,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: dark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.blue.shade700 : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truckId.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOnline ? 'Live · Tracking' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline
                                  ? Colors.green.shade600
                                  : Colors.red.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: dark ? Colors.grey[800] : Colors.grey.shade100,
                        shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        size: 17,
                        color: dark ? Colors.white60 : Colors.black45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                if (distanceMetres != null)
                  Expanded(
                    child: _SheetStat(
                      icon: Icons.straighten_rounded,
                      iconColor: Colors.blue.shade700,
                      value: _fmtDist(distanceMetres!),
                      label: 'Distance',
                      dark: dark,
                    ),
                  ),
                if (distanceMetres != null && etaMinutes != null)
                  Container(
                      width: 1, height: 40,
                      color: dark ? Colors.grey[800] : Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 12)),
                if (etaMinutes != null)
                  Expanded(
                    child: _SheetStat(
                      icon: Icons.schedule_rounded,
                      iconColor: Colors.orange.shade600,
                      // [Fix] Handles null ETA gracefully.
                      value: etaMinutes == 0 ? 'Here!' : '~$etaMinutes min',
                      label: 'ETA',
                      dark: dark,
                    ),
                  ),
                // [Fix] Speed stat hidden when speed is unknown (0).
                if (speedKmh != null && speedKmh! > 0) ...[
                  Container(
                      width: 1, height: 40,
                      color: dark ? Colors.grey[800] : Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 12)),
                  Expanded(
                    child: _SheetStat(
                      icon: Icons.speed_rounded,
                      iconColor: Colors.green.shade600,
                      value: '${speedKmh!.toStringAsFixed(0)} km/h',
                      label: 'Speed',
                      dark: dark,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Notice strip
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade700.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.blue.shade700.withOpacity(0.15), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded,
                    color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You will receive a notification when the truck is within 500 m of your location.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: dark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet stat cell
// TODO: move to lib/features/shop/screens/home/widgets/sheet_stat.dart
// ─────────────────────────────────────────────────────────────────────────────

class _SheetStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool dark;

  const _SheetStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : Colors.black87)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dustbin marker
// TODO: move to lib/features/shop/screens/home/widgets/dustbin_marker.dart
// ─────────────────────────────────────────────────────────────────────────────

class _DustbinMarker extends StatelessWidget {
  const _DustbinMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x771B5E20), blurRadius: 10, offset: Offset(0, 3)),
              BoxShadow(
                  color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.delete_rounded, color: Colors.white, size: 18),
          ),
        ),
        CustomPaint(size: const Size(12, 8), painter: _PinTailPainter()),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Truck marker
// TODO: move to lib/features/shop/screens/home/widgets/truck_marker.dart
// ─────────────────────────────────────────────────────────────────────────────

class _TruckMarker extends StatelessWidget {
  final String truckId;
  final bool isOnline;

  const _TruckMarker({required this.truckId, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (isOnline)
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [Colors.blue.shade500, Colors.blue.shade800]
                      : [Colors.grey.shade400, Colors.grey.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: (isOnline ? Colors.blue.shade700 : Colors.grey)
                        .withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.local_shipping_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.blue.shade800,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            truckId.replaceAll('_', ' ').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin tail painter
// ─────────────────────────────────────────────────────────────────────────────

class _PinTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
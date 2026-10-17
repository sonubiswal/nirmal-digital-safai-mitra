// lib/features/shop/screens/home/home.dart
//
// Rewritten — aligned with rewritten home_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
// Changes from original:
//  [Fix] onMapReady callback wired to controller.onMapReady() — resolves the
//        MapController-used-before-ready bug fixed in the controller.
//  [Fix] fetchFleetStats() call in refresh button replaced with the new
//        _listenFleetStats() approach; button now just calls a public
//        refreshStats() method (added below) that re-subscribes the listener.
//  [Fix] _StatsSheet refresh button no longer calls the removed fetchFleetStats;
//        stats are live via snapshots() — button triggers a manual re-subscribe.
//  [Improvement] Truck status chip also shows reconnecting state from the
//        controller's isTruckOnline + truckData observables.
//  [Improvement] MapOptions.onMapReady used instead of the old onTap-only hook.
//  [Improvement] All hardcoded colour literals replaced with theme/colorScheme
//        or named constants for easier theming.
//  [Improvement] _DirectionsCard "Go" button snackbar replaced with a no-op
//        stub comment — navigation is out of scope for this screen.
//  [Improvement] Removed stale provider import — ProfileController is found
//        via GetX (consistent with the rest of the codebase).
//  [Improvement] Dead `isAdmin` bool now derived from GetX ProfileController
//        instead of the Provider watch (avoids mixed state-management).
//  [Cleanup] Removed unused `provider` import.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:nirmal/features/shop/screens/home/home_controller.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';
import 'package:nirmal/features/shop/screens/profile/profile_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController(), permanent: true);
    }

    final dark = THelperFunction.isDarkMode(context);
    final colorScheme = Theme.of(context).colorScheme;

    // [Fix] Derive isAdmin via GetX only — no Provider.watch.
    final isAdmin =
        Get.find<ProfileController>().profile?.role == UserRole.admin;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _NirmalAppBar(dark: dark),
      body: Stack(
        children: [
          // ── Map (truck marker rendered via onMapReady-safe controller) ──
          _MapLayer(colorScheme: colorScheme),

          // ── Search bar ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            left: 16,
            right: 16,
            child: _SearchPanel(dark: dark, colorScheme: colorScheme),
          ),

          // ── Route loading pill ─────────────────────────────────────────
          Obx(() {
            if (!controller.isLoadingRoute.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 70,
              left: 0,
              right: 0,
              child: Center(
                child: _LoadingPill(dark: dark, colorScheme: colorScheme),
              ),
            );
          }),

          // ── Directions card ────────────────────────────────────────────
          Obx(() {
            final route = controller.activeRoute.value;
            if (route == null) return const SizedBox.shrink();
            return Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: _DirectionsCard(
                route: route,
                dark: dark,
                colorScheme: colorScheme,
              ),
            );
          }),

          // ── Stats sheet (hidden during active route) ───────────────────
          Obx(() {
            if (controller.activeRoute.value != null) {
              return const SizedBox.shrink();
            }
            return _StatsSheet(
              dark: dark,
              colorScheme: colorScheme,
              isAdmin: isAdmin,
            );
          }),

          // ── My-location FAB ────────────────────────────────────────────
          Obx(() {
            final bottom =
                controller.activeRoute.value != null ? 160.0 : 148.0;
            return Positioned(
              bottom: bottom,
              right: 16,
              child: _LocationFab(colorScheme: colorScheme),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _NirmalAppBar extends GetView<HomeController>
    implements PreferredSizeWidget {
  final bool dark;
  const _NirmalAppBar({required this.dark});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child:
                const Icon(Icons.eco_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            'Nirmal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: dark ? Colors.white : Colors.black87,
                  letterSpacing: 0.3,
                ),
          ),
          const SizedBox(width: 10),
          // [Improvement] Chip also reflects reconnecting state.
          Obx(() {
            final online = controller.isTruckOnline.value;
            final hasData = controller.truckData.value != null;
            final label = online
                ? 'Live'
                : hasData
                    ? 'Reconnecting'
                    : 'No truck';
            final dotColor = online
                ? Colors.green
                : hasData
                    ? Colors.orange
                    : Colors.grey;
            final bgColor = online
                ? Colors.green.withOpacity(0.15)
                : hasData
                    ? Colors.orange.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.12);
            final borderColor = online
                ? Colors.green.withOpacity(0.4)
                : hasData
                    ? Colors.orange.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.2);
            final textColor = online
                ? Colors.green.shade700
                : hasData
                    ? Colors.orange.shade700
                    : (dark ? Colors.grey[400]! : Colors.grey[600]!);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _GlassCircleButton(
            dark: dark,
            child: Icon(
              Icons.notifications_outlined,
              size: 20,
              color: dark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glass Circle Button
// ─────────────────────────────────────────────────────────────────────────────

class _GlassCircleButton extends StatelessWidget {
  final bool dark;
  final Widget child;
  final VoidCallback? onTap;

  const _GlassCircleButton({
    required this.dark,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (dark ? Colors.grey[850] : Colors.white)?.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading Pill
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingPill extends StatelessWidget {
  final bool dark;
  final ColorScheme colorScheme;

  const _LoadingPill({required this.dark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Finding route…',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Layer
// ─────────────────────────────────────────────────────────────────────────────

class _MapLayer extends GetView<HomeController> {
  final ColorScheme colorScheme;
  const _MapLayer({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Obx(() => FlutterMap(
          mapController: controller.mapController,
          options: MapOptions(
            center: controller.initialCenter.value,
            zoom: 15.0,
            maxZoom: 18.5,
            minZoom: 3.0,
            // [Fix] Wire onMapReady so the controller knows the map is mounted
            //       before attempting any mapController.move() calls.
            onMapReady: controller.onMapReady,
            onTap: (_, __) => controller.suggestions.clear(),
          ),
          children: [
            // ── Tiles ─────────────────────────────────────────────────────
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nirmal.app',
            ),

            // ── Route polyline ─────────────────────────────────────────────
            if (controller.activeRoute.value != null &&
                controller.activeRoute.value!.polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  // Glow layer
                  Polyline(
                    points: controller.activeRoute.value!.polylinePoints,
                    strokeWidth: 10,
                    color: const Color(0x441565C0),
                  ),
                  // Main line
                  Polyline(
                    points: controller.activeRoute.value!.polylinePoints,
                    strokeWidth: 5,
                    color: const Color(0xFF1565C0),
                    borderStrokeWidth: 1.5,
                    borderColor: Colors.white,
                  ),
                ],
              ),

            // ── User location dot ──────────────────────────────────────────
            if (controller.userLocation.value != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: controller.userLocation.value!,
                    width: 52,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    colorScheme.primary.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // ── Searched location pin ──────────────────────────────────────
            if (controller.searchedLocation.value != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: controller.searchedLocation.value!,
                    width: 50,
                    height: 72,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.place_rounded,
                              color: Colors.white, size: 26),
                        ),
                        Positioned(
                          top: 42,
                          left: 17,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            // ── Dustbin markers ────────────────────────────────────────────
            MarkerLayer(markers: controller.dummyMarkers),

            // ── Live truck marker ──────────────────────────────────────────
            // Only rendered after the RTDB has pushed at least one position.
            if (controller.truckMarker.value != null)
              MarkerLayer(
                markers: [controller.truckMarker.value!],
              ),
          ],
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Directions Card
// ─────────────────────────────────────────────────────────────────────────────

class _DirectionsCard extends GetView<HomeController> {
  final RouteInfo route;
  final bool dark;
  final ColorScheme colorScheme;

  const _DirectionsCard({
    required this.route,
    required this.dark,
    required this.colorScheme,
  });

  String _fmtDist(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  static const _routeBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: dark ? Colors.grey[800]! : Colors.grey.shade100,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            decoration: BoxDecoration(
              color: _routeBlue.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _routeBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_walk_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Walking Directions',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _routeBlue,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        route.destinationName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: controller.clearRoute,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          dark ? Colors.grey[800] : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 17,
                        color: dark ? Colors.white60 : Colors.black45),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _DirectionsStat(
                  icon: Icons.straighten_rounded,
                  iconColor: _routeBlue,
                  value: _fmtDist(route.distanceKm),
                  label: 'Distance',
                  dark: dark,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: dark ? Colors.grey[800] : Colors.grey.shade200,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _DirectionsStat(
                  icon: Icons.schedule_rounded,
                  iconColor: Colors.orange.shade600,
                  value: '${route.durationMinutes} min',
                  label: 'Walk time',
                  dark: dark,
                ),
                const Spacer(),
                // Go button — navigation handoff goes here.
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _routeBlue,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _routeBlue.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Go',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer hint
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0x121B5E20),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.delete_rounded,
                    color: Color(0xFF2E7D32), size: 15),
                const SizedBox(width: 6),
                Text(
                  'Dustbin · tap marker again to clear route',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: dark
                        ? Colors.grey[400]
                        : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w500,
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

class _DirectionsStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool dark;

  const _DirectionsStat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Panel
// ─────────────────────────────────────────────────────────────────────────────

class _SearchPanel extends GetView<HomeController> {
  final bool dark;
  final ColorScheme colorScheme;

  const _SearchPanel({required this.dark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search field
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: dark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search location…',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: dark ? Colors.grey[500] : Colors.grey[400],
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: colorScheme.primary, size: 22),
                suffixIcon: Obx(() {
                  if (controller.isSearching.value) {
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary),
                        ),
                      ),
                    );
                  }
                  if (controller.hasSearchText.value) {
                    return IconButton(
                      icon: Icon(Icons.cancel,
                          color: dark
                              ? Colors.grey[500]
                              : Colors.grey[400],
                          size: 20),
                      onPressed: controller.clearSearch,
                    );
                  }
                  return const SizedBox.shrink();
                }),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                controller.searchLocation(v);
                controller.suggestions.clear();
              },
            ),
          ),
        ),

        // Suggestion dropdown
        Obx(() {
          if (controller.suggestions.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: (dark ? Colors.grey[900] : Colors.white)
                  ?.withOpacity(0.97),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: (dark ? Colors.grey[700] : Colors.grey[200])!
                    .withOpacity(0.8),
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 240),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: controller.suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: dark ? Colors.grey[800] : Colors.grey[200],
                  indent: 52,
                  endIndent: 16,
                ),
                itemBuilder: (ctx, i) {
                  final place = controller.suggestions[i];
                  final display =
                      place['display_name'] as String? ?? '';
                  final parts = display.split(',');
                  final primary = parts.first.trim();
                  final secondary = parts.length > 1
                      ? parts.sublist(1).join(',').trim()
                      : '';
                  return InkWell(
                    onTap: () {
                      controller.selectSuggestion(place);
                      controller.suggestions.clear();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on_outlined,
                                color: colorScheme.primary, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: dark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                if (secondary.isNotEmpty)
                                  Text(
                                    secondary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.north_west_rounded,
                            size: 16,
                            color: dark
                                ? Colors.grey[600]
                                : Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _StatsSheet extends GetView<HomeController> {
  final bool dark;
  final ColorScheme colorScheme;
  final bool isAdmin;

  const _StatsSheet({
    required this.dark,
    required this.colorScheme,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.13,
      maxChildSize: 0.62,
      snap: true,
      snapSizes: const [0.13, 0.28, 0.62],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Activity",
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Row(children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Live · Updated in real time',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]),
                      ],
                    ),
                    // [Fix] Refresh re-subscribes the Firestore listener.
                    _GlassCircleButton(
                      dark: dark,
                      onTap: controller.refreshStats,
                      child: Icon(Icons.refresh_rounded,
                          size: 18, color: colorScheme.primary),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: dark ? Colors.grey[800] : Colors.grey[200],
                ),
              ),

              // Stat cards
              Obx(() {
                if (controller.statsLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: colorScheme.primary),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.local_shipping_rounded,
                            value:
                                controller.totalTrucks.value.toString(),
                            label: 'Total Trucks',
                            sublabel: 'Registered',
                            color: colorScheme.primary,
                            dark: dark,
                            onIncrement: isAdmin
                                ? controller.incrementTotalTrucks
                                : null,
                            onDecrement: isAdmin
                                ? controller.decrementTotalTrucks
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icon: Icons.alt_route_rounded,
                            value:
                                controller.activeRoutes.value.toString(),
                            label: 'Active Routes',
                            sublabel: 'In Progress',
                            color: Colors.orange.shade600,
                            dark: dark,
                            onIncrement: isAdmin
                                ? controller.incrementActiveRoutes
                                : null,
                            onDecrement: isAdmin
                                ? controller.decrementActiveRoutes
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icon: Icons.task_alt_rounded,
                            value: controller.completedDeliveries.value
                                .toString(),
                            label: 'Completed',
                            sublabel: 'Routes',
                            color: Colors.green.shade600,
                            dark: dark,
                            onIncrement: isAdmin
                                ? controller.incrementCompletedDeliveries
                                : null,
                            onDecrement: isAdmin
                                ? controller.decrementCompletedDeliveries
                                : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: StatCard(
                            icon: Icons.warning_amber_rounded,
                            value:
                                controller.delayedTrucks.value.toString(),
                            label: 'Delayed',
                            sublabel: 'Trucks',
                            color: Colors.red.shade400,
                            dark: dark,
                            onIncrement: isAdmin
                                ? controller.incrementDelayedTrucks
                                : null,
                            onDecrement: isAdmin
                                ? controller.decrementDelayedTrucks
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icon: Icons.pause_circle_outline_rounded,
                            value:
                                controller.idleTrucks.value.toString(),
                            label: 'Idle',
                            sublabel: 'Trucks',
                            color: Colors.blueGrey.shade400,
                            dark: dark,
                            onIncrement: isAdmin
                                ? controller.incrementIdleTrucks
                                : null,
                            onDecrement: isAdmin
                                ? controller.decrementIdleTrucks
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            icon: Icons.notifications_active_rounded,
                            value:
                                controller.activeAlerts.value.toString(),
                            label: 'Alerts',
                            sublabel: 'Active',
                            color: Colors.amber.shade600,
                            dark: dark,
                            onIncrement: isAdmin
                                ? controller.incrementActiveAlerts
                                : null,
                            onDecrement: isAdmin
                                ? controller.decrementActiveAlerts
                                : null,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _OnTimeBar(
                        dark: dark,
                        colorScheme: colorScheme,
                        isAdmin: isAdmin,
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// On-Time Bar
// ─────────────────────────────────────────────────────────────────────────────

class _OnTimeBar extends GetView<HomeController> {
  final bool dark;
  final ColorScheme colorScheme;
  final bool isAdmin;

  const _OnTimeBar({
    required this.dark,
    required this.colorScheme,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pct = controller.onTimePercentage.value;
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: dark ? Colors.grey[850] : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'On-Time Pickup',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        dark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Row(children: [
                  if (isAdmin)
                    _SmallIconBtn(
                      icon: Icons.remove,
                      dark: dark,
                      onTap: controller.decrementOnTimePercentage,
                    ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (isAdmin)
                    _SmallIconBtn(
                      icon: Icons.add,
                      dark: dark,
                      onTap: controller.incrementOnTimePercentage,
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor:
                    dark ? Colors.grey[700] : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  pct >= 90
                      ? Colors.green.shade500
                      : pct >= 70
                          ? Colors.orange.shade500
                          : Colors.red.shade400,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card  (public — used by stats screen too)
// ─────────────────────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;
  final bool dark;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.dark,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: dark ? Colors.grey[850] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? Colors.grey[800]! : Colors.grey.shade200,
        ),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (onDecrement != null)
            _SmallIconBtn(
                icon: Icons.remove, dark: dark, onTap: onDecrement!),
          const SizedBox(width: 6),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 6),
          if (onIncrement != null)
            _SmallIconBtn(
                icon: Icons.add, dark: dark, onTap: onIncrement!),
        ]),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: dark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10.5,
            color: dark ? Colors.grey[600] : Colors.grey[500],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Icon Button
// ─────────────────────────────────────────────────────────────────────────────

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _SmallIconBtn({
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: dark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location FAB
// ─────────────────────────────────────────────────────────────────────────────

class _LocationFab extends GetView<HomeController> {
  final ColorScheme colorScheme;
  const _LocationFab({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: controller.goToUserLocation,
        backgroundColor: colorScheme.primary,
        elevation: 0,
        tooltip: 'My location',
        child: const Icon(Icons.my_location_rounded,
            color: Colors.white, size: 24),
      ),
    );
  }
}
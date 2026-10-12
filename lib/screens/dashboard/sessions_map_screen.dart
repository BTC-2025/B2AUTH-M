import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/account_provider.dart';
import '../../services/location_provider.dart';

class SessionsMapScreen extends StatefulWidget {
  const SessionsMapScreen({super.key});

  @override
  State<SessionsMapScreen> createState() => _SessionsMapScreenState();
}

class _SessionsMapScreenState extends State<SessionsMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLatLng;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectAndSetLocation();
    });
  }

  Future<void> _detectAndSetLocation() async {
    if (!mounted) return;
    setState(() => _isLocating = true);

    try {
      final locationProvider = context.read<LocationProvider>();
      await locationProvider.detectGPSLocation();
      
      final loc = locationProvider.location;
      if (loc != null && mounted) {
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _currentLatLng = latLng;
        });
        _mapController.move(latLng, 14.0);

        String resolvedLocation = loc.zip.isNotEmpty ? '${loc.city}, ${loc.zip}' : loc.city;
        context.read<AccountProvider>().updateLocation(resolvedLocation);
      }
    } catch (e) {
      debugPrint('Failed to locate in real time: $e');
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  LatLng _getMapLatLng(String location) {
    final locLower = location.toLowerCase();
    if (locLower.contains('chennai')) {
      return const LatLng(13.0827, 80.2707);
    } else if (locLower.contains('manavalanagar') || locLower.contains('tiruvallur') || locLower.contains('thiruvallur')) {
      return const LatLng(13.0890, 79.9071);
    } else if (locLower.contains('tokyo')) {
      return const LatLng(35.6895, 139.6917);
    } else if (locLower.contains('london')) {
      return const LatLng(51.5074, -0.1278);
    } else if (locLower.contains('paris')) {
      return const LatLng(48.8566, 2.3522);
    } else if (locLower.contains('new york')) {
      return const LatLng(40.7128, -74.0060);
    }
    // Default fallback to Thiruvallur area
    return const LatLng(13.0890, 79.9071);
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.watch<AccountProvider>();
    final activeLocation = accountProvider.selectedAccount?.location ?? 'Manavalanagar, 602002';
    final targetLatLng = _currentLatLng ?? _getMapLatLng(activeLocation);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sessions',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          // Background Real Interactive Tile Map (OpenStreetMap style surroundings)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: targetLatLng,
                initialZoom: 12.0,
                minZoom: 4.0,
                maxZoom: 18.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.b2auth.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: targetLatLng,
                      width: 220,
                      height: 100,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Authenticator App - B2Auth',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.success.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.security,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Zoom In / Zoom Out / Locate Floating Controls
          Positioned(
            right: 20,
            bottom: 140,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'locate_self_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: _isLocating ? null : _detectAndSetLocation,
                  child: _isLocating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(Icons.my_location),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom + 1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () {
                    final currentZoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, currentZoom - 1);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Bottom Session Info Card
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.language,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Authenticator App - B2Auth',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CPH2455, ANDROID',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active now • $activeLocation',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

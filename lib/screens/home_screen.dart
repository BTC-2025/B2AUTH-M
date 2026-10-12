import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_overlay.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/account_provider.dart';
import '../core/services/local_storage_service.dart';
import '../core/providers/notification_provider.dart';
import 'dashboard/dashboard_page.dart';
import 'dashboard/mfa_page.dart';
import 'security/security_page.dart';
import 'settings/settings_page.dart';
import 'notifications/notifications_page.dart';
import '../services/location_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1; // Default to MFA page to showcase it
  final GlobalKey _avatarKey = GlobalKey();
  
  List<String> _searchResults = [];
  bool _isSearching = false;
  String _lastSearchQuery = '';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _selectedIndex = settings.defaultHomepage == 'authenticator' ? 0 : 1;
    _pages = [
      DashboardPage(onSwitchTab: (index) => setState(() => _selectedIndex = index)),
      MfaPage(onSwitchTab: (index) => setState(() => _selectedIndex = index)),
      const SecurityPage(),
      SettingsPage(onSwitchTab: (index) => setState(() => _selectedIndex = index)),
      const NotificationsPage(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = LocalStorageService.getString('access_token') ?? '';
      if (token.isNotEmpty) {
        context.read<AccountProvider>().fetchProfileFromApi(token);
      }
    });
  }

  void _showProfileOverlay() {
    final RenderBox renderBox = _avatarKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.05),
      builder: (context) => Stack(
        children: [
          Positioned(
            top: offset.dy + renderBox.size.height + 12,
            right: 20,
            child: const ProfileOverlay(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(settings.accentColor),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: IndexedStack(
                  key: ValueKey<int>(_selectedIndex),
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(settings.accentColor),
    );
  }

  Widget _buildTopBar(Color accentColor) {
    final accountProvider = context.watch<AccountProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final unreadCount = notificationProvider.notifications.where((n) => !n.isRead).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Transform.scale(
                    scale: 1.5,
                    child: Image.asset(
                      'assets/Auth_img.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.shield_outlined, color: accentColor, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'B2Auth',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Alerts / Notifications Icon Button with Badge
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 4; // Index of NotificationsPage
                  });
                },
                child: Container(
                  height: 36,
                  width: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkShadow.withValues(alpha: 0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: AppColors.lightShadow,
                        offset: const Offset(-2, -2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        _selectedIndex == 4 ? Icons.notifications : Icons.notifications_none_outlined,
                        color: _selectedIndex == 4 ? accentColor : AppColors.textSecondary,
                        size: 20,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                key: _avatarKey,
                onTap: _showProfileOverlay,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkShadow,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                      BoxShadow(
                        color: AppColors.lightShadow,
                        offset: Offset(-2, -2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: ProfileAvatar(
                    letter: accountProvider.selectedAccount?.avatarLetter ?? 'R',
                    imageUrl: accountProvider.selectedAccount?.avatarUrl,
                    imagePath: accountProvider.selectedAccount?.profileImagePath,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLocationPill(accentColor, accountProvider),
        ],
      ),
    );
  }

  bool _isLocating = false;

  Future<void> _detectAndSetLocation(Color accentColor, AccountProvider provider) async {
    setState(() => _isLocating = true);
    try {
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      await locationProvider.detectGPSLocation();
      
      if (!mounted) return;

      if (locationProvider.errorMessage != null) {
        throw Exception(locationProvider.errorMessage);
      }
      
      final loc = locationProvider.location;
      if (loc != null) {
        String resolvedLocation = loc.zip.isNotEmpty ? '${loc.city}, ${loc.zip}' : loc.city;
        provider.updateLocation(resolvedLocation);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detected location: $resolvedLocation'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: accentColor,
          ),
        );
      } else {
        throw Exception('Could not resolve location address.');
      }
    } catch (e) {
      if (!mounted) return;
      provider.updateLocation('Manavalanagar, 602002');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location detection failed. Using fallback location.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _searchPlaces(String query, StateSetter setModalState) async {
    if (query.trim().isEmpty) {
      setModalState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setModalState(() {
      _isSearching = true;
      _lastSearchQuery = query;
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5');
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'B2AuthApp/1.0 (contact@b2auth.com) MobileGeolocator');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = json.decode(responseBody);
        
        final List<String> results = [];
        for (var item in data) {
          final address = item['address'] ?? {};
          String name = address['neighbourhood'] ?? 
                        address['suburb'] ?? 
                        address['village'] ?? 
                        address['town'] ?? 
                        address['city'] ?? 
                        address['county'] ?? 
                        address['state'] ?? 
                        address['country'] ?? 
                        '';
          
          if (name.isEmpty) {
            final displayName = item['display_name'] ?? '';
            if (displayName.isNotEmpty) {
              final parts = displayName.split(',');
              name = parts.first.trim();
            }
          }
          
          final postcode = address['postcode'] ?? '';
          
          if (name.isNotEmpty) {
            final formatted = postcode.isNotEmpty ? '$name, $postcode' : name;
            if (!results.contains(formatted)) {
              results.add(formatted);
            }
          }
        }
        
        if (query == _lastSearchQuery) {
          setModalState(() {
            _searchResults = results;
            _isSearching = false;
          });
        }
      } else {
        throw Exception();
      }
    } catch (e) {
      if (query == _lastSearchQuery) {
        setModalState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Widget _buildLocationPill(Color accentColor, AccountProvider accountProvider) {
    final location = accountProvider.selectedAccount?.location ?? 'Set Location';
    return GestureDetector(
      onTap: () => _showLocationSelector(context, accentColor, accountProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLocating)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            else
              Icon(Icons.gps_fixed, color: accentColor, size: 14),
            const SizedBox(width: 6),
            Text(
              location,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: accentColor, size: 16),
          ],
        ),
      ),
    );
  }

  void _showLocationSelector(BuildContext context, Color accentColor, AccountProvider accountProvider) {
    final searchController = TextEditingController();
    final popularPlaces = ['New York', 'London', 'Tokyo', 'Paris', 'Manavalanagar, 602002'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Search Field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search city or place...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) {
                      _searchPlaces(val, setModalState);
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Use Current Location
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Icon(Icons.gps_fixed, color: accentColor),
                      title: const Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('GPS Active', style: TextStyle(fontSize: 11)),
                      trailing: _isLocating
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text('Detecting GPS location...'),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: accentColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                        await _detectAndSetLocation(accentColor, accountProvider);
                      },
                    ),
                  ),
                  const Divider(),

                  // If searching is active, render search states
                  if (searchController.text.trim().isNotEmpty) ...[
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_searchResults.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            "Place doesn't exist",
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._searchResults.map((place) {
                        final isCurrent = accountProvider.selectedAccount?.location == place;
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(place),
                          trailing: isCurrent ? Icon(Icons.check, color: accentColor) : null,
                          onTap: () {
                            accountProvider.updateLocation(place);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Location updated to $place'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: accentColor,
                              ),
                            );
                          },
                        );
                      }),
                  ] else ...[
                    // Default State (Not Searching): Show Use Current Location & Popular Places
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Popular Places', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    ...popularPlaces.map((place) {
                      final isCurrent = accountProvider.selectedAccount?.location == place;
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(place),
                        trailing: isCurrent ? Icon(Icons.check, color: accentColor) : null,
                        onTap: () {
                          accountProvider.updateLocation(place);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Location updated to $place'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: accentColor,
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        },
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', accentColor),
            _buildNavItem(1, Icons.shield_outlined, Icons.shield, 'MFA', accentColor),
            _buildNavItem(2, Icons.vpn_key_outlined, Icons.vpn_key, 'Security', accentColor),
            _buildNavItem(3, Icons.settings_outlined, Icons.settings, 'Settings', accentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData solidIcon, String label, Color accentColor) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? accentColor : AppColors.textSecondary;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

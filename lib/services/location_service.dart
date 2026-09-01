import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class UserLocation {
  final String city;
  final String zip;
  final String? streetAddress;
  final double latitude;
  final double longitude;

  UserLocation({
    required this.city,
    required this.zip,
    this.streetAddress,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  /// Detects the current device location and attempts to reverse-geocode it.
  /// Falls back to displaying coordinates if geocoding fails or is unsupported.
  static Future<UserLocation> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    } 

    // Fetch the current GPS position with a 10-second timeout
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    String city = 'Unknown City';
    String zip = '';
    String? streetAddress;

    try {
      // Try using the native geocoding package
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        // Find the best name for the locality
        final String detectedCity = place.locality ?? '';
        final String detectedSubAdmin = place.subAdministrativeArea ?? '';
        final String detectedAdmin = place.administrativeArea ?? '';
        
        if (detectedCity.isNotEmpty) {
          city = detectedCity;
        } else if (detectedSubAdmin.isNotEmpty) {
          city = detectedSubAdmin;
        } else if (detectedAdmin.isNotEmpty) {
          city = detectedAdmin;
        } else {
          city = 'Unknown City';
        }
        
        zip = place.postalCode ?? '';
        streetAddress = place.street;
      }
    } catch (e) {
      // Fallback: If native geocoding fails (e.g. web/windows, no internet, or native provider unavailable),
      // we format the coordinates nicely as the location display.
      city = 'Lat: ${position.latitude.toStringAsFixed(2)}';
      zip = 'Lng: ${position.longitude.toStringAsFixed(2)}';
      streetAddress = 'Coordinates: ${position.latitude}, ${position.longitude}';
    }

    return UserLocation(
      city: city,
      zip: zip,
      streetAddress: streetAddress,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Searches for coordinates of an address/city and reverse-geocodes it.
  /// Returns a UserLocation if successful, or a fallback location using the query.
  static Future<UserLocation?> searchPosition(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      // Fetch coordinates for the address/city query
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final Location loc = locations.first;
        
        // Reverse-geocode coordinates to get structured details
        List<Placemark> placemarks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        );
        
        String city = query;
        String zip = '';
        String? streetAddress;

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          final String country = place.country ?? '';
          final String adminArea = place.administrativeArea ?? '';
          final String locality = place.locality ?? '';
          final String subAdmin = place.subAdministrativeArea ?? '';

          // If query is an exact match for the country name or ISO code
          if (country.toLowerCase() == query.trim().toLowerCase() ||
              place.isoCountryCode?.toLowerCase() == query.trim().toLowerCase()) {
            city = country;
          }
          // If query matches the state/province name
          else if (adminArea.toLowerCase() == query.trim().toLowerCase()) {
            city = adminArea.isNotEmpty && country.isNotEmpty ? "$adminArea, $country" : adminArea;
          }
          // Otherwise build a hierarchy (Locality, AdminArea, Country)
          else {
            List<String> parts = [];
            if (locality.isNotEmpty) {
              parts.add(locality);
            } else if (subAdmin.isNotEmpty) {
              parts.add(subAdmin);
            }
            
            if (adminArea.isNotEmpty && adminArea != locality) {
              parts.add(adminArea);
            }
            
            if (country.isNotEmpty && country != adminArea) {
              parts.add(country);
            }
            
            if (parts.isNotEmpty) {
              city = parts.join(', ');
            }
          }
          
          zip = place.postalCode ?? '';
          streetAddress = place.street;
        }

        return UserLocation(
          city: city,
          zip: zip,
          streetAddress: streetAddress,
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      }
    } catch (e) {
      // Return null if geocoding lookup fails to find a real place
      return null;
    }
    return null;
  }
}

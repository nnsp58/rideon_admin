import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapService {
  // Photon API for Autocomplete (Free, No key) — biased towards India
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.length < 3) return [];
    
    try {
      // Photon with India location bias (lat=22, lon=78 = center of India)
      final response = await http.get(
        Uri.parse('https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5&lat=22&lon=78&lang=en'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List features = data['features'];
        
        if (features.isNotEmpty) {
          return features.map((f) {
            final props = f['properties'];
            final coords = f['geometry']['coordinates'];
            
            String name = props['name'] ?? '';
            String city = props['city'] ?? '';
            String state = props['state'] ?? '';
            String country = props['country'] ?? '';
            
            String description = [city, state, country]
                .where((s) => s.isNotEmpty)
                .join(', ');

            return {
              'display_name': name + (description.isNotEmpty ? ', $description' : ''),
              'lat': (coords[1] as num).toDouble(),
              'lon': (coords[0] as num).toDouble(),
            };
          }).toList();
        }
      }

      // Fallback: Nominatim search if Photon returns empty
      return await _searchNominatim(query);
    } catch (e) {
      debugPrint('Search error: $e');
      // Try Nominatim as fallback
      try {
        return await _searchNominatim(query);
      } catch (_) {}
    }
    return [];
  }

  // Nominatim fallback search (for when Photon doesn't find results)
  static Future<List<Map<String, dynamic>>> _searchNominatim(String query) async {
    final response = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=in',
      ),
      headers: {'User-Agent': 'RideOn_App'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) {
        return {
          'display_name': item['display_name'] as String,
          'lat': double.parse(item['lat']),
          'lon': double.parse(item['lon']),
        };
      }).toList();
    }
    return [];
  }

  // OSRM API for Routing — returns multiple route alternatives
  static Future<List<RouteOption>> getDetailedRoutes(LatLng start, LatLng end) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&alternatives=true',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List routes = data['routes'];
        
        return routes.asMap().entries.map((entry) {
          final r = entry.value;
          final List coords = r['geometry']['coordinates'];
          final String summary = r['legs']?[0]?['summary'] ?? '';
          return RouteOption(
            points: coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList(),
            distanceKm: (r['distance'] as num) / 1000,
            durationMins: (r['duration'] as num) ~/ 60,
            name: summary.isNotEmpty ? summary : 'Route ${entry.key + 1}',
          );
        }).toList();
      }
    } catch (e) {
      print('Routing error: $e');
    }
    return [];
  }

  // Legacy support for single route points
  static Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final routes = await getDetailedRoutes(start, end);
    return routes.isNotEmpty ? routes[0].points : [];
  }

  // Nominatim for Reverse Geocoding
  static Future<String> getAddressFromLatLng(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon'),
        headers: {'User-Agent': 'RideOn_App'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Unknown Location';
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return 'Unknown Location';
  }
}

class RouteOption {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMins;
  final String name;

  RouteOption({
    required this.points,
    required this.distanceKm,
    required this.durationMins,
    required this.name,
  });
}

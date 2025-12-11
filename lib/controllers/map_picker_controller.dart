import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapPickerController extends GetxController {
  final center = LatLng(12.9716, 77.5946).obs;
  final selected = Rxn<LatLng>();
  final isSearching = false.obs;
  final results = <Map<String, dynamic>>[].obs;
  final selectedLabelFromSearch = RxnString();

  Future<LatLng?> initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled) return null;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition();
      final current = LatLng(pos.latitude, pos.longitude);

      center.value = current;
      selected.value = current;
      selectedLabelFromSearch.value = null;

      return current;
    } catch (e) {
      debugPrint('initLocation error: $e');
      return null;
    }
  }

  Future<void> searchPlace(String query) async {
    if (query.trim().isEmpty) return;
    isSearching.value = true;
    results.clear();

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'dump_and_drop_app'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body) as List;
        final List<Map<String, dynamic>> parsed = data.map((e) {
          return {
            'displayName': e['display_name'] as String,
            'lat': double.tryParse(e['lat'] as String) ?? 0.0,
            'lon': double.tryParse(e['lon'] as String) ?? 0.0,
          };
        }).toList();

        results.addAll(parsed);
      }
    } catch (e) {
      debugPrint('searchPlace error: $e');
    } finally {
      isSearching.value = false;
    }
  }

  void applySearchResult(Map<String, dynamic> place) {
    final lat = place['lat'] as double;
    final lon = place['lon'] as double;
    final pos = LatLng(lat, lon);
    final displayName = place['displayName'] as String;

    center.value = pos;
    selected.value = pos;
    results.clear();
    selectedLabelFromSearch.value = displayName;
  }

  void setSelected(LatLng p) {
    center.value = p;
    selected.value = p;
    selectedLabelFromSearch.value = null;
  }

  Future<String> reverseGeocode(LatLng point) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=${point.latitude}&lon=${point.longitude}&format=json',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'dump_and_drop_app'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final fullName = data['display_name'] as String? ?? '';
        if (fullName.isEmpty) {
          return "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}";
        }
        final parts = fullName.split(',');
        if (parts.isEmpty) {
          return fullName;
        }
        final short = parts.take(2).join(',').trim();
        return short.isEmpty ? fullName : short;
      }
    } catch (e) {
      debugPrint('reverseGeocode error: $e');
    }
    return "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}";
  }

  Map<String, dynamic>? getSelectedPayload() {
    final s = selected.value;
    if (s == null) return null;
    final label = selectedLabelFromSearch.value;
    return {
      'label': label ?? '',
      'lat': s.latitude,
      'lng': s.longitude,
    };
  }
}

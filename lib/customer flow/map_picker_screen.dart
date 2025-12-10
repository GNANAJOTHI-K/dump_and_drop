import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const Color kPrimaryColor = Color(0xFF446FA8);

class MapPickerScreen extends StatefulWidget {
  final bool isPickup;

  const MapPickerScreen({super.key, required this.isPickup});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _center = const LatLng(12.9716, 77.5946);
  LatLng? _selected;
  bool _isSearching = false;
  List<Map<String, dynamic>> _results = [];
  String? _selectedLabelFromSearch;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) return;

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    final current = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _center = current;
      _selected = current;
      _selectedLabelFromSearch = null;
    });

    _mapController.move(current, 15);
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _results = [];
    });

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'dump_and_drop_app'},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      final List<Map<String, dynamic>> parsed = data.map((e) {
        return {
          'displayName': e['display_name'] as String,
          'lat': double.tryParse(e['lat'] as String) ?? 0.0,
          'lon': double.tryParse(e['lon'] as String) ?? 0.0,
        };
      }).toList();

      setState(() {
        _results = parsed;
      });
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _applySearchResult(Map<String, dynamic> place) {
    final lat = place['lat'] as double;
    final lon = place['lon'] as double;
    final pos = LatLng(lat, lon);
    final displayName = place['displayName'] as String;

    setState(() {
      _center = pos;
      _selected = pos;
      _results = [];
      _selectedLabelFromSearch = displayName;
    });

    _mapController.move(pos, 16);
    _searchController.text = displayName;
  }

  Future<String> _reverseGeocode(LatLng point) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=${point.latitude}&lon=${point.longitude}&format=json',
    );

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'dump_and_drop_app'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
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

    return "${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}";
  }

  Future<void> _confirmLocation() async {
    if (_selected == null) return;

    String label;
    if (_selectedLabelFromSearch != null) {
      label = _selectedLabelFromSearch!;
    } else {
      label = await _reverseGeocode(_selected!);
    }

    if (!mounted) return;

    Navigator.pop(context, {
      'label': label,
      'lat': _selected!.latitude,
      'lng': _selected!.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: Text(widget.isPickup ? "Select Pickup" : "Select Drop"),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onTap: (tapPos, latLng) {
                setState(() {
                  _selected = latLng;
                  _selectedLabelFromSearch = null;
                });
              },
              onPositionChanged: (position, hasGesture) {
                if (position.center != null && hasGesture) {
                  setState(() {
                    _center = position.center!;
                    _selected = position.center!;
                    _selectedLabelFromSearch = null;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dump_and_drop',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 36,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search location",
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchPlace(),
                      ),
                    ),
                    IconButton(
                      icon: _isSearching
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      onPressed: _isSearching ? null : _searchPlace,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_results.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              top: 70,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final place = _results[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          place['displayName'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _applySearchResult(place),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor,
        onPressed: _confirmLocation,
        child: const Icon(Icons.check),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
 

import 'package:get/get.dart';

import '../controllers/map_picker_controller.dart';

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
  final MapPickerController _ctrl = Get.put(MapPickerController());

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final cur = await _ctrl.initLocation();
    if (cur != null) _mapController.move(cur, 15);
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    await _ctrl.searchPlace(query);
  }

  void _applySearchResult(Map<String, dynamic> place) {
    _ctrl.applySearchResult(place);
    final lat = place['lat'] as double;
    final lon = place['lon'] as double;
    final pos = LatLng(lat, lon);
    _mapController.move(pos, 16);
    _searchController.text = place['displayName'] as String;
  }

  Future<void> _confirmLocation() async {
    final s = _ctrl.selected.value;
    if (s == null) return;

    String label;
    if (_ctrl.selectedLabelFromSearch.value != null) {
      label = _ctrl.selectedLabelFromSearch.value!;
    } else {
      label = await _ctrl.reverseGeocode(s);
    }

    if (!mounted) return;
    Navigator.pop(context, {
      'label': label,
      'lat': s.latitude,
      'lng': s.longitude,
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
              initialCenter: _ctrl.center.value,
              initialZoom: 15,
              onTap: (tapPos, latLng) {
                _ctrl.setSelected(latLng);
              },
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  _ctrl.setSelected(position.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.dump_and_drop',
              ),
              Obx(() {
                final sel = _ctrl.selected.value;
                if (sel == null) return const SizedBox.shrink();
                return MarkerLayer(
                  markers: [
                    Marker(
                      point: sel,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        size: 36,
                        color: kPrimaryColor,
                      ),
                    ),
                  ],
                );
              }),
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
                    Obx(() {
                      final searching = _ctrl.isSearching.value;
                      return IconButton(
                        icon: searching
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        onPressed: searching ? null : _searchPlace,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Obx(() {
            final results = _ctrl.results;
            if (results.isEmpty) return const SizedBox.shrink();
            return Positioned(
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
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
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
            );
          }),
          
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

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';

class AdminActivityMap extends StatelessWidget {
  final List<Marker> markers;
  final LatLng initialCenter;
  final double initialZoom;

  const AdminActivityMap({
    super.key,
    this.markers = const [],
    this.initialCenter = const LatLng(28.6139, 77.2090), // Delhi
    this.initialZoom = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.rideon.admin',
            tileProvider: CancellableNetworkTileProvider(),
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}

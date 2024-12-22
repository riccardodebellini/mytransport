import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(45.464219, 9.189606),
            initialZoom: 16,
        minZoom: 13,
        maxZoom: 18
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}@2x.png',
        maxZoom: 18,
          minZoom: 13,
          tileBounds: LatLngBounds(LatLng(45.584754, 9.058518), LatLng(45.377599, 9.304505)),
        ),
      ],
    );
  }
}

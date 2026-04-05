import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../domain/entities/nearby_spot.dart';

class NearbySpotsScreen extends StatelessWidget {
  const NearbySpotsScreen({
    super.key,
    required this.office,
  });

  final dynamic office;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Spots'),
      ),
      body: const Center(
        child: Text('Nearby spots loading...'),
      ),
    );
  }
}
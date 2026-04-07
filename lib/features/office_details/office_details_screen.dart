import 'package:flutter/material.dart';
import '../../domain/models/office.dart';
import '../../../routing/presentation/route_page.dart';

class OfficeDetailsScreen extends StatelessWidget {
  final Office office;

  const OfficeDetailsScreen({super.key, required this.office});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(office.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              office.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(office.address ?? 'No address available'),
            const SizedBox(height: 20),

            /// DISTANCE (simple placeholder for now)
            const Text("Distance: --"),
            const Text("ETA: --"),

            const Spacer(),

            /// PRIMARY BUTTON
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoutePage(office: office),
                    ),
                  );
                },
                icon: const Icon(Icons.directions),
                label: const Text("Get Directions"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
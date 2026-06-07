import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/location_reading.dart';

/// A single reading row: timestamp, coordinates (5 dp), and a distance chip.
class ReadingTile extends StatelessWidget {
  const ReadingTile({super.key, required this.reading});

  final LocationReading reading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.primary.withValues(alpha: 0.08),
        foregroundColor: scheme.primary,
        child: const Icon(Icons.place_outlined),
      ),
      title: Text(formatTimestamp(reading.timestamp)),
      subtitle: Text(
        '${formatCoordinate(reading.latitude)}, '
        '${formatCoordinate(reading.longitude)}',
      ),
      trailing: _DistanceChip(meters: reading.distanceMeters),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.meters});

  final double meters;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatDistance(meters),
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

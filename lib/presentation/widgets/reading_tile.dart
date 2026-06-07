import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/location_reading.dart';

/// A single reading row: timestamp, coordinates (5 dp), and a distance chip.
///
/// The most recent reading ([isLatest]) is tinted and badged so the live update
/// is easy to spot at the top of the list.
class ReadingTile extends StatelessWidget {
  const ReadingTile({
    super.key,
    required this.reading,
    this.isLatest = false,
  });

  final LocationReading reading;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: isLatest ? scheme.secondary.withValues(alpha: 0.10) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLatest
              ? scheme.secondary.withValues(alpha: 0.25)
              : scheme.primary.withValues(alpha: 0.08),
          foregroundColor: scheme.primary,
          child: Icon(isLatest ? Icons.my_location : Icons.place_outlined),
        ),
        title: Row(
          children: [
            Flexible(child: Text(formatTimestamp(reading.timestamp))),
            if (isLatest) ...[
              const SizedBox(width: 8),
              _LatestBadge(color: scheme.secondary),
            ],
          ],
        ),
        subtitle: Text(
          '${formatCoordinate(reading.latitude)}, '
          '${formatCoordinate(reading.longitude)}',
        ),
        trailing: _DistanceChip(meters: reading.distanceMeters),
      ),
    );
  }
}

class _LatestBadge extends StatelessWidget {
  const _LatestBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'LATEST',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
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

import 'package:flutter/material.dart';

/// Filters the readings list to the most recent N (5/10/15/20) or All.
/// Pure view concern — it never touches storage.
class FilterSelector extends StatelessWidget {
  const FilterSelector({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  /// Currently selected limit, or null for "All".
  final int? filter;
  final ValueChanged<int?> onChanged;

  static const List<int?> _options = [null, 5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<int?>(
          showSelectedIcon: false,
          segments: [
            for (final option in _options)
              ButtonSegment<int?>(
                value: option,
                label: Text(option == null ? 'All' : '$option'),
              ),
          ],
          selected: {filter},
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
      ),
    );
  }
}

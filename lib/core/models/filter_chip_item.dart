import 'package:flutter/material.dart';

/// A model representing a single filter chip item, used by map screens
/// and any other feature requiring horizontally-scrollable filter chips.
class FilterChipItem {
  final String label;
  final IconData? icon;
  final bool isDefault;

  const FilterChipItem({
    required this.label,
    this.icon,
    this.isDefault = false,
  });
}

import 'package:flutter/material.dart';

const List<String> kSupportedBoxBackgroundFits = <String>[
  'cover',
  'contain',
  'fill',
  'fitWidth',
  'fitHeight',
];

const List<String> kSupportedBoxBorderStyles = <String>[
  'normal',
  'solid',
  'dashed',
  'dotted',
];

double sanitizeBoxHeight(
  double? value, {
  double fallback = 100.0,
  double min = 80.0,
  double max = 600.0,
}) {
  final candidate = value ?? fallback;
  if (!candidate.isFinite) return fallback;
  return candidate.clamp(min, max).toDouble();
}

double sanitizeBoxOverlayOpacity(
  num? value, {
  double fallback = 0.3,
  double min = 0.0,
  double max = 0.8,
}) {
  final candidate = value?.toDouble() ?? fallback;
  if (!candidate.isFinite) return fallback;
  return candidate.clamp(min, max).toDouble();
}

String sanitizeBoxBackgroundFit(Object? fit) {
  if (fit is String && kSupportedBoxBackgroundFits.contains(fit)) {
    return fit;
  }
  return 'cover';
}

String sanitizeBoxBorderStyle(Object? style) {
  if (style is String && kSupportedBoxBorderStyles.contains(style)) {
    return style;
  }
  return 'solid';
}

BoxFit resolveBoxFit(String fit) {
  switch (sanitizeBoxBackgroundFit(fit)) {
    case 'fill':
      return BoxFit.fill;
    case 'contain':
      return BoxFit.contain;
    case 'fitWidth':
      return BoxFit.fitWidth;
    case 'fitHeight':
      return BoxFit.fitHeight;
    case 'cover':
      return BoxFit.cover;
  }

  return BoxFit.cover;
}

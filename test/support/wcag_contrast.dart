import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG 2.x relative luminance of an sRGB color.
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double relativeLuminance(Color color) {
  double linearize(double channel) {
    if (channel <= 0.03928) return channel / 12.92;
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);

  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG 2.x contrast ratio between two colors, order-independent.
/// https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG AA threshold for normal-size text (< 18pt, or < 14pt bold).
const double wcagAaNormalText = 4.5;

/// WCAG AA threshold for large-size text (≥ 18pt, or ≥ 14pt bold) and
/// non-text UI components.
const double wcagAaLargeText = 3;

// Throwaway asset-generation script — not part of the shipped app.
// Run once with `dart run tool/generate_app_icon.dart`, then safe to delete;
// its output (assets/icon/*.png) is what actually gets committed and wired
// via flavorizr.yaml.
//
// Design: a minimalist receipt with a coin — instantly reads as "track your
// spending" with no dependency on any product-name wordplay. Same motif for
// dev/prod; dev adds a diagonal "DEV" ribbon banner. Light and dark
// background variants are generated for both.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const int size = 1024;

// Palette
final ColorRgb8 coralTop = ColorRgb8(255, 138, 101); // #FF8A65
final ColorRgb8 goldBottom = ColorRgb8(255, 183, 77); // #FFB74D
final ColorRgb8 plumTop = ColorRgb8(74, 37, 69); // #4A2545
final ColorRgb8 navyBottom = ColorRgb8(36, 27, 78); // #241B4E

final ColorRgb8 receiptCream = ColorRgb8(255, 248, 240); // #FFF8F0
final ColorRgb8 lineMuted = ColorRgb8(214, 201, 186); // #D6C9BA — line items
final ColorRgb8 lineAccent = ColorRgb8(232, 93, 75); // #E85D4B — total line
final ColorRgb8 coinGold = ColorRgb8(245, 196, 81); // #F5C451
final ColorRgb8 coinGoldDark = ColorRgb8(214, 163, 48); // #D6A330
final ColorRgb8 coinGoldLight = ColorRgb8(255, 224, 150); // #FFE096

final ColorRgb8 devBannerBg = ColorRgb8(38, 41, 61); // near-navy
final ColorRgb8 devBannerText = ColorRgb8(255, 255, 255);

void verticalGradient(Image img, ColorRgb8 top, ColorRgb8 bottom) {
  for (var y = 0; y < img.height; y++) {
    final t = y / (img.height - 1);
    final r = (top.r + (bottom.r - top.r) * t).round();
    final g = (top.g + (bottom.g - top.g) * t).round();
    final b = (top.b + (bottom.b - top.b) * t).round();
    for (var x = 0; x < img.width; x++) {
      img.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

ColorRgb8 gradientColorAt(int y, ColorRgb8 top, ColorRgb8 bottom) {
  final t = y / (size - 1);
  return ColorRgb8(
    (top.r + (bottom.r - top.r) * t).round(),
    (top.g + (bottom.g - top.g) * t).round(),
    (top.b + (bottom.b - top.b) * t).round(),
  );
}

Image buildBaseIcon({required bool dark}) {
  final img = Image(width: size, height: size, numChannels: 4);
  final top = dark ? plumTop : coralTop;
  final bottom = dark ? navyBottom : goldBottom;

  verticalGradient(img, top, bottom);

  // The receipt: a tall cream card, centered, with a torn/zigzag bottom
  // edge — the single most universal "this app is about purchases" glyph.
  const receiptW = 460;
  const receiptH = 620;
  const receiptX = (size - receiptW) ~/ 2;
  const receiptY = 220;
  const receiptBottom = receiptY + receiptH;

  fillRect(
    img,
    x1: receiptX,
    y1: receiptY,
    x2: receiptX + receiptW,
    y2: receiptBottom,
    color: receiptCream,
    radius: 28,
  );

  // Zigzag: carve triangular notches out of the bottom edge using the
  // background color sampled at that height, so the receipt reads as torn
  // off a roll rather than a plain rounded card.
  const teeth = 8;
  const toothW = receiptW / teeth;
  const notchDepth = 26;
  final notchColor = gradientColorAt(receiptBottom, top, bottom);
  for (var i = 0; i < teeth; i++) {
    final xLeft = receiptX + i * toothW;
    final xRight = receiptX + (i + 1) * toothW;
    fillPolygon(
      img,
      vertices: [
        Point(xLeft, receiptBottom + 2),
        Point(xRight, receiptBottom + 2),
        Point(xLeft + toothW / 2, receiptBottom - notchDepth),
      ],
      color: notchColor,
    );
  }

  // Line items: a couple of muted bars suggest itemized entries; one
  // accent-colored bar near the bottom reads as the highlighted total.
  void bar(int y, double widthFraction, ColorRgb8 color, int height) {
    fillRect(
      img,
      x1: receiptX + 48,
      y1: y,
      x2: receiptX + 48 + (receiptW * widthFraction).round(),
      y2: y + height,
      color: color,
      radius: (height / 2).floor(),
    );
  }

  bar(receiptY + 110, 0.58, lineMuted, 26);
  bar(receiptY + 172, 0.42, lineMuted, 26);
  bar(receiptBottom - 150, 0.50, lineAccent, 32);

  // Coin peeking over the receipt's top-right corner.
  const coinCx = receiptX + receiptW - 30;
  const coinCy = receiptY + 10;
  fillCircle(
    img,
    x: coinCx,
    y: coinCy,
    radius: 108,
    color: coinGoldDark,
    antialias: true,
  );
  fillCircle(
    img,
    x: coinCx,
    y: coinCy,
    radius: 92,
    color: coinGold,
    antialias: true,
  );
  fillCircle(
    img,
    x: coinCx - 26,
    y: coinCy - 26,
    radius: 24,
    color: coinGoldLight,
    antialias: true,
  );

  return img;
}

Image addDevRibbon(Image base) {
  final out = base.clone();

  // A straight band rotated -20 degrees across the lower third of the icon.
  const bandWidth = 190.0;
  const angleDegrees = -20.0;
  const angle = angleDegrees * math.pi / 180;
  const bandCenterY = size * 0.74;
  const length = size * 1.6;

  Point rotated(double lx, double ly) {
    final x = lx * math.cos(angle) - ly * math.sin(angle);
    final y = lx * math.sin(angle) + ly * math.cos(angle);
    return Point(size / 2 + x, bandCenterY + y);
  }

  final band = [
    rotated(-length / 2, -bandWidth / 2),
    rotated(length / 2, -bandWidth / 2),
    rotated(length / 2, bandWidth / 2),
    rotated(-length / 2, bandWidth / 2),
  ];
  fillPolygon(out, vertices: band, color: devBannerBg);

  // "DEV" text, drawn larger via a small canvas scaled up.
  final textLayer = Image(width: 300, height: 90, numChannels: 4);
  drawString(textLayer, 'DEV', font: arial48, color: devBannerText);
  final scaledText = copyResize(textLayer, width: 480, height: 144);

  final destX = (size - scaledText.width) ~/ 2;
  final destY = bandCenterY.round() - scaledText.height ~/ 2;
  compositeImage(out, scaledText, dstX: destX, dstY: destY);

  return out;
}

void writePng(Image img, String path) {
  File(path).writeAsBytesSync(encodePng(img));
  stdout.writeln('Wrote $path');
}

void main() {
  final light = buildBaseIcon(dark: false);
  final dark = buildBaseIcon(dark: true);
  final lightDev = addDevRibbon(light);
  final darkDev = addDevRibbon(dark);

  Directory('assets/icon').createSync(recursive: true);
  writePng(light, 'assets/icon/icon_light.png');
  writePng(dark, 'assets/icon/icon_dark.png');
  writePng(lightDev, 'assets/icon/icon_light_dev.png');
  writePng(darkDev, 'assets/icon/icon_dark_dev.png');
}

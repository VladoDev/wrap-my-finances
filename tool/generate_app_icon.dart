// Throwaway asset-generation script — not part of the shipped app.
// Run once with `dart run tool/generate_app_icon.dart`, then safe to delete;
// its output (assets/icon/*.png) is what actually gets committed and wired
// via flavorizr.yaml.
//
// Design: a wrapped-gift wallet — a wallet (finances) with a ribbon bow
// across it (the "Wrapped" feature) and a peeking coin, in the product's
// Modern Playful palette. Same motif for dev/prod; dev adds a diagonal
// "DEV" ribbon banner. Light and dark background variants are generated for
// both.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const int size = 1024;

// Palette
final ColorRgb8 coralTop = ColorRgb8(255, 138, 101); // #FF8A65
final ColorRgb8 goldBottom = ColorRgb8(255, 183, 77); // #FFB74D
final ColorRgb8 plumTop = ColorRgb8(74, 37, 69); // #4A2545
final ColorRgb8 navyBottom = ColorRgb8(36, 27, 78); // #241B4E

final ColorRgb8 walletCream = ColorRgb8(255, 248, 240); // #FFF8F0
final ColorRgb8 walletCreamShadow = ColorRgb8(235, 222, 208); // #EBDED0
final ColorRgb8 ribbonCoral = ColorRgb8(232, 93, 75); // #E85D4B
final ColorRgb8 ribbonCoralDark = ColorRgb8(200, 70, 55); // #C84637
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

Image buildBaseIcon({required bool dark}) {
  final img = Image(width: size, height: size, numChannels: 4);

  verticalGradient(
    img,
    dark ? plumTop : coralTop,
    dark ? navyBottom : goldBottom,
  );

  // Wallet body (drop shadow + body) — centered, filling most of the frame
  // with room left above for the bow and coin.
  const walletW = 680;
  const walletH = 480;
  const walletX = (size - walletW) ~/ 2;
  const walletY = 400;

  fillRect(
    img,
    x1: walletX + 14,
    y1: walletY + 18,
    x2: walletX + walletW + 14,
    y2: walletY + walletH + 18,
    color: walletCreamShadow,
    radius: 56,
  );
  fillRect(
    img,
    x1: walletX,
    y1: walletY,
    x2: walletX + walletW,
    y2: walletY + walletH,
    color: walletCream,
    radius: 56,
  );

  // Wallet flap — the top third, slightly darker, with a rounded bottom
  // edge suggested by a second, shorter rounded rect.
  fillRect(
    img,
    x1: walletX,
    y1: walletY,
    x2: walletX + walletW,
    y2: walletY + (walletH * 0.42).round(),
    color: walletCreamShadow,
    radius: 56,
  );
  // Snap button on the flap.
  fillCircle(
    img,
    x: size ~/ 2,
    y: walletY + (walletH * 0.42).round(),
    radius: 14,
    color: coinGoldDark,
    antialias: true,
  );

  // Coin peeking from the top-right of the wallet.
  const coinCx = walletX + walletW - 90;
  const coinCy = walletY - 20;
  fillCircle(
    img,
    x: coinCx,
    y: coinCy,
    radius: 116,
    color: coinGoldDark,
    antialias: true,
  );
  fillCircle(
    img,
    x: coinCx,
    y: coinCy,
    radius: 100,
    color: coinGold,
    antialias: true,
  );
  fillCircle(
    img,
    x: coinCx - 30,
    y: coinCy - 30,
    radius: 26,
    color: coinGoldLight,
    antialias: true,
  );

  // Ribbon bow across the wallet: two loops + center knot + two tails.
  const cx = size / 2;
  const cy = walletY + 24.0;

  Image drawLoop(Image target, double dx) {
    final vertices = [
      Point(cx, cy),
      Point(cx + dx * 48, cy - 108),
      Point(cx + dx * 228, cy - 84),
      Point(cx + dx * 240, cy + 36),
      Point(cx + dx * 108, cy + 66),
    ];
    return fillPolygon(target, vertices: vertices, color: ribbonCoral);
  }

  var out = img;
  out = drawLoop(out, -1);
  out = drawLoop(out, 1);
  out = fillPolygon(
    out,
    vertices: [
      Point(cx - 31, cy + 36),
      Point(cx + 31, cy + 36),
      Point(cx + 48, cy + 264),
      Point(cx, cy + 228),
      Point(cx - 48, cy + 264),
    ],
    color: ribbonCoralDark,
  );
  out = fillCircle(
    out,
    x: cx.round(),
    y: cy.round(),
    radius: 41,
    color: ribbonCoralDark,
    antialias: true,
  );

  return out;
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

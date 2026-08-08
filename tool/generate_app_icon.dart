// Throwaway asset-generation script — not part of the shipped app.
// Run once with `dart run tool/generate_app_icon.dart`, then safe to delete;
// its output (assets/icon/*.png) is what actually gets committed and wired
// via flavorizr.yaml.
//
// Design: a minimalist flat-outline piggy bank with a coin dropping into
// the slot — the single most universal "savings / track your money" glyph,
// on a mint-to-teal gradient. Same motif for dev/prod; dev adds a diagonal
// "DEV" ribbon banner. Light and dark background variants are generated for
// both.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const int size = 1024;

// Background gradient
final ColorRgb8 mintTop = ColorRgb8(146, 217, 176); // #92D9B0
final ColorRgb8 tealBottom = ColorRgb8(58, 181, 196); // #3AB5C4
final ColorRgb8 deepTealTop = ColorRgb8(19, 78, 74); // #134E4A
final ColorRgb8 deepNavyBottom = ColorRgb8(18, 38, 58); // #12263A

// Piggy bank
final ColorRgb8 outline = ColorRgb8(35, 55, 60); // #23373C
final ColorRgb8 pigCream = ColorRgb8(255, 250, 245); // #FFFAF5
final ColorRgb8 snoutShade = ColorRgb8(214, 230, 232); // #D6E6E8

// Coin
final ColorRgb8 coinGold = ColorRgb8(247, 191, 76); // #F7BF4C
final ColorRgb8 coinGoldDark = ColorRgb8(214, 155, 40); // #D69B28

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

void fillEllipse(
  Image img, {
  required double cx,
  required double cy,
  required double rx,
  required double ry,
  required ColorRgb8 color,
}) {
  final x0 = (cx - rx).floor().clamp(0, img.width - 1);
  final x1 = (cx + rx).ceil().clamp(0, img.width - 1);
  final y0 = (cy - ry).floor().clamp(0, img.height - 1);
  final y1 = (cy + ry).ceil().clamp(0, img.height - 1);
  for (var y = y0; y <= y1; y++) {
    final ny = (y - cy) / ry;
    for (var x = x0; x <= x1; x++) {
      final nx = (x - cx) / rx;
      if (nx * nx + ny * ny <= 1.0) {
        img.setPixelRgba(x, y, color.r, color.g, color.b, 255);
      }
    }
  }
}

void outlinedEllipse(
  Image img, {
  required double cx,
  required double cy,
  required double rx,
  required double ry,
  required double strokeWidth,
  required ColorRgb8 strokeColor,
  required ColorRgb8 fillColor,
}) {
  fillEllipse(
    img,
    cx: cx,
    cy: cy,
    rx: rx + strokeWidth,
    ry: ry + strokeWidth,
    color: strokeColor,
  );
  fillEllipse(img, cx: cx, cy: cy, rx: rx, ry: ry, color: fillColor);
}

void arrowHead(
  Image img,
  double tipX,
  double tipY,
  double dirX,
  double dirY,
  double length,
  double width,
  ColorRgb8 color,
) {
  final len = math.sqrt(dirX * dirX + dirY * dirY);
  final ux = dirX / len;
  final uy = dirY / len;
  final px = -uy;
  final py = ux;
  final backX = tipX - ux * length;
  final backY = tipY - uy * length;
  fillPolygon(
    img,
    vertices: [
      Point(tipX, tipY),
      Point(backX + px * width, backY + py * width),
      Point(backX - px * width, backY - py * width),
    ],
    color: color,
  );
}

void thickLine(
  Image img,
  double x1,
  double y1,
  double x2,
  double y2,
  double thickness,
  ColorRgb8 color,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = math.sqrt(dx * dx + dy * dy);
  final ux = -dy / len * thickness / 2;
  final uy = dx / len * thickness / 2;
  fillPolygon(
    img,
    vertices: [
      Point(x1 + ux, y1 + uy),
      Point(x2 + ux, y2 + uy),
      Point(x2 - ux, y2 - uy),
      Point(x1 - ux, y1 - uy),
    ],
    color: color,
  );
}

Image buildBaseIcon({required bool dark}) {
  final img = Image(width: size, height: size, numChannels: 4);
  final top = dark ? deepTealTop : mintTop;
  final bottom = dark ? deepNavyBottom : tealBottom;

  verticalGradient(img, top, bottom);

  // Body + head: two overlapping outlined ellipses in the same colors so
  // the overlap disappears and they read as one continuous silhouette.
  const bodyCx = 580.0;
  const bodyCy = 660.0;
  const bodyRx = 270.0;
  const bodyRy = 210.0;
  const headCx = 340.0;
  const headCy = 630.0;
  const headRx = 150.0;
  const headRy = 140.0;
  const strokeW = 14.0;

  fillEllipse(
    img,
    cx: bodyCx,
    cy: bodyCy,
    rx: bodyRx + strokeW,
    ry: bodyRy + strokeW,
    color: outline,
  );
  fillEllipse(
    img,
    cx: headCx,
    cy: headCy,
    rx: headRx + strokeW,
    ry: headRy + strokeW,
    color: outline,
  );
  fillEllipse(
    img,
    cx: bodyCx,
    cy: bodyCy,
    rx: bodyRx,
    ry: bodyRy,
    color: pigCream,
  );
  fillEllipse(
    img,
    cx: headCx,
    cy: headCy,
    rx: headRx,
    ry: headRy,
    color: pigCream,
  );

  // Snout: its own outlined ellipse in a slightly cooler shade so it reads
  // as a distinct feature rather than merging into the head.
  const snoutCx = 195.0;
  const snoutCy = 655.0;
  outlinedEllipse(
    img,
    cx: snoutCx,
    cy: snoutCy,
    rx: 95,
    ry: 72,
    strokeWidth: 12,
    strokeColor: outline,
    fillColor: snoutShade,
  );
  fillEllipse(
    img,
    cx: snoutCx - 45,
    cy: snoutCy - 18,
    rx: 9,
    ry: 9,
    color: outline,
  );
  fillEllipse(
    img,
    cx: snoutCx - 45,
    cy: snoutCy + 20,
    rx: 9,
    ry: 9,
    color: outline,
  );

  // Eye.
  fillEllipse(img, cx: 300, cy: 555, rx: 16, ry: 16, color: outline);

  // Ear: a simple solid triangle above the head.
  fillPolygon(
    img,
    vertices: [
      Point(275, 475),
      Point(345, 415),
      Point(375, 505),
    ],
    color: outline,
  );

  // Tail: a small open loop on the back of the body.
  const tailCx = 838.0;
  const tailCy = 545.0;
  fillEllipse(img, cx: tailCx, cy: tailCy, rx: 46, ry: 46, color: outline);
  fillEllipse(
    img,
    cx: tailCx,
    cy: tailCy,
    rx: 26,
    ry: 26,
    color: gradientColorAt(tailCy.round(), top, bottom),
  );

  // Coin slot on top of the body.
  fillRect(
    img,
    x1: 545,
    y1: 438,
    x2: 655,
    y2: 462,
    color: outline,
    radius: 12,
  );

  // Legs: four outlined rounded rectangles under the body.
  void leg(double cx) {
    const legW = 56.0;
    const legTop = 828.0;
    const legBottom = 918.0;
    const inset = 10.0;
    fillRect(
      img,
      x1: (cx - legW / 2).round(),
      y1: legTop.round(),
      x2: (cx + legW / 2).round(),
      y2: legBottom.round(),
      color: outline,
      radius: 16,
    );
    fillRect(
      img,
      x1: (cx - legW / 2 + inset).round(),
      y1: (legTop + inset).round(),
      x2: (cx + legW / 2 - inset).round(),
      y2: legBottom.round(),
      color: pigCream,
      radius: 10,
    );
  }

  leg(430);
  leg(525);
  leg(650);
  leg(742);

  // Ground line + growth arrow.
  fillRect(img, x1: 150, y1: 900, x2: 790, y2: 914, color: outline, radius: 7);
  thickLine(img, 160, 922, 226, 844, 16, outline);
  arrowHead(img, 232, 838, 72, -84, 46, 26, outline);

  // Coin dropping into the slot, with a $ mark and motion lines above it.
  const coinCx = 615.0;
  const coinCy = 330.0;
  fillEllipse(img, cx: coinCx, cy: coinCy, rx: 107, ry: 107, color: outline);
  fillEllipse(img, cx: coinCx, cy: coinCy, rx: 95, ry: 95, color: coinGoldDark);
  fillEllipse(img, cx: coinCx, cy: coinCy, rx: 81, ry: 81, color: coinGold);

  final textLayer = Image(width: 120, height: 120, numChannels: 4);
  drawString(textLayer, r'$', font: arial48, color: outline);
  final scaledText = copyResize(textLayer, width: 150, height: 150);
  compositeImage(
    img,
    scaledText,
    dstX: coinCx.round() - scaledText.width ~/ 2,
    dstY: coinCy.round() - scaledText.height ~/ 2,
  );

  void motionLine(double cx, int h) {
    fillRect(
      img,
      x1: (cx - 9).round(),
      y1: 150,
      x2: (cx + 9).round(),
      y2: 150 + h,
      color: pigCream,
      radius: 9,
    );
  }

  motionLine(560, 55);
  motionLine(615, 75);
  motionLine(670, 55);

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

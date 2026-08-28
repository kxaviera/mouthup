import 'package:flutter/material.dart';

/// Deterministic pixel avatar data derived from a username.
class AvatarGenerator {
  AvatarGenerator._();

  static const _grid = 5;

  static int _hash(String input) {
    var h = 0;
    for (var i = 0; i < input.length; i++) {
      h = input.codeUnitAt(i) + ((h << 5) - h);
    }
    return h;
  }

  /// 5×5 symmetric pixel mask — same username always yields the same shape.
  static List<List<bool>> pixelMask(String name) {
    final hash = _hash(name.toLowerCase().trim());
    final grid = List.generate(_grid, (_) => List.filled(_grid, false));

    for (var y = 0; y < _grid; y++) {
      for (var x = 0; x < (_grid / 2).ceil(); x++) {
        final bit = (hash >> (y * 3 + x)) & 1;
        grid[y][x] = bit == 1;
        grid[y][_grid - 1 - x] = bit == 1;
      }
    }
    return grid;
  }

  static Color backgroundColor(String name) {
    final h = _hash('bg:$name').abs();
    return HSLColor.fromAHSL(1, (h % 360).toDouble(), 0.38, 0.14).toColor();
  }

  static Color pixelColor(String name) {
    final h = _hash('px:$name').abs();
    return HSLColor.fromAHSL(1, ((h % 360) + 40) % 360, 0.58, 0.68).toColor();
  }

  static Color accentColor(String name) {
    final h = _hash('ac:$name').abs();
    return HSLColor.fromAHSL(1, ((h % 360) + 180) % 360, 0.48, 0.52).toColor();
  }
}

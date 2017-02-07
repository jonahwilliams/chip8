import 'dart:typed_data';
import 'dart:html';

import '../modules/screen_module.dart';

class CanvasScreen implements ScreenModule {
  final _buffer = new Uint8List(2048);
  final CanvasRenderingContext2D _context;
  final int _scale;
  final width = 32;
  final height = 64;

  factory CanvasScreen(String id, int scale) {
    final root = document.getElementById(id);
    final canvas = new CanvasElement(width: 32 * scale, height: 64 * scale);
    root.append(canvas);
    final ctx = canvas.getContext('2d');
    return new CanvasScreen._(ctx, scale);
  }

  CanvasScreen._(this._context, this._scale) {
    _context.fillStyle = 'black';
  }

  void clear() {
    for (int i = 0; i < _buffer.length; i++) {
      _buffer[i] = 0;
    }
    _context.clearRect(0, 0, width * _scale, height * _scale);
  }

  void draw() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (getPixel(x, y)) {
          _context.rect(x * _scale, y * _scale, _scale, _scale);
        } else {
          _context.clearRect(x * _scale, y * _scale, _scale, _scale);
        }
      }
    }
  }

  bool setPixel(int x, int y) {
    _buffer[y * height + x] ^= 1;
    return _buffer[y * height + x] == 1;
  }

  bool getPixel(int x, int y) => _buffer[y * height + x] == 1;
}

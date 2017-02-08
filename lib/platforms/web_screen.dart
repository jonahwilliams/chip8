import 'dart:typed_data';
import 'dart:html';

import '../modules/screen_module.dart';

class CanvasScreen implements ScreenModule {
  final _buffer = new Uint8List(2048);
  final CanvasRenderingContext2D _context;
  final ImageData _rawBuffer;

  final width = 64;
  final height = 32;

  factory CanvasScreen(String id) {
    final root = document.getElementById(id);
    final canvas = new CanvasElement(width: 64, height: 32)
      ..style.imageRendering = 'pixelated'
      ..style.height = '${32 * 10}px'
      ..style.width = '${64 * 10}px';
    root.append(canvas);
    final CanvasRenderingContext2D ctx = canvas.getContext('2d');
    ctx.imageSmoothingEnabled = false;
    return new CanvasScreen._(ctx, ctx.getImageData(0, 0, 64, 32));
  }

  CanvasScreen._(this._context, this._rawBuffer) {
    _context.fillStyle = 'black';
  }

  void clear() {
    for (int i = 0; i < _buffer.length; i++) {
      _buffer[i] = 0;
    }
  }

  void drawLoop() {
    draw();
    window.requestAnimationFrame((_) => drawLoop());
  }

  void draw() {
    for (int i = 0; i < _rawBuffer.data.length; i += 4) {
      _rawBuffer.data[i] = 1 | _buffer[i ~/ 4] * 255;
      _rawBuffer.data[i + 1] = 1 | _buffer[i ~/ 4] * 255;
      _rawBuffer.data[i + 2] = 1 | _buffer[i ~/ 4] * 255;
      _rawBuffer.data[i + 3] = 255;
    }
    _context.putImageData(_rawBuffer, 0, 0);
  }

  bool setPixel(int x, int y) {
    _buffer[(y * width) + x] ^= 1;
    return _buffer[(y * width) + x] == 1;
  }

  bool getPixel(int x, int y) {
    return _buffer[(y * width) + x] == 1;
  }
}

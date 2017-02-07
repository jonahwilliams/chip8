import 'dart:html';

import '../modules/input_module.dart';

const keyMap = const <int, int>{
  49: 0x1, // 1
  50: 0x2, // 2
  51: 0x3, // 3
  52: 0xC, // 4
  113: 0x04, // Q
  119: 0x05, // W
  101: 0x06, // E
  114: 0x0D, // R
  97: 0x07, // A
  115: 0x08, // S
  100: 0x09, // D
  102: 0x0E, // F
  122: 0x0A, // Z
  120: 0x00, // X
  99: 0x0B, // C
  118: 0x0F, // V
};

class WebInput implements InputModule {
  int _keyCode = 36;

  WebInput() {
    document.body.onKeyPress.listen((event) {
      final key = event.charCode;
      final code = keyMap[key];
      if (code != null) {
        _keyCode = code;
      }
    });
  }

  int get keyCode => _keyCode;

  void clear() {
    _keyCode = 36;
  }
}

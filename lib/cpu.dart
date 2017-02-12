import 'dart:typed_data';
import 'dart:math';
import 'dart:async';

import 'modules/screen_module.dart';
import 'modules/sound_module.dart';
import 'modules/input_module.dart';

const fontSet = const <int>[
  0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
  0x20, 0x60, 0x20, 0x20, 0x70, // 1
  0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
  0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
  0x90, 0x90, 0xF0, 0x10, 0x10, // 4
  0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
  0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
  0xF0, 0x10, 0x20, 0x40, 0x40, // 7
  0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
  0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
  0xF0, 0x90, 0xF0, 0x90, 0x90, // A
  0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
  0xF0, 0x80, 0x80, 0x80, 0xF0, // C
  0xE0, 0x90, 0x90, 0x90, 0xE0, // D
  0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
  0xF0, 0x80, 0xF0, 0x80, 0x80 // F
];

/// The Chip-8
class Cpu {
  final Uint8List vRegisters = new Uint8List(16);
  final Uint8List memory = new Uint8List(4096);
  final List<int> stack = <int>[];
  final InputModule input;
  final ScreenModule screen;
  final SoundModule sound;
  final Random rand;

  var soundTimer = 0x0;
  var delayTimer = 0x0;
  var iRegister = 0x0;
  var programCounter = 0x200;
  var drawFlag = false;
  var currentInput = null;

  Cpu(this.rand, this.screen, this.input, this.sound) {
    // Load font set.
    for (var i = 0, length = fontSet.length; i < length; i++) {
      memory[i] = fontSet[i];
    }
    // begin draw loop
    screen.drawLoop();

    new Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (soundTimer > 0) soundTimer--;
      if (delayTimer > 0) delayTimer--;
    });
  }
  void loop() {
    currentInput = input.keyCode;
    executeOpcode(opcode);
    if (drawFlag) {
      screen.drawFlag = true;
      drawFlag = false;
    }
  }

  void loadProgram(List<int> buffer) {
    for (int i = 0; i < buffer.length; i++) {
      memory[0x200 + i] = buffer[i];
    }
  }

  String toDebugString() {
    final buffer = new StringBuffer();
    buffer.writeln(opcode.toRadixString(16));
    return buffer.toString();
  }

  // fetch the current operation
  int get opcode => memory[programCounter] << 8 | memory[programCounter + 1];

  void executeOpcode(int code) {
    final x = (code & 0x0F00) >> 8;
    final y = (code & 0x00F0) >> 4;
    programCounter += 2;
    switch (code >> 12) {
      case 0x0:
        switch (code & 0xFFF) {
          case 0x0E0:
            screen.clear();
            break;
          case 0x0EE:
            programCounter = stack.removeLast();
            break;
          default:
            print('ERROR: unknown code ${code.toRadixString(16)}');
        }
        break;
      case 0x1:
        programCounter = code & 0x0FFF;
        break;
      case 0x2:
        stack.add(programCounter);
        programCounter = code & 0x0FFF;
        break;
      case 0x3:
        if (vRegisters[x] == (code & 0x00FF)) {
          programCounter += 2;
        }
        break;
      case 0x4:
        if (vRegisters[x] !=  (code & 0x00FF)) {
          programCounter += 2;
        }
        break;
      case 0x5:
        if (vRegisters[x] == vRegisters[y]) {
          programCounter += 2;
        }
        break;
      case 0x6:
        vRegisters[x] = code & 0xFF;
        break;
      case 0x7:
        vRegisters[x] += code & 0xFF;
        break;
      case 0x8:
        switch (code & 0xF) {
          case 0x0:
            vRegisters[x] = vRegisters[y];
            break;
          case 0x1:
            vRegisters[x] |= vRegisters[y];
            break;
          case 0x2:
            vRegisters[x] &= vRegisters[y];
            break;
          case 0x3:
            vRegisters[x] ^= vRegisters[y];
            break;
          case 0x4:
            final value = vRegisters[x] + vRegisters[y];
            vRegisters[x] = value;
            vRegisters[0xF] = value > 255 ? 1 : 0;
            break;
          case 0x5:
            vRegisters[0xF] = vRegisters[x] > vRegisters[y] ? 0 : 1;
            vRegisters[x] -= vRegisters[y];
            break;
          case 0x6:
            vRegisters[0xF] = vRegisters[x] & 0x1;
            vRegisters[x] >>= 1;
            break;
          case 0x7:
            vRegisters[0xF] = vRegisters[y] > vRegisters[x] ? 1 : 0;
            vRegisters[x] = vRegisters[y] - vRegisters[x];
            break;
          case 0xE:
            vRegisters[0xF] = vRegisters[x] >> 7;
            vRegisters[x] <<= 1;
            break;
          default:
            print('ERROR: unknown code ${code.toRadixString(16)}');
        }
        break;
      case 0x9:
        if (vRegisters[x] != vRegisters[y]) {
          programCounter += 2;
        }
        break;
      case 0xA:
        iRegister = code & 0x0FFF;
        break;
      case 0xB:
        programCounter = (0x0FFF & code) + vRegisters[0];
        break;
      case 0xC:
        vRegisters[x] = rand.nextInt(256) & (0x0FF & code);
        break;
      case 0xD:
        final h = code & 0x000F;
        final w = 8;
        final xx = vRegisters[x];
        final yy = vRegisters[y];
        vRegisters[0xF] = 0x0;

        for (int row = 0; row < h; row++) {
          int pixel = memory[iRegister + row];
          for (int col = 0; col < w; col++) {
            if ((pixel & 0x80) > 0) {
              if (screen.setPixel(xx + col, yy + row)) {
                vRegisters[0xF] = 0x1;
              }
            }
            pixel <<= 1;
          }
        }
        drawFlag = true;
        break;
      case 0xE:
        switch(code & 0xFF) {
          case 0x9E:
            if (currentInput == vRegisters[x]) {
              programCounter += 2;
            }
            break;
          case 0xA1:
            if (currentInput != vRegisters[x]) {
              programCounter += 2;
            }
            break;
          default:
          print('ERROR: unknown code ${code.toRadixString(16)}');
        }
        break;
      case 0xF:
        switch (code & 0x00FF) {
          case 0x0007:
            vRegisters[x] = delayTimer;
            break;
          case 0x000A:
            if (input.keyCode == null) {
              programCounter -= 2;
            } else {
              vRegisters[x] = currentInput;
            }
            break;
          case 0x0015:
            delayTimer = vRegisters[x];
            break;
          case 0x0018:
            soundTimer = vRegisters[x];
            break;
          case 0x001E:
            iRegister += vRegisters[x];
            break;
          case 0x0029:
            iRegister = vRegisters[x] * 5;
            break;
          case 0x0033:
            memory[iRegister] = vRegisters[x] ~/ 100;
            memory[iRegister + 1] = (vRegisters[x] ~/ 10) % 10;
            memory[iRegister + 2] = vRegisters[x] % 10;
            break;
          case 0x0055:
            for (int i = 0; i <= x; i++) {
              memory[iRegister + i] = vRegisters[i];
            }
            iRegister += x + 1;
            break;
          case 0x0065:
            for (int i = 0; i <= x; i++) {
              vRegisters[i] = memory[iRegister + i];
            }
            iRegister += x + 1;
            break;
          default:
            print('ERROR: unknown code ${code.toRadixString(16)}');
        }
        break;
      default:
        print('ERROR: unknown code ${code.toRadixString(16)}');
    }
  }
}

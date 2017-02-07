import 'dart:typed_data';
import 'dart:math';

import 'modules/screen_module.dart';
import 'modules/sound_module.dart';
import 'modules/timer_module.dart';
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

/// The Chip-8 cpu
///
/// http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
/// The chip-8 had 15 8 bit general purpose registers, named from
/// V0 to VE.  The 16th was the carry flag.
///
/// The is an index register and a program counter.
class Cpu {
  final Uint8List vRegisters = new Uint8List(16);
  final Uint8List memory = new Uint8List(4096);
  final Uint16List stack = new Uint16List(16);
  final InputModule input;
  final ScreenModule screen;
  final SoundModule sound;
  final DelayTimerModule delayTimer;
  final SoundTimerModule soundTimer;
  final Random rand;

  var iRegister = 0x0;
  var programCounter = 0x200;
  var stackPointer = 0x0;
  var drawFlag = false;
  var blockFlag = false;
  var currentInput = null;

  Cpu(this.rand, this.screen, this.input, this.sound, this.delayTimer,
      this.soundTimer) {
    // Load font set.
    for (var i = 0, length = fontSet.length; i < length; i++) {
      memory[i] = fontSet[i];
    }
    // attach soundModule to sound timer
    soundTimer.attach(sound);
  }
  void loop() {
    currentInput = input.keyCode;
    executeOpcode(opcode);
    if (drawFlag) {
      screen.draw();
      drawFlag = false;
    }
  }

  void loadProgram(Uint16List buffer) {
    for (int i = 0; i < buffer.length; i++) {
      memory[0x200 + i] = buffer[i];
    }
  }

  // fetch the current operation
  int get opcode => memory[programCounter] << 8 | memory[programCounter + 1];

  void executeOpcode(int code) {
    final left = code >> 12;
    final leftMiddle = (code >> 8) & 0xF;
    final rightMiddle = (code >> 4) & 0xF;
    final right = code & 0xF;
    loop:
    switch (left) {
      case 0x0:
        if (leftMiddle == 0x0 && rightMiddle == 0xE && right == 0x0) {
          // clear the screen.
          screen.clear();
          programCounter += 2;
        } else if (leftMiddle == 0x0 && rightMiddle == 0xE && right == 0xE) {
          // return from subroutine.
          programCounter = stack[stackPointer - 1];
          stackPointer--;
        } else {
          // Calls RCA 1802 program at address NNN
          iRegister = (leftMiddle << 8) | (rightMiddle << 4) | right;
          programCounter += 2;
        }
        break loop;
      case 0x1:
        // 	Jumps to address NNN.
        programCounter = code & 0x0FFF;
        break loop;
      case 0x2:
        // Calls subroutine at NNN.
        stack[stackPointer] = programCounter;
        stackPointer++;
        programCounter = code & 0x0FFF;
        break loop;
      case 0x3:
        // Skips the next instruction if VX equals NN.
        programCounter += vRegisters[leftMiddle] == (code & 0x00FF) ? 4 : 2;
        break loop;
      case 0x4:
        // Skips the next instruction if VX doesn't equal NN.
        programCounter += vRegisters[leftMiddle] != (code & 0x00FF) ? 4 : 2;
        break loop;
      case 0x5:
        // Skips the next instruction if VX equals VY.
        programCounter +=
            vRegisters[leftMiddle] == vRegisters[rightMiddle] ? 4 : 2;
        break loop;
      case 0x6:
        // Sets VX to NN
        vRegisters[leftMiddle] = rightMiddle << 4 | right;
        programCounter += 2;
        break loop;
      case 0x7:
        // Adds NN to VX
        vRegisters[leftMiddle] =
            vRegisters[leftMiddle] + ((rightMiddle << 4) | right);
        programCounter += 2;
        break loop;
      case 0x8:
        switch (right) {
          case 0x0:
            // Assign Vx to the value of Vy.
            vRegisters[leftMiddle] = vRegisters[rightMiddle];
            programCounter += 2;
            break loop;
          case 0x1:
            // Set Vx to Vx | Vy.
            vRegisters[leftMiddle] =
                vRegisters[leftMiddle] | vRegisters[rightMiddle];
            programCounter += 2;
            break loop;
          case 0x2:
            // Set Vx to Vx & Vy.
            vRegisters[leftMiddle] =
                vRegisters[leftMiddle] & vRegisters[rightMiddle];
            programCounter += 2;
            break loop;
          case 0x3:
            // Set Vx to Vx ^ Vy.
            vRegisters[leftMiddle] =
                vRegisters[leftMiddle] ^ vRegisters[rightMiddle];
            programCounter += 2;
            break loop;
          case 0x4:
            // Adds VY to VX.
            // VF is set to 1 when there's a carry, and to 0 when there isn't.
            final value = vRegisters[leftMiddle] + vRegisters[rightMiddle];
            vRegisters[leftMiddle] = value;
            vRegisters[0xF] = value > 255 ? 1 : 0;
            programCounter += 2;
            break loop;
          case 0x5:
            // Set Vx to VY subtraced from VX.
            // VF is set to 0 when there's a borrow, and 1 when there isn't.
            final value = vRegisters[leftMiddle] - vRegisters[rightMiddle];
            vRegisters[leftMiddle] = value < 0 ? (value + 0xFF) : value;
            vRegisters[15] = value < 0 ? 1 : 0;
            programCounter += 2;
            break loop;
          case 0x6:
            // Shifts VX right by one.
            // VF is set to the value of the least significant bit of VX before the shift.
            final value = vRegisters[leftMiddle];
            vRegisters[15] = value & -value;
            vRegisters[leftMiddle] = value >> 1;
            programCounter += 2;
            break loop;
          case 0x7:
            // Sets VX to VY minus VX.
            // VF is set to 0 when there's a borrow, and 1 when there isn't.
            final value = vRegisters[rightMiddle] - vRegisters[leftMiddle];
            vRegisters[leftMiddle] = value < 0 ? (value + 0xFF) : value;
            vRegisters[15] = value < 0 ? 0 : 1;
            programCounter += 2;
            break loop;
          case 0xE:
            // Shifts VX left by one.
            // VF is set to the value of the most significant bit of VX before
            // the shift.
            final value = vRegisters[leftMiddle];
            vRegisters[15] = flp2(value);
            vRegisters[leftMiddle] = (value << 1) & 0xFF;
            programCounter += 2;
            break loop;
          default:
            print('ERROR: unknown code $code');
        }
        break loop;
      case 0x9:
        programCounter +=
            vRegisters[leftMiddle] != vRegisters[rightMiddle] ? 4 : 2;
        break loop;
      case 0xA:
        // Set the iRegister to the value in the opcode.
        iRegister = code & 0x0FFF;
        programCounter += 2;
        break loop;
      case 0xB:
        programCounter = (0x0FFF & code) + vRegisters[0];
        break loop;
      case 0xC:
        vRegisters[leftMiddle] = rand.nextInt(256) & (0x00F & code);
        programCounter += 2;
        break loop;
      case 0xD:
        // 0xDXYN
        // Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels
        // and a height of N pixels. Each row of 8 pixels is read as bit-coded
        // starting from memory location I; I value doesn’t change after the
        // execution of this instruction. As described above, VF is set to 1
        // if any screen pixels are flipped from set to unset when the sprite
        // is drawn, and to 0 if that doesn’t happen.
        final x = vRegisters[leftMiddle];
        final y = vRegisters[rightMiddle];
        final h = code & 0x000F;
        final w = 8;

        vRegisters[0xF] = 0x0;

        for (int row = 0; row < h; row++) {
          int pixel = memory[iRegister + row];
          for (int col = 0; col < w; col++) {
            if ((pixel & 0x80) > 0) {
              if (screen.setPixel(x + col, y + row)) {
                vRegisters[0xF] = 0x1;
              }
            }
            pixel = pixel << 1;
          }
        }
        drawFlag = true;
        programCounter += 2;
        break loop;
      case 0xE:
        if ((code & 0xFF) == 0x9E) {
          // Skips the next instruction if the key stored in VX is pressed
          programCounter += (vRegisters[leftMiddle] == currentInput)  ? 4 : 2;
        } else if ((code & 0xFF) == 0x0A) {
          // Skips the next instruction if the key stored in VX isn't pressed.
          programCounter += (vRegisters[leftMiddle]  == currentInput) ? 4 : 2;
        } else {
          print('ERROR: unknown code $code');
        }
        break loop;
      case 0xF:
        switch (code & 0x00FF) {
          case 0x0007:
            vRegisters[leftMiddle] = delayTimer.time;
            programCounter += 2;
            break loop;
          case 0x000A:
            if (input.keyCode == null) {
              break loop;
            } else {
              vRegisters[leftMiddle] = currentInput;
              programCounter += 2;
            }
            break loop;
          case 0x0015:
            delayTimer.time = vRegisters[leftMiddle];
            programCounter += 2;
            break loop;
          case 0x0018:
            soundTimer.time = vRegisters[leftMiddle];
            programCounter += 2;
            break loop;
          case 0x001E:
            // Adds VX to I
            iRegister += vRegisters[leftMiddle];
            programCounter += 2;
            break loop;
          case 0x0029:
            // Sets I to the location of the sprite for the character in VX.
            // Characters 0-F (in hexadecimal) are represented by a 4x5 font.
            vRegisters[0xF] =
                (iRegister + vRegisters[leftMiddle] > 0xfff) ? 1 : 0;
            iRegister = iRegister + vRegisters[leftMiddle];
            programCounter += 2;
            break loop;
          case 0x0033:
            memory[iRegister] = vRegisters[(code & 0x0F00) >> 8] ~/ 100;
            memory[iRegister + 1] =
                (vRegisters[(code & 0x0F00) >> 8] ~/ 10) % 10;
            memory[iRegister + 2] =
                (vRegisters[(code & 0x0F00) >> 8] % 100) % 10;
            programCounter += 2;
            break loop;
          case 0x0055:
            for (int i = 0; i <= leftMiddle; i++) {
              memory[iRegister + i] = vRegisters[i];
            }
            programCounter += 2;
            break loop;
          case 0x0065:
            for (int i = 0; i <= leftMiddle; i++) {
              vRegisters[i] = memory[iRegister + i];
            }
            programCounter += 2;
            break loop;
          default:
            print('ERROR: unknown code $code');
            break loop;
        }
        break loop;
      default:
        print('ERROR: unknown code $code');
    }
  }
}

/// Most significant bit
int flp2(int x) {
  x |= (x >> 1);
  x |= (x >> 2);
  x |= (x >> 4);
  x |= (x >> 8);
  x |= (x >> 16);
  return x - (x >> 1);
}

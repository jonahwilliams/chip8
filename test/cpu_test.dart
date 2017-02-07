import 'dart:typed_data';
import 'dart:math';

import 'package:test/test.dart';
import 'package:chip8/cpu.dart';
import 'package:chip8/modules/screen_module.dart';
import 'package:chip8/modules/sound_module.dart';
import 'package:chip8/modules/timer_module.dart';
import 'package:chip8/modules/input_module.dart';

class TestScreen implements ScreenModule {
  final int height = 64;
  final int width = 32;
  void clear() {}
  void draw() {}
  bool setPixel(int x, int y) => false;
  bool getPixel(int x, int y) => false;
}

class TestInput implements InputModule {
  int keyCode = 30;

  bool keyPressed(int key) => key == keyCode;

  void clear() {}
}

class TestSound implements SoundModule {
  void play() {}
}

class TestDelayTimer implements DelayTimerModule {
  int time = 0;
}

class TestSoundTimer implements SoundTimerModule {
  SoundModule _sound;
  int time = 0;

  void attach(SoundModule sound) {
    _sound = sound;
  }
}

void main() {
  group('CPU Opcode', () {
    Cpu cpu;
    Random random;
    TestInput input;
    ScreenModule screen;
    SoundModule sound;
    DelayTimerModule delayTimer;
    SoundTimerModule soundTimer;

    setUp(() {
      random = new Random(0);
      screen = new TestScreen();
      sound = new TestSound();
      input = new TestInput();
      delayTimer = new TestDelayTimer();
      soundTimer = new TestSoundTimer();
      cpu = new Cpu(random, screen, input, sound, delayTimer, soundTimer);
    });

    void load(List<int> codes) {
      cpu.loadProgram(new Uint16List.fromList(codes));
    }

    void press(int keyCode) {
      input.keyCode = keyCode;
    }

    void run(int cycles) {
      while (cycles > 0) {
        cpu.loop();
        cycles--;
      }
    }

    group('0x0 series', () {});

    group('0x1 series', () {
      test('0x1nnn jumps to location nnn', () {
        load([0x11, 0x11]);
        run(1);

        expect(cpu.programCounter, 0x111);
      });
    });
    group('0x2 series', () {
      test('0x2nnn call subroutine at nnn and increment stack pointer', () {
        load([0x21, 0x11]);
        run(1);

        expect(cpu.programCounter, 0x111);
        expect(cpu.stackPointer, 0x1);
        expect(cpu.stack[0], 0x200);
      });
    });
    group('0x3 series', () {
      test('0x3xkk skips the next instruction if Vx == kk', () {
        cpu.vRegisters[0x1] = 13;

        load([0x31, 0x0D]);
        run(1);

        expect(cpu.programCounter, 0x204);
      });
      test('0x3xkk does not skip the next instruction if Vx != kk', () {
        cpu.vRegisters[0x1] = 13;

        load([0x31, 0x01]);
        run(1);

        expect(cpu.programCounter, 0x202);
      });
    });
    group('0x4 series', () {
      test('0x4xkk skips the next instruction if Vx != kk', () {
        cpu.vRegisters[0x0] = 7;

        load([0x40, 0x09]);
        run(1);

        expect(cpu.programCounter, 0x204);
      });
      test('0x4xkk does not skip the next instruction if Vx == kk', () {
        cpu.vRegisters[0x0] = 7;

        load([0x40, 0x07]);
        run(1);

        expect(cpu.programCounter, 0x202);
      });
    });
    group('0x5 series', () {
      test('0x5xy0 skips the next instruction if Vx == Vy', () {
        cpu.vRegisters[0x0] = 12;
        cpu.vRegisters[0x1] = 12;

        load([0x51, 0x00]);
        run(1);

        expect(cpu.programCounter, 0x204);
      });
       test('0x5xy0 does not skip the next instruction if Vx != Vy', () {
        cpu.vRegisters[0x0] = 12;
        cpu.vRegisters[0x1] = 2;

        load([0x51, 0x00]);
        run(1);

        expect(cpu.programCounter, 0x202);
      });
    });
    group('0x6 series', () {
      test('0x6xkk sets Vx to kk', () {
        cpu.vRegisters[0x1] = 12;

        load([0x61, 0x01]);
        run(1);

        expect(cpu.vRegisters[0x1], 1);
        expect(cpu.programCounter, 0x202);
      });
    });
    group('0x7 series', () {
      test('0x7xkk sets Vx to Vx + kk', () {
        cpu.vRegisters[0x1] = 12;

        load([0x71, 0x01]);
        run(1);

        expect(cpu.vRegisters[0x1], 13);
        expect(cpu.programCounter, 0x202);
      });
    });
    // Math and BitOps
    group('0x8 series', () {
      test('0x8XY0 sets the value of Vx to Vy', () {
        cpu.vRegisters[0x1] = 13;

        load([0x80, 0x10]);
        run(1);

        expect(cpu.vRegisters[0], 13);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY1 sets the value of Vx to Vx | Vy', () {
        cpu.vRegisters[0x1] = 13;
        cpu.vRegisters[0x0] = 6;

        load([0x80, 0x11]);
        run(1);

        expect(cpu.vRegisters[0], 15);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY2 sets the value of Vx to Vx & Vy', () {
        cpu.vRegisters[0x1] = 13;
        cpu.vRegisters[0x0] = 6;

        load([0x80, 0x12]);
        run(1);

        expect(cpu.vRegisters[0], 4);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY3 sets the value of Vx to Vx ^ Vy', () {
        cpu.vRegisters[0x1] = 13;
        cpu.vRegisters[0x0] = 6;

        load([0x80, 0x13]);
        run(1);

        expect(cpu.vRegisters[0], 11);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY4 sets the value of Vx to Vy + Vx and Vf to 1 if carry', () {
        cpu.vRegisters[0x1] = 244;
        cpu.vRegisters[0x0] = 35;

        load([0x80, 0x14]);
        run(1);

        // 244 + 35 mod 256 = 23;
        expect(cpu.vRegisters[0x0], 23);
        expect(cpu.vRegisters[0xF], 1);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY4 sets the value of Vx to Vy + Vx and Vf to 0 if no carry',
          () {
        cpu.vRegisters[0x1] = 22;
        cpu.vRegisters[0x0] = 35;

        load([0x80, 0x14]);
        run(1);

        expect(cpu.vRegisters[0x0], 57);
        expect(cpu.vRegisters[0xF], 0);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY5 sets the value of Vx to Vx - Vy and Vf = 0 if borrow', () {
        cpu.vRegisters[0x1] = 10;
        cpu.vRegisters[0x0] = 1;

        load([0x80, 0x15]);
        run(1);

        // 1 - 10 = -9 + 255 = 246
        expect(cpu.vRegisters[0x0], 246);
        expect(cpu.vRegisters[0xF], 1);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY5 sets the value of Vx to Vx - Vy and Vf = 1 if no borrow',
          () {
        cpu.vRegisters[0x1] = 1;
        cpu.vRegisters[0x0] = 10;

        load([0x80, 0x15]);
        run(1);

        // 1 - 10 = -9 + 255 = 246
        expect(cpu.vRegisters[0x0], 9);
        expect(cpu.vRegisters[0xF], 0);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY6 shifts Vx right by 1 and sets VF to the LSB', () {
        cpu.vRegisters[0x0] = 9; // 0b1001

        load([0x80, 0x16]);
        run(1);

        expect(cpu.vRegisters[0x0], 4);
        expect(cpu.vRegisters[0xF], 1);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY7 sets Vx to Vy - Vx and sets Vf to 1 if no borrow', () {
        cpu.vRegisters[0x0] = 10;
        cpu.vRegisters[0x1] = 11;

        load([0x80, 0x17]);
        run(1);

        expect(cpu.vRegisters[0x0], 1);
        expect(cpu.vRegisters[0xF], 1);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XY7 sets Vx to Vy - Vx and sets Vf to 0 if borrow', () {
        cpu.vRegisters[0x0] = 12;
        cpu.vRegisters[0x1] = 11;

        load([0x80, 0x17]);
        run(1);

        expect(cpu.vRegisters[0x0], 254);
        expect(cpu.vRegisters[0xF], 0);
        expect(cpu.programCounter, 0x202);
      });
      test('0x8XYE shifts Vx left by 1 and sets Vf to the MSB', () {
        cpu.vRegisters[0x0] = 9; // 0b1001

        load([0x80, 0x1E]);
        run(1);

        expect(cpu.vRegisters[0x0], 18);
        expect(cpu.vRegisters[0xF], 8);
        expect(cpu.programCounter, 0x202);
      });
    });
    group('0x9 series', () {
      test('0x9XY0 skips the next instruction if VX != VY', () {
        cpu.vRegisters[0x0] = 2;
        cpu.vRegisters[0x1] = 3;

        load([0x90, 0x10]);
        run(1);

        expect(cpu.programCounter, 0x204);
      });
      test('0x9XY0 doesnt skip the next instruction if VX == VY', () {
        cpu.vRegisters[0x0] = 3;
        cpu.vRegisters[0x1] = 3;

        load([0x90, 0x10]);
        run(1);

        expect(cpu.programCounter, 0x202);
      });
    });
    group('0xA series', () {
      test('0xANNN sets the iRegister to NNN', () {
        load([0xA1, 0x11]);
        run(1);

        expect(cpu.iRegister, 0x111);
        expect(cpu.programCounter, 0x202);
      });
    });
    group('0xB series', () {
      test('0xBNNN jumpts to the address NNN+V0', () {
        cpu.vRegisters[0x0] = 12;

        load([0xB1, 0x11]);
        run(1);

        expect(cpu.programCounter, 0x111 + 12);
      });
    });
    group('0xC series', () {
      // assuming this words XD/
    });
    group('0xD series', () {
      test('0xDXYN draws a sprite at coordinate Vx, Vy', () {
        load([0xD0, 0x14]);
        run(1);

        // TODO
      });
    });
    group('0xE series', () {
      test('0xEx9E skips the next instruction if the key with the value'
           'of Vx is pressed', () {
          press(0x1);
          cpu.vRegisters[0x0] = 0x1;

          load([0xE0, 0x9E]);
          run(1);

          expect(cpu.programCounter, 0x204);
        });
      test('0xEx9E does not skip the next instruction if the key with the'
           'value of Vx is not pressed', () {
          cpu.vRegisters[0x0] = 0x1;

          load([0xE0, 0x9E]);
          run(1);

          expect(cpu.programCounter, 0x202);
        });
      test('0xExA1 skips the next instruction if the key with the value'
           ' of Vx is not pressed', () {
          press(0x3);
          cpu.vRegisters[0x0] = 0x1;

          load([0xE0, 0xA1]);
          run(1);

          expect(cpu.programCounter, 0x204);
        });
      test('0xExA1 does not skip the next instruction if the key with the'
           'value of Vx is pressed', () {
          press(0x1);
          cpu.vRegisters[0x0] = 0x1;

          load([0xE0, 0xA1]);
          run(1);

          expect(cpu.programCounter, 0x202);
        });
    });
    group('0xF series', () {
      test('0xFX07 sets Vx to the value of the delay timer', () {
        cpu.delayTimer.time = 24;

        load([0xF0, 0x07]);
        run(1);

        expect(cpu.vRegisters[0x0], 24);
        expect(cpu.programCounter, 0x202);
      });

      test('0xFX15 sets the delay timer to Vx', () {
        cpu.delayTimer.time = 0;
        cpu.vRegisters[0x0] = 2;

        load([0xF0, 0x15]);
        run(1);

        expect(cpu.delayTimer.time, 2);
        expect(cpu.programCounter, 0x202);
      });

      test('0xFX18 sets the sound timer to Vx', () {
        cpu.soundTimer.time = 0;
        cpu.vRegisters[0x0] = 2;

        load([0xF0, 0x18]);
        run(1);

        expect(cpu.soundTimer.time, 2);
        expect(cpu.programCounter, 0x202);
      });

      test('0xFX1E adds Vx to the iRegister', () {
        cpu.vRegisters[0x0] = 12;
        cpu.iRegister = 3;

        load([0xF0, 0x1E]);
        run(1);

        expect(cpu.iRegister, 15);
        expect(cpu.programCounter, 0x202);
      });
      test('0xFX33', () {});
      test(
          '0xFX55 fills values from V0 to Vx inclusive with values in memory'
          ' starting at the iRegister', () {
        cpu.memory[4] = 0;
        cpu.memory[5] = 0;
        cpu.vRegisters[0x0] = 1;
        cpu.vRegisters[0x1] = 2;
        cpu.vRegisters[0x2] = 3;
        cpu.vRegisters[0x3] = 4;
        cpu.vRegisters[0x4] = 5;
        cpu.vRegisters[0x5] = 6;
        cpu.iRegister = 0x0;

        load([0xF4, 0x55]);
        run(1);

        expect(cpu.memory[0], 1);
        expect(cpu.memory[1], 2);
        expect(cpu.memory[2], 3);
        expect(cpu.memory[3], 4);
        expect(cpu.memory[4], 5);
        expect(cpu.memory[5], 0);
        expect(cpu.programCounter, 0x202);
      });
      test(
          '0xFX65 V0 to Vx inclusive with values in memory'
          ' startin at the iRegister', () {
        cpu.memory[0] = 1;
        cpu.memory[1] = 1;
        cpu.memory[2] = 1;
        cpu.memory[3] = 1;
        cpu.memory[4] = 1;

        load([0xF2, 0x65]);
        run(1);

        expect(cpu.vRegisters[0], 1);
        expect(cpu.vRegisters[1], 1);
        expect(cpu.vRegisters[2], 1);
        expect(cpu.vRegisters[3], 0);
        expect(cpu.programCounter, 0x202);
      });
    });
  });
}

import 'dart:math';
import 'dart:async';

import 'package:chip8/cpu.dart';
import 'package:chip8/platforms/web_screen.dart';
import 'package:chip8/platforms/web_sound.dart';
import 'package:chip8/platforms/web_timers.dart';
import 'package:chip8/platforms/web_input.dart';
import 'package:chip8/binaries/games.dart';

void main() {
  final cpu = new Cpu(
    new Random(0),
    new CanvasScreen('app'),
    new WebInput(),
    new WebSound(),
    new WebDelayTimer(),
    new WebSoundTimer());
  cpu.loadProgram(missile);
  new Timer.periodic(const Duration(milliseconds: 1), (_) {
    cpu.loop();
  });
}

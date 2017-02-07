import 'dart:math';
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:chip8/cpu.dart';
import 'package:chip8/platforms/web_screen.dart';
import 'package:chip8/platforms/web_sound.dart';
import 'package:chip8/platforms/web_timers.dart';
import 'package:chip8/platforms/web_input.dart';
import 'package:chip8/binaries/games.dart';

final vRegisterTable = document.getElementById('v-registers');

void main() {
  final cpu = new Cpu(
    new Random(0),
    new CanvasScreen('app', 10),
    new WebInput(),
    new WebSound(),
    new WebDelayTimer(),
    new WebSoundTimer());
  cpu.loadProgram(new Uint16List.fromList(missile));
  new Timer.periodic(const Duration(milliseconds: 950), (_)  {
    cpu.loop();
    updateDebug(cpu);
  });
}

void updateDebug(Cpu cpu) {
  for (int i = 0; i < 16; i++) {
    document.getElementById('$i').innerHtml = '${cpu.vRegisters[i]}';
  }
  document.getElementById('i').innerHtml = '${cpu.iRegister}';
  document.getElementById('delay').innerHtml = '${cpu.delayTimer.time}';
  document.getElementById('sound').innerHtml = '${cpu.soundTimer.time}';
  document.getElementById('counter').innerHtml = '${cpu.programCounter}';
}
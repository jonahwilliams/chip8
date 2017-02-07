import 'dart:async';

import '../modules/timer_module.dart';
import '../modules/sound_module.dart';

const sixtyHertz = const Duration(milliseconds: 16, microseconds: 666);

class WebDelayTimer implements DelayTimerModule {
  int time = 0;

  WebDelayTimer() {
    new Timer.periodic(sixtyHertz, (_) {
      if (time > 0) {
        time--;
      }
    });
  }
}

class WebSoundTimer implements SoundTimerModule {
  SoundModule _sound;
  int time = 0;

  WebSoundTimer() {
    new Timer.periodic(sixtyHertz, (_) {
      if (time > 0) {
        time--;
      }
    });
  }

  void attach(SoundModule sound) {
    _sound = sound;
  }
}

import 'sound_module.dart';

abstract class DelayTimerModule {
  
  int get time;

  set time(int value);
  
}

abstract class SoundTimerModule {

  int get time;

  set time(int value);

  void attach(SoundModule sound);
}
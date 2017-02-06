// Copyright (c) 2017, Jonah Williams. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library chip8;

import 'dart:io';
import 'dart:typed_data';

import 'src/cpu.dart';
export 'src/cpu.dart';


void main() {
  final bytes = new File('MISSILE').readAsBytesSync();
  final cpu = new Cpu()..loadOpcodes(new Uint16List.fromList(bytes));
  for (int i = 0 ; i < 100000; i++) {
    cpu.loop();
    print(cpu.screen);
  }
}

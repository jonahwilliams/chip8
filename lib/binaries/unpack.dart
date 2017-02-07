import 'dart:io';
import 'dart:typed_data';

void main() {
  final result = new File('TICTAC').readAsBytesSync();
  print(new Uint16List.fromList(result));
}

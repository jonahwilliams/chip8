import 'dart:io';
import 'dart:typed_data';

void main(String args) {
  final result = new File(args[0]).readAsBytesSync();
  print(new Uint8List.fromList(result));
}

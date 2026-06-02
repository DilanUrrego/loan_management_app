import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Inicializa sqflite FFI para Windows, Linux y macOS.
/// Este archivo NO debe importarse en web.
Future<void> initDesktopDb() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

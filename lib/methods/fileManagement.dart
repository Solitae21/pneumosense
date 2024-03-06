import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:pneumosense/classes/DiagLog.dart';

class FileManager {
  static FileManager? _instance;

  factory FileManager() {
    _instance ??= FileManager._internal();
    return _instance!;
  }

  FileManager._internal();

  Future<String> get _directoryPath async {
    Directory? directory = await getExternalStorageDirectory();
    return directory!.path;
  }

  Future<File> get _jsonFile async {
    final path = await _directoryPath;
    return File('$path/DiagLog.json');
  }

  Future<Map<String, dynamic>?> readJsonFile() async {
    late String fileContent;

    File file = await _jsonFile;

    if (await file.exists()) {
      try {
        fileContent = await file.readAsString();
        print('Successfully Read JSON File');
        return json.decode(fileContent);
      } catch (e) {
        print(e);
      }
    }
    return null;
  }

  Future<DiagLog> writeJsonFile(
      {required temp,
      required pulse,
      required oxy,
      required result,
      required date,
      required time}) async {
    final DiagLog diagLog = DiagLog(temp, pulse, oxy, result, date, time);

    File file = await _jsonFile;
    await file.writeAsString(json.encode(diagLog));
    print('File Successfully Created');
    return diagLog;
  }
}

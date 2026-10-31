import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor connect({String dbName = 'savoryx.sqlite'}) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, dbName));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
        rawDb.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}

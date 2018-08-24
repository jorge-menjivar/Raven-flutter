import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'request_entry.dart';

import 'room_model.dart';


class ListenersDatabase {

  Future getDb() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'listeners');
    return await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            "CREATE TABLE Listeners ("
                "${Room.db_contact} TEXT PRIMARY KEY, "
                "${Room.db_room} TEXT, "
                "${Room.db_time} TEXT, "
                "${Room.db_cToken} TEXT "
                ")");
      });
  }

  addToDb(Database db, RequestEntry request, String time) async{
    await db.rawInsert(
          'INSERT INTO '
              'Listeners(${Room.db_contact}, ${Room.db_room}, ${Room.db_time}, ${Room.db_cToken})'
              ' VALUES("${request.contact}", "${request.room}", "$time", "${request.cToken}")');
  }


  Future<List<Map>> getRoomQuery(Database db, String contact) async{
    var result = await db.rawQuery('SELECT * FROM Listeners WHERE ${Room.db_contact} = "$contact"');
    return result;
  }

  // Delete requested listener
  Future<int> deleteListener(Database db, String contact) async{
    return db.rawDelete('DELETE FROM Listeners WHERE ${Room.db_contact} = "$contact"');
  }

  // Close database
  Future closeDb(Database db) async {
    return db.close();
  }

  Future getQuery(Database db) async {
    var query = await db.rawQuery('SELECT * FROM Listeners ORDER BY ${Room.db_time} ASC');
    if (query.length == 0)print('NO LISTENERS');
    return query;
  }

}
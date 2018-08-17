import 'package:firebase_database/firebase_database.dart';

class RequestEntry {
  String room;
  String contact;

  RequestEntry({this.room, this.contact});

  RequestEntry.fromSnapshot(DataSnapshot snapshot)
  : room = snapshot.value['r'],
    contact = snapshot.value['c'];

  toJson() {
    return {
      "r" : room,
      "c" : contact
    };
  }
}
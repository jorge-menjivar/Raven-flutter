import 'package:firebase_database/firebase_database.dart';

class RequestEntry {
  String room;
  String contact;
  String cToken;

  RequestEntry({this.room, this.contact, this.cToken});

  RequestEntry.fromSnapshot(DataSnapshot snapshot)
  : room = snapshot.value['r'],
    contact = snapshot.value['c'],
    cToken = snapshot.value['t'];

  toJson() {
    return {
      "r" : room,
      "c" : contact,
      "t" : cToken
    };
  }
}
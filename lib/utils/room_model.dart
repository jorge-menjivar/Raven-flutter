import 'package:meta/meta.dart';

class Room {
  static final db_room = "room";
  static final db_contact = "contact";
  static final db_time = "time";
  static final db_cToken = "cToken";

  String room, contact, time, cToken;

  bool starred;
  Room({
    @required this.room,
    @required this.contact,
    @required this.time,
    @required this.cToken
  });

  Room.fromMap(Map<String, dynamic> map): this(
    room: map[db_room],
    contact: map[db_contact],
    time: map[db_time],
    cToken: map[db_cToken]
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    db_room: map.room,
    db_contact: map.contact,
    db_time: map.time,
    db_cToken: map.cToken
  };
}
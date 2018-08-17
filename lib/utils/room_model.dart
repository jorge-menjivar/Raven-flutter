import 'package:meta/meta.dart';

class Room {
  static final db_room = "room";
  static final db_contact = "contact";
  static final db_time = "time";

  String room, contact, time;

  bool starred;
  Room({
    @required this.room,
    @required this.contact,
    @required this.time,
  });

  Room.fromMap(Map<String, dynamic> map): this(
    room: map[db_room],
    contact: map[db_contact],
    time: map[db_time]
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    db_room: map.room,
    db_contact: map.contact,
    db_time: map.time
  };
}
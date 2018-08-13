import 'package:meta/meta.dart';

class Message {
  static final db_sTime = "sTime";
  static final db_rTime = "rTime";
  static final db_message = "message";
  static final db_image = "image";
  static final db_status = "status";
  static final db_birth = "birth";

  String sTime, rTime, message, image, status, birth;

  bool starred;
  Message({
    @required this.sTime,
    @required this.rTime,
    @required this.message,
    @required this.image,
    @required this.status,
    @required this.birth,
  });

  Message.fromMap(Map<String, dynamic> map): this(
    sTime: map[db_sTime],
    rTime: map[db_rTime],
    message: map[db_message],
    image: map[db_image],
    status: map[db_status],
    birth: map[db_birth],
  );

  // Currently not used
  static Map<String, dynamic> toMap(map) => {
    db_sTime: map.sTime,
    db_rTime: map.rTime,
    db_message: map.message,
    db_image: map.image,
    db_status: map.status,
    db_birth: map.birth,
  };
}
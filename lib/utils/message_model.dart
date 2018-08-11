import 'package:meta/meta.dart';

class Message {
  static final db_sTime = "sTime";
  static final db_rTime = "rTime";
  static final db_message = "message";
  static final db_image = "image";
  static final db_status = "status";

  String sTime, rTime, message, image, status;

  bool starred;
  Message({
    @required this.sTime,
    @required this.rTime,
    @required this.message,
    @required this.image,
    @required this.status,
  });

  Message.fromMap(Map<String, dynamic> map): this(
    sTime: map[db_sTime],
    rTime: map[db_rTime],
    message: map[db_message],
    image: map[db_image],
    status: map[db_status],
  );

  // Currently not used
  Map<String, dynamic> toMap() {
    return {
      db_sTime: sTime,
      db_rTime: rTime,
      db_message: message,
      db_image: image,
      db_status: status,
    };
  }
}
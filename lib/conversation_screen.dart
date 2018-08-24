import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Raven/utils/message_model.dart';
import 'package:Raven/utils/room_model.dart';
import 'package:Raven/utils/listeners_database.dart';
import 'package:Raven/utils/request_entry.dart';

import 'package:firebase_auth/firebase_auth.dart';


// New Convo
import 'package:http/http.dart' as http;

// Notifications
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Storage
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class ConversationScreen extends StatefulWidget {
  final FirebaseUser user;
  final String contact;
  final String username;
  final String room;
  final String contactNToken;

  ConversationScreen({this.user, this.contact, this.username, this.room, this.contactNToken});

  @override
  ConversationScreenState createState() => new ConversationScreenState(
    user: user,
    contact: contact,
    username: username,
    room: room,
    contactNToken: contactNToken
  );
}

class ConversationScreenState extends State<ConversationScreen> with WidgetsBindingObserver{
  final FirebaseUser user;
  final String contact;
  final String username;
  String room;
  String contactNToken;
  

  ScrollController controller;
  final TextEditingController _textController = new TextEditingController();

  final String tableName = "Messages";
  var queryResult;
  Database dataB;

  var mainReference;
  var statusesRef;
  var trashRef;
  var _inSub, _sSub, _tSub;


  
  ConversationScreenState({this.user, this.contact, this.username, this.room, this.contactNToken});

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var showTime;

  @override
  void initState() {
    super.initState();
    if (room == '0') {
      startNewConvo();
    }
    else {
      initQuery();
    }
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  void dispose() {
    super.dispose();
    closeDb(dataB);
    _inSub.cancel();
    _sSub.cancel();
    _tSub.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try{
      var initializationSettingsAndroid =
          new AndroidInitializationSettings('@mipmap/ic_launcher');
      var initializationSettingsIOS = new IOSInitializationSettings();
      var initializationSettings = new InitializationSettings(
          initializationSettingsAndroid, initializationSettingsIOS);
      flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin.initialize(initializationSettings);
      flutterLocalNotificationsPlugin.cancelAll();
    }
    catch (e) {
    }
  }


  void startNewConvo() async{
    try {
      var client = new http.Client();
      String token = await user.getIdToken();
      await client.post(
        "https://us-central1-raven-bd517.cloudfunctions.net/notificationFunctions/r/$username/$contact/t/m/" ,
        headers: {HttpHeaders.AUTHORIZATION: token})
        .then((response) async{
          try {
            print(response.body);
            await setContactNToken()
            .then((v) async{
              _saveRoomToDb(response.body);
              await _sendRoomRequest(response.body).then((s) {
                room = response.body;
                initQuery();
              });
            });
          }
          catch(e){
            print(e);
          }
        })
      .whenComplete(client.close);
    }
    catch(e){
      print('CONNECTION ERROR');
    }
  }

  void _saveRoomToDb(String recRoom) async{
    ListenersDatabase listeners = new ListenersDatabase();
    var time = DateTime.now().millisecondsSinceEpoch.toString();
    await listeners.getDb()
    .then((lisDb) async {
      await lisDb.rawInsert(
          'INSERT INTO '
              'Listeners(${Room.db_contact}, ${Room.db_room}, ${Room.db_time}, ${Room.db_cToken})'
              ' VALUES("$contact", "$recRoom", "$time", "$contactNToken")');
    });
  }

// Get the notification token for the contact
  Future setContactNToken() async{
    try {
      var client = new http.Client();
      String token = await user.getIdToken();
      await client.post(
        "https://us-central1-raven-bd517.cloudfunctions.net/notificationFunctions/t/u/$contact/t/m" ,
        headers: {HttpHeaders.AUTHORIZATION: token})
        .then((response) async{
          try {
            print(response.body);
            contactNToken = response.body;
          }
          catch(e){
            print(e);
          }
        })
      .whenComplete(client.close);
    }
    catch(e){
      print('CONNECTION ERROR');
    }
  }

  Future _sendRoomRequest(String recRoom) async{
    var reqRef = FirebaseDatabase.instance.reference().child('users').child(contact).child('requests');
    var nToken = await FirebaseMessaging().getToken();
    var request = new RequestEntry(
      //TODO let the receiver very the username of the sender through the server instead
      room: recRoom,
      contact: username,
      cToken : nToken
    );
    reqRef.push().set(request.toJson());
  }

  Future initQuery() async {
    await _getDb(contact)
    .then((database) async{
      dataB = database;
    });
  
    mainReference = FirebaseDatabase.instance.reference().child('messages').child(room).child('convo');
    statusesRef = FirebaseDatabase.instance.reference().child('messages').child(room).child('statuses');
    trashRef = FirebaseDatabase.instance.reference().child('messages').child(room).child('trash');

    // Listeners for online database.
    _inSub = mainReference.orderByKey().onChildAdded.listen(_messageAdded); // New Message
    _tSub = trashRef.onChildAdded.listen(_messageDeleted); // Remove Message
    _sSub = statusesRef.onChildChanged.listen(_statusChanged); // Message Status Changed

    
    var result = await _getQuery(dataB);

    showTime = new List<bool>.filled(result.length, false, growable: true);
    setState(() => queryResult = result);
  }


  // Called when a new message has been received.
  void _messageAdded(Event event) async{
    MessageEntry mEntry = MessageEntry.fromSnapshot(event.snapshot);
    var sTime = event.snapshot.key;
    var rTime = DateTime.now().millisecondsSinceEpoch.toString();

    await getMessageQuery(dataB, sTime)
    .then((localQ) async{
      if (localQ.length == 0){
        var message = new MessageEntry(
          message:  mEntry.message,
          birth:  mEntry.birth
        );
        
        addToDb(dataB, message, sTime, rTime, '2'); //Status 2 (Message Received)

        if (mEntry.birth != username){
          var status = new StatusEntry(
            status: "2"
          );

          // Letting the database know that we received the message.
          statusesRef.child(sTime).update(status.toJson());
        }
      }
      else return;
    });

    var result = await _getQuery(dataB);
    setState(() => queryResult = result);
  }

  void _statusChanged(Event event) async{
    var sEntry = StatusEntry.fromSnapshot(event.snapshot);
    var sTime = event.snapshot.key;
    updateMessage(dataB, sTime, 'status', sEntry.status);

    var result = await _getQuery(dataB);
    setState(() => queryResult = result);
  }


  void _messageDeleted(Event event) async{
    MessageEntry mEntry = MessageEntry.fromSnapshot(event.snapshot);
    var sTime = event.snapshot.key;
    try {
      if (mEntry.birth != username) {
        deleteMessage(dataB, sTime);
        trashRef.child(sTime).set(null);

        var result = await _getQuery(dataB);
        setState(() => queryResult = result);
      }
    }
    catch (e) {
      print(e);
    }
  }

  Future addToDb(Database db, MessageEntry entry, String sTime, String rTime, String status) async {
    await db.rawInsert(
          'INSERT INTO '
              '$tableName(${Message.db_sTime}, ${Message.db_rTime}, ${Message.db_message}, ${Message.db_image}, ${Message.db_status}, ${Message.db_birth})'
              ' VALUES("$sTime", "$rTime", "${entry.message}", "${entry.image}", "$status", "${entry.birth}")');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: new AppBar(
        title: new Text("Conversation with " + contact),
        elevation: 4.0,
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Column(
            children: <Widget>[
              new Flexible(
                child: buildMessages(),
              ),
              new Divider(height: 1.0),
              new Container(
              decoration: new BoxDecoration(
                color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
              ),
            ],
          );
        }
      )
    );
  }


  Widget _buildTextComposer() {
    return new Container(
       margin: const EdgeInsets.symmetric(horizontal: 8.0),
       child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: new InputDecoration.collapsed(
                hintText: "Send a message"),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                icon: new Icon(
                  Icons.send,
                  color: Colors.purple),
                onPressed: () {
                  if (_textController.text.contains(new RegExp(r'\S'))) {
                    _handleSubmitted(_textController.text);
                  }
                }
              ),
           ),
         ]
       )
    );
  }



  // Creating message and sending its values to all databases.
  _handleSubmitted(String text) async{
    _textController.clear();
    var sTime = DateTime.now().millisecondsSinceEpoch.toString();

    // Main message
    var message = new MessageEntry(
      message:  text,
      birth:  username
    );

    print(room);
    print(username);
    print(contact);

    // Status linked to the message
    var status = new StatusEntry(
      status: "2" // Status is SENT because when it is first read it would have already been sent.
    );

    // Add to local database with SENT status.
    addToDb(dataB, message, sTime, "0", "2");
  
    // Add to cloud database
    mainReference.child(sTime).set(message.toJson())
    .then((v) async{
      statusesRef.child(sTime).set(status.toJson())
      .then((v) async{
        // Refresh Screen
        var result = await _getQuery(dataB);
        this.setState(() => queryResult = result);
      });
    });

    try {
      var client = new http.Client();
      String token = await user.getIdToken();
      await client.post(
        "https://us-central1-raven-bd517.cloudfunctions.net/notificationFunctions/m/$username/u/$contactNToken/$text/" ,
        headers: {HttpHeaders.AUTHORIZATION: token})
        .then((response) async{
          try {
            print(response.body);
          }
          catch(e){
            print(e);
          }
        })
      .whenComplete(client.close);
    }
    catch(e){
      print('CONNECTION ERROR');
    }
  }


  Widget buildMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      reverse: true,

      // For even rows, the function adds a ListTile row for the word pairing.
      // For odd rows, the function adds a Divider widget to visually
      itemBuilder: (context, i){
        return getTile(i);
      }
    );
  }  

  Widget getTile (int i){
    if (queryResult != null && queryResult.length> 0 && i < queryResult.length){
      var row = queryResult[i];
      if (row['birth'] == username){
        return _buildSentRow(row['message'], row['status'], row['sTime'], i);
      }
      else {
        if (row['status'] == "2"){
          updateStatus(row['sTime'], "3");
        }
        return _buildReceivedRow(row['message'], row['sTime'], i);
      }
    }
    return null;
  }

  updateStatus(String sTime, String s) {
    var status = new StatusEntry(
      status: s
    );
    statusesRef.child(sTime).update(status.toJson());
  }






// ------------------------------------ SENT MESSAGES ---------------------------------------------------------
  Widget _buildSentRow(String message, String status, String sTime, int i) {

    // Text style
    var textStyle = new TextStyle(
      fontSize: 16.0,
      color: Colors.white,
    );

    // time
    int secs = int.tryParse(sTime);
    var dt = DateTime.fromMillisecondsSinceEpoch(secs);
    var time = "${dt.hour}:${dt.minute}";

    // chat bubble
    final radius = BorderRadius.only(
      topLeft: Radius.circular(20.0),
      topRight: Radius.circular(20.0),
      bottomLeft: Radius.circular(20.0),
      bottomRight: Radius.circular(20.0),
    );

    // bubble Color
    var color = Colors.purple[900];

    var timeRow;
    if (showTime[i] == true){
      timeRow = new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right : 3.0),
            child: new Text(
              time.toString(),
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 12.0
              ),
            ),
          ),
        ],
      );
    }
    else {
      timeRow = null;
    }

    // received or read icon
    var icon;
    if (status == '2'){
      icon = Icons.chat_bubble_outline;
    }
    else if (status == '3'){
      icon = Icons.chat_bubble;
    }

    return ListTile(
      contentPadding: EdgeInsets.only(left: 80.0),
      title: new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: .5,
                  spreadRadius: 1.0,
                  color: Colors.black.withOpacity(.12)
                )
              ],
              color: color,
              borderRadius: radius,
            ),
            child:new Text(
            message,
            textAlign: TextAlign.right,
            style: textStyle,
            ),
          ),

        ],
      ),
      subtitle: timeRow,
      trailing: new Icon(
              icon,
              color: Colors.blue,
              size: 20.0,),
      onLongPress: () {      // Add 9 lines from here...
        setState(() {
          _deleteSentMessage(sTime);
        });
      },
      onTap: () {
        setState(() {
          //toggle boolean
          showTime[i] = !showTime[i];
        });
      }
    );
  }




  // ---------------------------------- RECEIVED MESSAGES -------------------------------------------------
  Widget _buildReceivedRow(String message, String sTime, int i) {

    

    // Text style
    var textStyle = new TextStyle(
      fontSize: 16.0,
      color: Colors.black,
    );

    // time
    int secs = int.tryParse(sTime);
    var dt = DateTime.fromMillisecondsSinceEpoch(secs);
    var time = "${dt.hour}:${dt.minute}";

    // chat bubble
    final radius = BorderRadius.only(
      topLeft: Radius.circular(20.0),
      topRight: Radius.circular(20.0),
      bottomLeft: Radius.circular(20.0),
      bottomRight: Radius.circular(20.0),
    );

    // bubble Color
    var color = Colors.blueGrey[50];

    var timeRow;
    if (showTime[i] == true){
      timeRow = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new Container(
            child: new Text(
              time.toString(),
              textAlign: TextAlign.left,
              style: new TextStyle(
                fontSize: 12.0
              ),
            ),
          ),
        ],
      );
    }
    else {
      timeRow = null;
    }
        
    return ListTile(
      contentPadding: EdgeInsets.only(right: 80.0),
      leading: new CircleAvatar(
        child: new Text(contact.toUpperCase()[0])
      ),
      title: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  blurRadius: .5,
                  spreadRadius: 1.0,
                  color: Colors.black.withOpacity(.12)
                )
              ],
              color: color,
              borderRadius: radius,
            ),
            child:new Text(
            message,
            textAlign: TextAlign.left,
            style: textStyle,
            ),
          ),

        ],
      ),
      subtitle: timeRow,
      onLongPress: () {      // Add 9 lines from here...
        setState(() {
          _deleteSentMessage(sTime);
        });
      },
      onTap: () {
        setState(() {
          //toggle boolean
          showTime[i] = !showTime[i];
        });
      }
    );
  }



  _deleteSentMessage(String sTime){
    var trashMessage = new MessageEntry(
      birth: username
    );
    mainReference.child(sTime).set(null)
    .then((v) async{
      statusesRef.child(sTime).set(null)
      .then((v) async{
        trashRef.child(sTime).set(trashMessage.toJson())
        .then((v) async{
          // Refresh Screen
          deleteMessage(dataB, sTime)
          .then((r) async{
            var result = await _getQuery(dataB);
            this.setState(() => queryResult = result);
          });
        });
      });
    });
  }






  /// -------------------------------------- DATABASE -----------------------------------------

  // Use this method to access the database, because initialization of the database (it has to go through the method channel)

  Future _getDb(String contact) async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'convos', contact);
    return await openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
        // When creating the db, create the table
        await db.execute(
            "CREATE TABLE $tableName ("
                "${Message.db_sTime} TEXT PRIMARY KEY, "
                "${Message.db_rTime} TEXT, "
                "${Message.db_message} TEXT, "
                "${Message.db_image} TEXT, "
                "${Message.db_status} TEXT, "
                "${Message.db_birth} TEXT"
                ")");
      });
  }


   // Get a message by its sTime, if there is not entry for that ID, returns null.
  Future<List<Map>> getMessageQuery(Database db, String sTime) async{
    var result = await db.rawQuery('SELECT * FROM $tableName WHERE ${Message.db_sTime} = "$sTime"');
    return result;
  }

  Future<int> updateMessage(Database db, String sTime, String field, String value) async {
    return db.rawUpdate('UPDATE $tableName SET $field = "$value" WHERE sTime = $sTime');
  }

  // Delete requested message
  Future<int> deleteMessage(Database db, String sTime) async{
    return db.rawDelete('DELETE FROM $tableName WHERE ${Message.db_sTime} = "$sTime"');
  }

  // Close database
  Future closeDb(Database db) async {
    return db.close();
  }

  Future _getQuery(Database db) async {
    var query = await db.rawQuery('SELECT * FROM $tableName ORDER BY ${Message.db_sTime} DESC');
    if (query.length == 0)print('NO MESSAGES');
    return query;
  }

}








class ChatMessage extends StatelessWidget {
    final String text;
    final String sentTime;
    final String contact;
  ChatMessage({this.text, this.sentTime, this.contact});

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: new CircleAvatar(child: new Text(contact[0])),
          ),
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Text(contact, style: Theme.of(context).textTheme.subhead),
              new Container(
                margin: const EdgeInsets.only(top: 5.0),
                child: new Text(text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




class MessageEntry {
  String message;
  String image;
  String birth;

  MessageEntry({this.message, this.image, this.birth});

  MessageEntry.fromSnapshot(DataSnapshot snapshot)
  : message = snapshot.value['m'],
    image = snapshot.value['i'],
    birth = snapshot.value['b'];

  toJson() {
    return {
      "m": message,
      "i": image,
      "b": birth
    };
  }
}


class StatusEntry {
  String status;

  StatusEntry({this.status});

  StatusEntry.fromSnapshot(DataSnapshot snapshot)
  : status = snapshot.value['s'];

  toJson() {
    return {
      "s" : status,
    };
  }
}











































































class Storage {
  final String contact;
  Storage({this.contact});

  // Getting path to the app directory.
  Future<String> get _localPath async {
    var directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Getting the file we are working with.
  Future<File> get _localFile async {
    final path = await _localPath;
    print(path);
    Directory directory = new Directory('$path/convos/');
    if (!directory.existsSync()){
      directory.createSync();
    }
    return File('$path/convos/$contact.json');
  }

  // Writing the data to file.
  Future<File> writeToFile(String m) async {
    final file = await _localFile;

    if (!file.existsSync()){
      file.createSync();
    }
    
    // Write the file
    String time = TimeOfDay.now().toString();
    print(time);
    SentMessage message = new SentMessage(
        sTime: time,
        rTime: '0',
        message: m,
        image: '0',
        status: '0');
    String jsonMessage = json.encode(message);
    return file.writeAsString(jsonMessage);
  }

  // Read the data from the file.
  Future<int> readFromFile() async {
    try {
      final file = await _localFile;

      // Read the file
      String contents = await file.readAsString();

      Map messageMap = json.decode(contents);
      var message = ReceivedMessage.fromJson(messageMap);
      print('sTime: ${message.sTime}');
      print('rTime: ${message.rTime}');
      print('message: ${message.message}');
      print('image: ${message.image}');
      print('status: ${message.status}');
      return int.parse(contents);
    } catch (e) {
      // If we encounter an error, return 0
      return 0;
    }
  }
}


class SentMessage {
  final String sTime;
  final String rTime;
  final String message;
  final String image;
  final String status;

  SentMessage({this.sTime, this.rTime, this.message, this.image, this.status});
  factory SentMessage.fromJson(Map<String, dynamic> parsedJson) {

    return SentMessage (
      sTime: parsedJson['sTime'], 
      rTime: parsedJson['rTime'],
      message: parsedJson['message'],
      image: parsedJson['image'],
      status: parsedJson['status']
    );
  }
  
  Map<String, dynamic> toJson() => 
  {
    'sTime': sTime,
    'rTime': rTime,
    'message' : message,
    'image' : image,
    'status' : status
  };
}


class ReceivedMessage {
  final String sTime;
  final String rTime;
  final String message;
  final String image;
  final String status;

  ReceivedMessage({this.sTime, this.rTime, this.message, this.image, this.status});
  factory ReceivedMessage.fromJson(Map<String, dynamic> parsedJson) {

    return ReceivedMessage (
      sTime: parsedJson['sTime'], 
      rTime: parsedJson['rTime'],
      message: parsedJson['message'],
      image: parsedJson['image'],
      status: parsedJson['status']
    );
  }
  
  Map<String, dynamic> toJson() => 
  {
    'sTime': sTime,
    'rTime': rTime,
    'message' : message,
    'image' : image,
    'status' : status
  };




}

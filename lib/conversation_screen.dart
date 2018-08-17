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

  ConversationScreen({this.user, this.contact, this.username, this.room});

  @override
  ConversationScreenState createState() => new ConversationScreenState(user: user, contact: contact, username: username, room: room);
}

class ConversationScreenState extends State<ConversationScreen> {
  final FirebaseUser user;
  final String contact;
  final String username;
  final String room;
  
  ConversationScreenState({this.user, this.contact, this.username, this.room});
  
  final TextEditingController _textController = new TextEditingController();
  final _biggerFont = const TextStyle(fontSize: 17.0);

  final String tableName = "Messages";
  var queryResult;
  Database dataB;

  var mainReference;
  var statusesRef;
  var _inSub, _dSub, _sSub;


  @override
  void initState() {
      super.initState();
      mainReference = FirebaseDatabase.instance.reference().child('messages').child(room).child('convo');
      statusesRef = FirebaseDatabase.instance.reference().child('messages').child(room).child('statuses');
      initQuery();
      if (room == '0')
        startNewConvo();
  }


  @override
  void dispose() {
    super.dispose();
    closeDb(dataB);
    _inSub.cancel();
    _dSub.cancel();
    _sSub.cancel();
  }

  void startNewConvo() async{
    try {
      var client = new http.Client();
      String token = await user.getIdToken();
      await client.post(
        "https://us-central1-raven-bd517.cloudfunctions.net/notificationFunctions/command/$username/$contact/" ,
        headers: {HttpHeaders.AUTHORIZATION: token})
        .then((response) async{
          try {
            _saveRoomToDb(response.body);
            _sendRoomRequest(response.body);
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

  void _saveRoomToDb(String room) async{
    ListenersDatabase listeners = new ListenersDatabase();
    var time = DateTime.now().millisecondsSinceEpoch.toString();
    await listeners.getDb()
    .then((lisDb) async {
      await lisDb.rawInsert(
          'INSERT INTO '
              'Listeners(${Room.db_room}, ${Room.db_contact}, ${Room.db_time})'
              ' VALUES("$room", "$contact", "$time")')
      .then((){
        listeners.closeDb(lisDb);
      });
    });
  }


  void _sendRoomRequest(String room) async{
    var reqRef = FirebaseDatabase.instance.reference().child('users').child(contact).child('requests');
    var request = new RequestEntry(
      //TODO let the receiver very the username of the sender through the server instead
      room: room,
      contact: username
    );
    reqRef.push().set(request.toJson());
  }

  Future initQuery() async {
    await _getDb(contact)
    .then((database) async{
      dataB = database;
      var result = await _getQuery(database);
      this.setState(() => queryResult = result);
    });

    // Listeners for online database.
    _inSub = mainReference.orderByKey().limitToLast(1).onChildAdded.listen(_messageAdded); // New Message
    _dSub = mainReference.onChildRemoved.listen(_messageDeleted); // Remove Message
    _sSub = statusesRef.onChildChanged.listen(_statusChanged); // Message Status Changed
  }


  // Called when a new message has been received.
  void _messageAdded(Event event) async{
    MessageEntry mEntry = MessageEntry.fromSnapshot(event.snapshot);
    var sTime = event.snapshot.key;
    var rTime = DateTime.now().millisecondsSinceEpoch.toString();

    if (mEntry.birth != username){
      await getMessageQuery(dataB, sTime)
      .then((localQ) async{
        if (localQ.length == 0){
          var message = new MessageEntry(
            message:  mEntry.message,
            birth:  mEntry.birth
          );

          addToDb(dataB, message, sTime, rTime, '2'); //Status 2 (Message Received)
          
          var result = await _getQuery(dataB);
          setState(() => queryResult = result);

          var status = new StatusEntry(
            status: "2"
          );

          // Letting the database know that we received the message.
          statusesRef.child(sTime).update(status.toJson());
        }
        else return;
      });
    }
  }

  void _statusChanged(Event event) async{
    var sEntry = StatusEntry.fromSnapshot(event.snapshot);
    var sTime = event.snapshot.key;
    updateMessage(dataB, sTime, 'status', sEntry.status);
  }


  void _messageDeleted(Event event) async{
    var sTime = event.snapshot.key;
    deleteMessage(dataB, sTime);

    var result = await _getQuery(dataB);
    setState(() => queryResult = result);
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

    // Status linked to the message
    var status = new StatusEntry(
      status: "1" // Status is SENT because when it is first read it would have already been sent.
    );

    // Add to local database with UNSENT status.
    addToDb(dataB, message, sTime, "0", "0");
    
    print(user.uid.toString());
  
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
  }


  Widget buildMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(22.0),
      reverse: true,

      // For even rows, the function adds a ListTile row for the word pairing.
      // For odd rows, the function adds a Divider widget to visually
      itemBuilder: (context, i){
        if (queryResult != null && queryResult.length> 0 && i < queryResult.length){
          var row = queryResult[i];
          if (row['birth'] == contact){
            return _buildReceivedRow(row['message'], row['sTime']);
          }
          else {
            return _buildSentRow(row['message'], row['status'], row['sTime']);
          }
        }
      }
    );
  }

  Widget _buildSentRow(String message, String status, String sTime) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 80.0),
      title: Text(
        message,
        textAlign: TextAlign.right,
        style: _biggerFont,
      ),
      onTap: () {      // Add 9 lines from here...
        setState(() {
          _deleteSentMessage(sTime);
        });
      }  
    );
  }

  Widget _buildReceivedRow(String message, String sTime) {
    return ListTile(
      contentPadding: EdgeInsets.only(right: 80.0),
      title: Text(
        message,
        textAlign: TextAlign.left,
        style: _biggerFont,
      ),
      onTap: () {      // Add 9 lines from here...
        setState(() {
          _deleteSentMessage(sTime);
        });
      }  
    );
  }



  _deleteSentMessage(String sTime){
    mainReference.child(sTime).set(null)
    .then((v) async{
      statusesRef.child(sTime).set(null)
      .then((v) async{
        // Refresh Screen
        deleteMessage(dataB, sTime)
        .then((r) async{
          var result = await _getQuery(dataB);
          this.setState(() => queryResult = result);
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

  void checkTime() async {
    var now = DateTime.now().millisecondsSinceEpoch;
    print(now);
    var inCurrentTime = DateTime.fromMillisecondsSinceEpoch(now);
    print(inCurrentTime);

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

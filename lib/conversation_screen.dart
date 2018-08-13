import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:Raven/utils/message_model.dart';

import 'package:firebase_auth/firebase_auth.dart';

// Storage
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';


class ConversationScreen extends StatefulWidget {
  final FirebaseUser user;
  final String contact;

  ConversationScreen({this.user, this.contact});

  @override
  ConversationScreenState createState() => new ConversationScreenState(user: user, contact: contact);
}

class ConversationScreenState extends State<ConversationScreen> {
  final FirebaseUser user;
  final String contact;
  
  ConversationScreenState({this.user, this.contact});

  
  final List<ChatMessage> _messages = <ChatMessage>[];
  
  final TextEditingController _textController = new TextEditingController();

  final String tableName = "Messages";

  final _biggerFont = const TextStyle(fontSize: 17.0);

  var queryResult;

  Database dataB;

  @override
  void initState() {
      super.initState();
      initQuery();
  }

  Future initQuery() async {
    await _getDb(contact)
    .then((database) async{
      dataB = database;
      var result = await _getQuery(database);
      this.setState(() => queryResult = result);
    });

  }

  Future addToDb(Database db, String text) async {
    await db.rawInsert(
          'INSERT INTO '
              '$tableName(${Message.db_sTime}, ${Message.db_rTime}, ${Message.db_message}, ${Message.db_image}, ${Message.db_status}, ${Message.db_birth})'
              ' VALUES("${DateTime.now().millisecondsSinceEpoch}", "0", "${text}", "0", "0", "0")');
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

  _handleSubmitted(String text) async{
    _textController.clear();
    addToDb(dataB, text);
    var result = await _getQuery(dataB);
    this.setState(() => queryResult = result);
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
          if (row['birth'] == '0'){
            return _buildSentRow(row['message'], row['status']);
          }
          else {
            return _buildReceivedRow(row['message']);
          }
        }
      }
    );
  }

  Widget _buildSentRow(String message, String status) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: 80.0),
      title: Text(
        message,
        textAlign: TextAlign.right,
        style: _biggerFont,
      ), 
    );
  }

  Widget _buildReceivedRow(String message) {
    return ListTile(
      contentPadding: EdgeInsets.only(right: 80.0),
      title: Text(
        message,
        textAlign: TextAlign.left,
        style: _biggerFont,
      ),  
    );
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
  Future<Message> getMessage(Database db, String contact, String sTime) async{
    var result = await db.rawQuery('SELECT * FROM $tableName WHERE ${Message.db_sTime} = "$sTime"');
    if(result.length == 0)return null;
    return new Message.fromMap(result[0]);
  }

  // Delete requested message
  Future<int> deleteMessage(Database db, String contact, String sTime) async{
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

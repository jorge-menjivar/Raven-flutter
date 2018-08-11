import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

// Storage
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

  @override
  Widget build(BuildContext context) {
    fileTest();
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Conversation with " + contact),
        elevation: 4.0,
      ),
      body: new Container(
      )
    );
  }

  void fileTest() async {
      Storage storage = new Storage(contact: contact);
      await storage.writeToFile("hi");
      await storage.readFromFile();
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

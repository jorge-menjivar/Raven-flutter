import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'welcome_screen.dart';

// Storage
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main(){
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Raven',
      theme: new ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: new MyInitPage(title: 'Welcome'),
    );
  }
}

class MyInitPage extends StatefulWidget {
  MyInitPage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyInitPageState createState() => new _MyInitPageState();
}

class _MyInitPageState extends State<MyInitPage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseUser user;
  final secureStorage = new FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _getDir();
    _checkCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(""),
        elevation: 4.0,
      ),
      body: new Container()
    );
  }

  void _checkCurrentUser() async {
    await _auth.currentUser().then((u) async{
      user = u;
      if (user == null) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WelcomeScreen(user: user)));
      } 
      else {
        _checkToken();
        var username = await secureStorage.read(key: 'username');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(user, username)));
      }
    });
  }

  void _getDir(){

  }

  Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
  }
  
  void _checkToken() async {
    try {
      // Future to get user token
      var token = await user.getIdToken();
      _checkRefreshedToken(token);
    } catch (e) {
      // Handling error
      print(e.toString());
    }
  }

  void _checkRefreshedToken(var token) async {
    var id = user.uid.toString();
    DocumentSnapshot ds = await Firestore.instance.collection('users').document(id).get();
    var dbToken = ds['t'];
    if (dbToken is String) {
      if (token == dbToken){ //Token matches database. Token is up to date.
        print("TOKEN IS UP TO DATE");
      }
      else {
        print("TOKEN IS NOT UP TO DATE");
        updateToken(id, token);
      }
    }
    else {
      print("TOKEN IS NOT A STRING");
    }
  }

  void updateToken(var id, var token) async {
    print("UPDATING TOKEN...");
    try {
      Firestore.instance.collection('users').document(id)
      .updateData({'t': token});  
      print("UPDATING TOKEN: SUCCESS");
    } catch (e) {
      print(e.toString());
      print("UPDATING TOKEN: FAILURE");
    }
  }
}
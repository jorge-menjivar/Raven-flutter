import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:raven/username_screen.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Raven',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.purple,
      ),
      home: new MyHomePage(title: 'MyRavens'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<FirebaseUser> _listener;

  FirebaseUser user;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return new SignInScreen(
        title: "Log In or Sign Up to Raven",
        header: new Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0),
          child: new Padding(
            padding: const EdgeInsets.all(32.0),
            child: new Text("Use your email... or social media"),
          ),
        ),
        providers: [
          ProvidersTypes.email,
          ProvidersTypes.google,
          ProvidersTypes.facebook
        ],
      );
    } else {
      return new HomeScreen(user: user);
    }
  }

  void _checkCurrentUser() async {
    user = await _auth.currentUser();

    _listener = _auth.onAuthStateChanged.listen((FirebaseUser myUser) {
      setState(() {
        user = myUser;
        if (user != null && user.displayName != null){ //Making sure that we only continue while background pro have completed.
          _checkAccountDbExistence(); //Create Display name & Database account if it does not yet exist.
        }
      });
    });
  }

  void _checkAccountDbExistence() async {
    try {
      final String id = user.uid.toString();
      DocumentSnapshot ds = await Firestore.instance.collection('users').document(id).get();
      if (ds.exists) {
        print ("ACCOUNT ALREADY EXISTS ON DATABASE. USER IS LOGGING IN");
        _checkToken();
      }
      else {
        print ("ACCOUNT DOES NOT EXISTS ON DATABASE. USER IS SIGNING UP");
        Navigator.push(context, MaterialPageRoute(builder: (context) => UsernameScreen(user)));
      }
    } catch (e) {
      print(e.toString());
    }
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
class HomeScreen extends StatelessWidget {
  final FirebaseUser user;

  HomeScreen({this.user});

  @override
  Widget build(BuildContext context) => new Scaffold(
      appBar: new AppBar(
        title: new Text("Raven Messenger"),
        elevation: 4.0,
      ),
      body: new Container(
          padding: const EdgeInsets.all(16.0),
          decoration: new BoxDecoration(color: Colors.amber),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Text("Welcome,"),
                ],
              ),
              new SizedBox(
                height: 8.0,
              ),
              new Text(user.displayName ?? user.email),
              new SizedBox(
                height: 32.0,
              ),
              new RaisedButton(
                  child: new Text("DECONNEXION"), onPressed: _logout)
            ],
          )));

  void _logout() async{
    print("hello");
    //FirebaseAuth.instance.signOut();
  }
}
import 'dart:async';

import 'package:flutter/material.dart';

import 'username_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MySignInScreen extends StatefulWidget {
  final FirebaseUser user;

  MySignInScreen(this.user);

  @override
  SignInScreenState createState() => new SignInScreenState();
}

class SignInScreenState extends State<MySignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<FirebaseUser> _listener;

  final secureStorage = new FlutterSecureStorage();

  FirebaseUser user;

  @override
  Widget build(BuildContext context) {
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
  }

  
  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    super.dispose();
    _listener.cancel();
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
        var username = await ds['u'];
        secureStorage.write(key: 'username', value: username);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(user, username)));
      }
      else {
        print ("ACCOUNT DOES NOT EXISTS ON DATABASE. USER IS SIGNING UP");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UsernameScreen(user)));
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
    var dbToken = await ds['t'];
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
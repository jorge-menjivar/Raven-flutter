import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'signin_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final FirebaseUser user;

  WelcomeScreen({this.user});

  @override
  WelcomeScreenState createState() => new WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen> {

  FirebaseUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                new Text("Welcome to Raven"),
              ],
            ),
            new SizedBox(
              height: 32.0,
            ),
            new RaisedButton(
              child: new Text("SIGN IN"), onPressed: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MySignInScreen(user)));
              }
            )
          ],
        )
      )
    );
  }
}
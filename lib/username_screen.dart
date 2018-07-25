import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_firebase_ui/flutter_firebase_ui.dart';
import 'package:raven/main.dart';


class UsernameScreen extends StatefulWidget {

  @override
  createState() => UsernameScreenState();
}

class UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controllerUsername = new TextEditingController();

  final FirebaseUser user;

  @override
  Widget build(BuildContext context) => new Scaffold(
      appBar: new AppBar(
        title: new Text("Create Username"),
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
                  new TextField(
                    controller: _controllerUsername,
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    decoration: null,
                  ),
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
                  child: new Text("CHECK"), onPressed: _checkAvailability)
            ],
          )));

  void _checkAvailability() async{
    String username = _controllerUsername.text;
    try {
      QuerySnapshot qs = await Firestore.instance.collection('usernames').where("u", isEqualTo: username).getDocuments();
      if (qs.documents.length > 0) {
        print ("USERNAME IS TAKE");
      }
      else {
        print ("USERNAME IS AVAILABLE");
      }
    } catch (e) {
      print(e.toString());
    }
  }
}
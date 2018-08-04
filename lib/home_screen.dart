import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;


class HomeScreen extends StatefulWidget {
  final FirebaseUser user;
  final String username;

  HomeScreen(this.user, this.username);
  @override
  createState() => HomeScreenState(user: user, username: username);
}

class HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controllerUsername = new TextEditingController();
  final FirebaseUser user;
  final String username;

  HomeScreenState({this.user, this.username});

  bool _available = true;
  bool _firstTry = true;
  int _counter = 0;

  final _formFieldKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("My Ravens"),
        elevation: 4.0,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Raven Message',
        child: new Icon(Icons.message),
        onPressed: createNewMessage,
        ),
      body: new Builder(
        builder: (BuildContext context) {
          return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: new BoxDecoration(color: Colors.amber),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
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
              new Text(username),
              new SizedBox(
                height: 32.0,
              ),
            ],
          )
        );
      })
    );
  }

  void createNewMessage() {

  }
}
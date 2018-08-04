import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';



class UsernameScreen extends StatefulWidget {
  final FirebaseUser user;

  UsernameScreen(this.user);
  @override
  createState() => UsernameScreenState(user: user);
}

class UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controllerUsername = new TextEditingController();
  final FirebaseUser user;

  UsernameScreenState({this.user});

  bool _available = true;
  bool _firstTry = true;
  int _counter = 0;

  final _formFieldKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async => false,
        child: new Scaffold(
        appBar: new AppBar(
          title: new Text("Create Username"),
          elevation: 4.0,
        ),
        body: new Builder(
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: new BoxDecoration(color: Colors.amber),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new TextFormField(
                    key: _formFieldKey,
                    controller: _controllerUsername,
                    keyboardType: TextInputType.text,
                    autocorrect: false,
                    autofocus: true,
                    autovalidate: true,
                    decoration: new InputDecoration(
                      labelText: "What will be your username?",
                      hintText: "Friends will find you with this",
                      ),
                    validator: (username) {
                      if (_firstTry == false && username.length < 4 || username.length > 20)
                        return 'Usernames are lower case. 4 to 20 characters long.';
                      if (username.contains(new RegExp(r'\W')))
                        return 'Only letter, digits, and _';
                      if (_available == false){
                        _counter++; //For first run on Validate() call
                        if (_counter > 1){
                          _counter = 0;
                          _available = true; //For second(last) run on Validate() call
                        }
                        return 'Username is unavailable';
                      }
                    },
                  ),
                  new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      
                    ],
                  ),
                  new SizedBox(
                    height: 32.0,
                  ),
                  new RaisedButton(
                      child: new Text("CONTINUE TO RAVEN"), onPressed: (){
                        _firstTry = false;
                        if (_formFieldKey.currentState.validate() == true){
                          Scaffold
                          .of(context)
                          .showSnackBar(SnackBar(content: Text('Processing Data')));
                          _tryRegistration();
                        }
                      }
                  )
                ],
              )
            );
          },
        )
      )
    );
  } 

  //Sending registration post to server. If username is taken then display error. Otherwise continue.
  void _tryRegistration() async{
    final username = _controllerUsername.text.toString().toLowerCase();
    try {
      var client = new http.Client();
      String token = await user.getIdToken();
      await client.post(
        "https://us-central1-raven-bd517.cloudfunctions.net/usernameFunctions/" +  username,
        headers: {HttpHeaders.AUTHORIZATION: token})
        .then((response) {
          final responseJson = json.decode(response.body);
          print(responseJson);
          if (response.statusCode == 402){
              // _available is bool that gets set to false to throw error. Gets set back to true when another letter is inputted.
              // For benefit of doubt that username is unavailable and to not make it confusing for user.
              _available = false;
              _formFieldKey.currentState.validate();
          }
          else if (response.statusCode == 420){
            //TODO when username is accepted and user info is in database.
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(user, username)));
          }
          else if (response.statusCode == 500){
            //TODO use firebase to collect error data.
            print('SERVER ERROR');
            Fluttertoast.showToast(
              msg: "Server error",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIos: 1,
              bgcolor: "#e74c3c",
              textcolor: '#ffffff'
            );
          }
        })
      .whenComplete(client.close);
    }
    catch(e){
      print('CONNECTION ERROR');
      print(e);
      Fluttertoast.showToast(
        msg: "Connection error",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        bgcolor: "#e74c3c",
        textcolor: '#ffffff'
      );
    }
  }
}

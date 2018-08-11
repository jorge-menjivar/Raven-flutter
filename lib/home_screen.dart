import 'package:flutter/material.dart';

import 'conversation_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';


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
  final _biggerFont = const TextStyle(fontSize: 18.0);

  List<String> _convosList = ['rudmaister', 'hennykenny', 'ninjakiwi'];

  HomeScreenState({this.user, this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("My Ravens"),
        elevation: 4.0,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        hasNotch: true,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: Icon(Icons.menu), onPressed: () {},),
            IconButton(icon: Icon(Icons.search), onPressed: () {},),
          ],
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Raven Message',
        child: new Icon(Icons.message),
        onPressed: createNewMessage,
        ),
      body: _buildConvoTitles(),
    );
  }

  Widget _buildConvoTitles() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),

      // For even rows, the function adds a ListTile row for the word pairing.
      // For odd rows, the function adds a Divider widget to visually
      itemBuilder: (context, i){
        if (i.isOdd) return Divider();
        
        int index = i ~/ 2;
        if (index < _convosList.length){
          return _buildRow(index);
        }

        return null;
      }
    );
  }

  Widget _buildRow(int index) {
    return ListTile(
      title: Text(
        _convosList[index],
        style: _biggerFont,
      ),
      trailing: new Icon(
        Icons.phonelink_lock,
        color: Colors.green,
      ), 
      onTap: () {      // Add 9 lines from here...
        setState(() {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationScreen(user: user, contact: _convosList[index])));
        });
      }  
    );
  }

  void createNewMessage() {

  }
}
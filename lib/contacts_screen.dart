import 'dart:ui';

import 'package:flutter/material.dart';

import 'conversation_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

// Storage
import 'package:firebase_database/firebase_database.dart';


class ContactScreen extends StatefulWidget {
  final FirebaseUser user;
  final String username;
  ContactScreen({this.user, this.username});

  @override
  createState() => ContactScreenState(user: user, username: username);
}




class ContactScreenState extends State<ContactScreen> {
  final FirebaseUser user;
  final String username;

  List<ContactEntry> friends;

  var _friendsRef;

  var _inSub;

  ContactScreenState({this.user, this.username});
  


  @override
  void initState(){
    super.initState();
    friends = new List<ContactEntry>.filled(0, null, growable: true);
    _friendsRef = FirebaseDatabase.instance.reference().child('users').child(username).child('friends');
    _inSub = _friendsRef.orderByKey().onChildAdded.listen(_onContact);
  }

  _onContact(Event event) async{
    ContactEntry c = ContactEntry.fromSnapshot(event.snapshot);
    c.time = event.snapshot.key;
    setState(() {
     friends.add(c);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _inSub.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text("Friends"),
        elevation: 4.0,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        hasNotch: true,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: Icon(Icons.menu), onPressed: () {},
            ),
            IconButton(icon: Icon(Icons.search), onPressed: () {},
            ),
          ],
        ),
      ),
      floatingActionButtonLocation:
      FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Friend',
        child: new Icon(Icons.person_add),
        onPressed: addFriend(),
        ),
      body: _buildFriendTitles(),
    );
  }

  addFriend(){

  }

  Widget _buildFriendTitles() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),

      // For even rows, the function adds a ListTile row for the word pairing.
      // For odd rows, the function adds a Divider widget to visually
      itemBuilder: (context, i){
        if (i.isOdd && friends.length > 0) return Divider();
        int index = i ~/ 2;
        if (friends != null && friends.length> 0 && index < friends.length){
          var row = friends[index];
          return _buildRow(row.contact);
        }
        else if (i == 0){
          return _buildNoFriendsRow();
        }
        return null;
      }
    );
  }

  Widget _buildNoFriendsRow(){
    var noFriendsText = "It looks lonely over here. Time to add some friends!";
    var style = new TextStyle(
      color: Colors.black45,
      fontSize: 18.0
    );

    return ListTile(
      contentPadding: const EdgeInsets.all(40.0),
      title: Text(
        noFriendsText,
        textAlign: TextAlign.center,
        style: style,
      ),
      leading: Text(
        "😭",
        style: TextStyle(
          color: Colors.black45,
          fontSize: 30.0,
        ),
      ),
    );
  }


  Widget _buildRow(String contact) {
    // text style
    var style = new TextStyle(
      color: Colors.black,
      fontSize: 18.0
    );

    return ListTile(
      title: Text(
        contact,
        textAlign: TextAlign.left,
        style: style,
      ),
      trailing: new Icon(
        Icons.person,
        color: Colors.blue,
      ), 
      onTap: () {
        setState(() {
          Navigator.pushReplacement(context, MaterialPageRoute(builder:
          (context) => new ConversationScreen(
            user: user,
            contact: contact,
            username: username,
            room: "0",
            contactNToken: "0",
          )));
        });
      }  
    );
  }

}











class ContactEntry {
  String contact;
  String time;

  ContactEntry({this.contact, this.time});

  ContactEntry.fromSnapshot(DataSnapshot snapshot)
  : contact = snapshot.value['c'],
    time = snapshot.value['t'];

  toJson() {
    return {
      "c": contact,
      "t": time,
    };
  }
}
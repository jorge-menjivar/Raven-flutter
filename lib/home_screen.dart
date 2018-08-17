import 'package:flutter/material.dart';

import 'conversation_screen.dart';
import 'package:Raven/utils/listeners_database.dart';
import 'package:Raven/utils/request_entry.dart';

import 'package:firebase_auth/firebase_auth.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseUser user;
  final String username;

  HomeScreen(this.user, this.username);
  @override
  createState() => HomeScreenState(user: user, username: username);
}

class HomeScreenState extends State<HomeScreen> {

  HomeScreenState({this.user, this.username});

  final TextEditingController _controllerUsername = new TextEditingController();
  final FirebaseUser user;
  final String username;
  final _biggerFont = const TextStyle(fontSize: 18.0);

  List<String> _convosList = ['rudmaister', 'hennykenny', 'ninjakiwi'];


  ListenersDatabase ld = new ListenersDatabase();
  var queryResult;
  Database db;
  
  var reqRef;

  var _inSub, _dSub, _sSub;

  @override
  void initState(){
    super.initState();
    reqRef = FirebaseDatabase.instance.reference().child('users').child(username).child('requests');
    _initDb();
  }


  @override
  void dispose() {
    super.dispose();
    _inSub.cancel();
    _dSub.cancel();
    _sSub.cancel();
  }

  void _initDb() async {
    ld.getDb()
    .then((lisDb) async{
      db = lisDb;
      var result = await ld.getQuery(db);
      this.setState(() => queryResult = result);
    });

    
    // Listeners for online database.
    _inSub = reqRef.orderByKey().onChildAdded.listen(_requestReceived); // New Request
  }

  _requestReceived(Event event) async{
    RequestEntry request = RequestEntry.fromSnapshot(event.snapshot);

    await ld.getRoomQuery(db, request.contact)
    .then((localQ) async{
      if (localQ.length == 0){

        var time = DateTime.now().millisecondsSinceEpoch.toString();
        ld.addToDb(db, request, time);
        
        var result = await ld.getQuery(db);
        setState(() => queryResult = result);
      }
      else return;
    });
  }
  

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
            IconButton(icon: Icon(Icons.menu), onPressed: () {deleteDatabase(db.path);},),
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
        if (queryResult != null && queryResult.length> 0 && index < queryResult.length){
          var row = queryResult[index];
          return _buildRow(row['contact'], row['room']);
        }
        return null;
      }
    );
  }

  Widget _buildRow(String name, String room) {
    return ListTile(
      title: Text(
        name,
        textAlign: TextAlign.left,
        style: _biggerFont,
      ),
      trailing: new Icon(
        Icons.phonelink_lock,
        color: Colors.red,
      ), 
      onTap: () {      // Add 9 lines from here...
        setState(() {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationScreen(user: user, contact: name, username: username, room: room,)));
        });
      }  
    );
  }

  void createNewMessage() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ConversationScreen(user: user, contact: 'rudmaister', username: username, room: '0',)));
  }
}
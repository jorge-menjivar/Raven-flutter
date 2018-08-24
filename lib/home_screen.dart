import 'package:flutter/material.dart';

import 'conversation_screen.dart';
import 'package:Raven/utils/listeners_database.dart';
import 'package:Raven/utils/request_entry.dart';
import 'contacts_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

// Storage
import 'package:sqflite/sqflite.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Notifications
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseUser user;
  final String username;

  HomeScreen(this.user, this.username);
  @override
  createState() => HomeScreenState(user: user, username: username);
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver{

  HomeScreenState({this.user, this.username});

  final TextEditingController _controllerUsername = new TextEditingController();
  final FirebaseUser user;
  final String username;
  final _biggerFont = const TextStyle(fontSize: 18.0);

  List<String> _convosList = ['rudmaister', 'hennykenny', 'ninjakiwi'];

  final FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();


  ListenersDatabase ld = new ListenersDatabase();
  var queryResult;
  Database db;
  
  var reqRef;

  var _rSub, _inSub, _dSub, _sSub;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState(){
    super.initState();
    initFireMessaging();
    reqRef = FirebaseDatabase.instance.reference().child('users').child(username).child('requests');
    _initDb();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    try{
      var result = await ld.getQuery(db);
      this.setState(() => queryResult = result);
      var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
      var initializationSettingsIOS = new IOSInitializationSettings();
      var initializationSettings = new InitializationSettings(
          initializationSettingsAndroid, initializationSettingsIOS);
      flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
      flutterLocalNotificationsPlugin.initialize(initializationSettings);
      await flutterLocalNotificationsPlugin.cancelAll();
    }
    catch (e) {
    }
}


  @override
  void dispose() {
    super.dispose();
    _inSub.cancel();
    _dSub.cancel();
    _sSub.cancel();
    _rSub.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _initDb() async {
    ld.getDb()
    .then((lisDb) async{
      db = lisDb;
      var result = await ld.getQuery(db);
      this.setState(() => queryResult = result);

      // Listeners for online database.
      _rSub = reqRef.onChildAdded.listen(_requestReceived); // New Request
    });
  }

  _requestReceived(Event event) async{
    var key = event.snapshot.key;
    RequestEntry request = RequestEntry.fromSnapshot(event.snapshot);

    await ld.getRoomQuery(db, request.contact)
    .then((localQ) async{
      if (localQ.length == 0){

        var time = DateTime.now().millisecondsSinceEpoch.toString();
        ld.addToDb(db, request, time);
        
        var result = await ld.getQuery(db);
        setState(() => queryResult = result);

        // Deleting request once it is received and processed.
        reqRef.child(key).set(null);
      }
      else {
        reqRef.child(key).set(null);
      }
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
            IconButton(icon: Icon(Icons.menu), onPressed: () {},),
            IconButton(icon: Icon(Icons.search), onPressed: () async {},),
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
          return _buildRow(row['contact'], row['room'], row['cToken']);
        }
        return null;
      }
    );
  }

  Widget _buildRow(String name, String room, String contactNToken) {
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
      onLongPress: () {
        ld.deleteListener(db, name);
      },
      onTap: () {      // Add 9 lines from here...
        setState(() {
          Navigator.push(context, MaterialPageRoute(builder:
          (context) => ConversationScreen(
            user: user,
            contact: name,
            username: username,
            room: room,
            contactNToken: contactNToken,
          )));
        });
      }  
    );
  }

  void createNewMessage() {
    Navigator.push(context, MaterialPageRoute(builder:
    (context) => ContactScreen(
      user: user,
      username: username
    )));
  }



  void initFireMessaging() async {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        var con = message['contact'];
        //TODO refresh and show new message under contact tile.
      },
      onLaunch: (Map<String, dynamic> message) async {
        var con = message['contact'];
        _goToContact(con);
      },
      onResume: (Map<String, dynamic> message) async {
        var con = message['contact'];
        _goToContact(con);
      },
    );
    
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterLocalNotificationsPlugin.cancelAll();
    _checkNotificationToken();
  }

  void _goToContact(String con) async{
    ld.getDb()
    .then((lisDb) async{
      db = lisDb;
      await ld.getRoomQuery(db, con)
      .then((query) {
        var row = query[0];
        String room = row['room'];
        String cNT = row['cToken'];
        Navigator.push(context, MaterialPageRoute(builder:
        (context) => ConversationScreen(
          user: user,
          contact: con,
          username: username,
          room: room,
          contactNToken: cNT,
        )));
      });
    });
  }


  void _checkNotificationToken() async {
    var token = await _firebaseMessaging.getToken()
    .then((String token) {
      assert (token != null);
      _checkRefreshedNotiToken(token);
    });
  }

  void _checkRefreshedNotiToken(String token) async {
    var id = user.uid.toString();
    DocumentSnapshot ds = await Firestore.instance.collection('users').document(id).get();
    var dbToken = ds['n'];
    if (dbToken is String) {
      if (token == dbToken){ //Token matches database. Token is up to date.
        print("NOTIFICATION TOKEN IS UP TO DATE");
      }
      else {
        print("NOTIFICATION TOKEN IS NOT UP TO DATE");
        updateNotiToken(id, token);
      }
    }
    else {
      print("NOTIFICATION TOKEN IS NOT A STRING");
    }
  }

  void updateNotiToken(var id, var token) async {
    print("UPDATING NOTIFICATION TOKEN...");
    try {
      Firestore.instance.collection('users').document(id)
      .updateData({'n': token});  
      print("UPDATING NOTIFICATION TOKEN: SUCCESS");
    } catch (e) {
      print(e.toString());
      print("UPDATING NOTIFICATION TOKEN: FAILURE");
    }
  }
}
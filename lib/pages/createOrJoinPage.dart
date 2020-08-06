// page 2, create room or join a room

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../appBar.dart';
import 'firebaseFunctions.dart';
import 'insertNamePage.dart';
import 'mapRenderPage.dart';
import 'enterCodePage.dart';

Future<void> saveRoomCodePreference(String roomCode) async {
  SharedPreferences roomCodePrefs = await SharedPreferences.getInstance();
  roomCodePrefs.setString("roomCode", roomCode);
}

// to load shared string
Future<String> getRoomCodePreference() async {
  SharedPreferences roomCodePrefs = await SharedPreferences.getInstance();
  String roomCode = roomCodePrefs.getString("roomCode");
  return roomCode;
}

class Page2 extends StatefulWidget {
  //final String name;
  //Page2({Key key, @required this.name}) : super(key: key);
  @override
  _Page2State createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  bool isLoading = false;
  String _name = "";
  final roomCodeController = TextEditingController();
  String roomCode;

  void initState() {
    getNamePreference().then(_updateName);
    super.initState();
  }

  void _updateName(String name) {
    setState(() {
      this._name = name;
    });
  }

  createRoomCode() async {
    // create unique roomCode

    String roomCode = await FirebaseFunctions.createFirebaseRoom(_name);
    roomCode = FirebaseFunctions.roomData["roomCode"];

    setState(() {
      isLoading = true;
    });

    // create a room, send user to room

    //databaseMethods.createMapRoom(roomCode, name);
    print("roomCode is: " + roomCode);
    saveRoomCodePreference(roomCode).then((_) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => MapRender()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffd4f9ff),
      appBar: appBarMain(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(0, 50, 0, 30),
              child: Image(
                image: AssetImage('images/Rendezvous_logo.png'),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "Hello, $_name:" ?? "Name is Null",
                style: new TextStyle(
                  fontSize: 30.0,
                  color: Colors.black,
                ),
              ),
              margin: EdgeInsets.fromLTRB(0, 10.0, 0, 0),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 15.0),
              child: ButtonTheme(
                minWidth: 200.0,
                height: 30.0,
                padding: EdgeInsets.all(10.0),
                buttonColor: Color(0xffcaf7dc),
                child: RaisedButton(
                  child: Text("Create a Room",
                      style:
                          new TextStyle(fontSize: 20.0, color: Colors.black)),
                  onPressed: () {
                    createRoomCode();
//                    Navigator.push(context,
//                        MaterialPageRoute(builder: (context) => MapRender()));
                  },
                ),
              ),
            ),
            ButtonTheme(
              minWidth: 200.0,
              height: 30.0,
              padding: EdgeInsets.all(10.0),
              buttonColor: Color(0xffcaf7dc),
              hoverColor: Color(0xffffccbb),
              child: RaisedButton(
                child: Text("Join a Room",
                    style: new TextStyle(fontSize: 20.0, color: Colors.black)),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Page4()));
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
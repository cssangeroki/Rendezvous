// 8-4, the enter code page

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'page3.dart';
import 'page5.dart';
/*
class Page4 extends StatelessWidget {
  final codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous Page 4'),
      ),
      body: isLoading
          ? Container(child: Center(child: CircularProgressIndicator()))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    minRadius: 170,
                    backgroundImage: AssetImage('images/Rendezvous_logo.png'),
                  ),
                  Container(
                    child: Text(
                      "Enter Code Below:",
                      style: new TextStyle(
                        fontSize: 25.0,
                      ),
                    ),
                    padding: EdgeInsets.all(25.0),
                  ),
                  Container(
                    margin: EdgeInsets.all(5.0),
                    width: 200.0,
                    child: TextField(
                      // connected to textField, listen and save user input
                      controller: codeController,
                      decoration: InputDecoration(hintText: "Enter text here"),
                    ),
                  ),
                ]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn4",
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Page5()));
        },
        child: Text('Page 5'), // to show Go text in button
      ),
    );
  }
}
 */

class Page4 extends StatefulWidget {
  String roomCode;
  Page4({Key key, @required this.roomCode, @required this.name})
      : super(key: key);
  String name;

  @override
  _Page4State createState() => _Page4State(roomCode, name);
}

class _Page4State extends State<Page4> {
  bool isLoading = false;

  final formKey = GlobalKey<FormState>();

  String roomCode;
  String name;

  _Page4State(this.roomCode, this.name);

  final codeController = TextEditingController();

  sendToRoom() {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      // this can be used for future login with firebase
//      Map<String, String> userInfoMap = {
//        "name": userNameTextEditingController.text,
//        "email": userNameTextEditingController.text
//      };

      //databaseMethods.uploadUserInfo(userInfoMap);
      _sendDataToPage3(context);
    }
  }

  void _sendDataToPage3(BuildContext context) {
    String userName = name;
    String chatRoomCode = roomCode;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapRender(
            name: userName,
            roomCode: chatRoomCode,
          ),
        ));
  }

  static Future<bool> checkExist(String roomName) async {
    bool exists = false;
    try {
      await Firestore.instance.document("rooms/$roomName").get().then((doc) {
        if (doc.exists)
          exists = true;
        else
          exists = false;
      });
      return exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous Page 4'),
      ),
      body: isLoading
          ? Container(child: Center(child: CircularProgressIndicator()))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(children: <Widget>[
                  Image(
                    image: AssetImage('images/Rendezvous_logo.png'),
                  ),
                  Container(
                    child: Text(
                      "Enter Code Below:",
                      style: new TextStyle(
                        fontSize: 25.0,
                      ),
                    ),
                    padding: EdgeInsets.all(25.0),
                  ),
                  Container(
                    margin: EdgeInsets.all(5.0),
                    width: 200.0,
                    child: Form(
                      key: formKey,
                      child: TextFormField(
                        onChanged: (text) {
                          roomCode = text;
                        },
                        /*validator: (val) {
                          var check = checkExist(roomCode);
                          return check ? "Please enter a correct code" : null;
                        },*/
                        // connected to textField, listen and save user input
                        controller: codeController,
                        decoration:
                            InputDecoration(hintText: "Enter text here"),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn4",
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          sendToRoom();
//          Navigator.push(
//              context, MaterialPageRoute(builder: (context) => Page5()));
        },
        child: Text('Go'), // to show Go text in button
      ),
    );
  }
}

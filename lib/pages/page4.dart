// 8-4, the enter code page

import 'package:flutter/material.dart';

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
  Page4({Key key, @required this.roomCode}) : super(key: key);

  @override
  _Page4State createState() => _Page4State(roomCode);
}

class _Page4State extends State<Page4> {
  bool isLoading = false;

  final formKey = GlobalKey<FormState>();

  String roomCode;

  _Page4State(this.roomCode);

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
      _sendDataToPage5(context);
    }
  }

  void _sendDataToPage5(BuildContext context) {
    String chatRoomCode = roomCode;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapRender(
            roomCode: chatRoomCode,
          ),
        ));
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
                    child: Form(
                      key: formKey,
                      child: TextFormField(
                        validator: (val) {
                          return val.isEmpty
                              ? "Please enter a correct code"
                              : null;
                        },
                        onChanged: (text) {
                          roomCode = text;
                        },
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

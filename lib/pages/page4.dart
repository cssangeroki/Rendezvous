// 8-4, the enter code page

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebaseFunctions.dart';
import 'firebaseFunctions.dart';
import 'firebaseFunctions.dart';
import 'page3.dart';
import 'page5.dart';

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
  String validationMessage = "Enter a valid code";
  String isValid = "";

  _Page4State(this.roomCode, this.name);

  final codeController = TextEditingController();

  /*sendToRoom() {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });

      _sendDataToPage3(context);
    }
  }*/

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
                        maxLength: 5,
                        validator: (val) {
                          if (val.isEmpty) {
                            return "Please enter a code";
                          }
                          if (val.length != 5) {
                            return "Must be 5 characters long";
                          }
                          if (isValid == 'false') {
                            return (this.validationMessage);
                          }
                          return null;
                        },
                        onChanged: (text) {
                          String msg = null;
                          if (text == "") {
                            msg = "Enter a valid code";
                          }
                          roomCode = text;
                          this.setState(() {
                            roomCode = text;
                            validationMessage = msg;
                          });
                        },
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
        onPressed: () async {
          if (formKey.currentState.validate()) {
            setState(() {
              isLoading = true;
            });
            bool isSuccess =
                await FirebaseFunctions.addCurrentUserToRoom(this.roomCode);
            if (isSuccess) {
              await FirebaseFunctions.refreshFirebaseRoomData();
//              sendToRoom();
              _sendDataToPage3(context);
            } else {
              setState(() {
                isLoading = false;
                isValid = 'false';
                print('code not valid');
                validationMessage = "Invalid code entered";
              });
              this.setState(() {
                validationMessage = "Invalid code entered";
              });
            }
          }
        },
        child: Text('Go'), // to show Go text in button
      ),
    );
  }
}

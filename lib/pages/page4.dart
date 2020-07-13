// 8-4, the enter code page

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'page3.dart';

class Page4 extends StatefulWidget {
  String roomCode;
  Page4({Key key, @required this.roomCode, @required this.name})
      : super(key: key);
  String name;

  @override
  _Page4State createState() => _Page4State(roomCode);
}

class _Page4State extends State<Page4> {
  bool isLoading = false;

  @override
  final formKey = GlobalKey<FormState>();
  final firestoreInstance = Firestore.instance;
  String roomCode;
  String roomCodeValidate = "";

  _Page4State(this.roomCode);

  final codeController = TextEditingController();

  checkIfRoomValid(roomCodeValidate) {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });

      // find roomCode on firebase
      Firestore.instance
          .collection('rooms')
          .where('roomCode', isEqualTo: roomCodeValidate)
          .getDocuments()
          .then((QuerySnapshot docs) {
        if (docs.documents.isNotEmpty) {
          print('room found');
          _sendToRoom(context);
        } else if (docs.documents.isEmpty) {
          // still working on code for this condition
          print('room not found');
        }
      });
    }
  }

  void _sendToRoom(BuildContext context) {
    //String chatRoomCode = roomCode;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapRender(),
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
                        validator: (val) {
                          return val.isEmpty
                              ? "Please enter a correct code"
                              : null;
                        },
                        onChanged: (text) {
                          roomCodeValidate = text;
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
          checkIfRoomValid(roomCodeValidate);
//          Navigator.push(
//              context, MaterialPageRoute(builder: (context) => Page5()));
        },
        child: Text('Go'), // to show Go text in button
      ),
    );
  }
}

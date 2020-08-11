// page 1, this is start/home page

import 'package:Rendezvous/pages/firebaseFunctions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../appBar.dart';
import 'createOrJoinPage.dart';

Future<void> saveNamePreference(String userName) async {
  SharedPreferences userNamePrefs = await SharedPreferences.getInstance();
  userNamePrefs.setString("userName", userName);
}

// to load shared string
Future<String> getNamePreference() async {
  SharedPreferences userNamePrefs = await SharedPreferences.getInstance();
  String userName = userNamePrefs.getString("userName");
  return userName;
}

class Page1 extends StatefulWidget {
  //String userName;
  //Page1({Key key, @required this.userName}) : super(key: key);

  @override
  _Page1State createState() => _Page1State();
}

class _Page1State extends State<Page1> {
//  bool isLoading = false;

  final formKey = GlobalKey<FormState>();

  //_Page1State(this.userName);
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final userNameController = TextEditingController();
  String userName;

  // checks if name is valid then saves name and sends to page2
  void _signMeUp() {
    if (formKey.currentState.validate()) {
      String userName = userNameController.text;
      saveNamePreference(userName).then((_) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Page2()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      backgroundColor: Color(0xffd4f9ff),
      appBar: appBarMain(context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            child: Column(children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(0, 50, 0, 30),
                child: Image(
                  image: AssetImage('images/Rendezvous_logo.png'),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                child: Text(
                  "Enter a display name:",
                  style: buttonTextSize30(),
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 20.0, 0, 0),
                width: 300.0,
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    validator: (val) {
                      return val.isEmpty ? "Please Enter a Name" : null;
                    },
                    controller: userNameController,
                    onChanged: (text) {
                      userName = text;
                      FirebaseFunctions.currentUserData["userName"] = text;
                    },
                    decoration: InputDecoration(hintText: 'Enter text here'),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn1",
        backgroundColor: Color(0xffffccbb),
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          _signMeUp();
        },
        child: Text(
          'Go',
          style: TextStyle(color: Colors.black),
        ), // to show Go text in button
      ),
    );
  }
}

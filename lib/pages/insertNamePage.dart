// page 1, this is start/home page

import 'package:Rendezvous/pages/firebaseFunctions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../appBar.dart';
import 'createOrJoinPage.dart';
import '../globalVar.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Column(children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).size.height * 0.4, 0, 0),
                  width: 200.0,
                  child: Form(
                    key: formKey,
                    child: TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                      validator: (val) {
                        return val.isEmpty ? "Please Enter a Name" : null;
                      },
                      controller: userNameController,
                      onChanged: (text) {
                        userName = text;
                        FirebaseFunctions.currentUserData["userName"] = text;
                      },
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                FloatingActionButton.extended(
                  label: Text('Go'),
                  heroTag: "btn1",
                  // When the user presses the button, show an alert dialog containing
                  // the text that the user has entered into the text field.
                  onPressed: () {
                    _signMeUp();
                  },
                  icon: Icon(Icons.check), // to show Go text in button
                ),
              ]),
            ),
          ),
        ),
      ),
      backgroundColor: Color(Global.backgroundColor),
    );
  }
}

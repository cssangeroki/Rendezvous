// page 1, this is start/home page

import 'package:Rendezvous/pages/firebaseFunctions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _nameEntered = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  final formKey = GlobalKey<FormState>();

  //_Page1State(this.userName);
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final userNameController = TextEditingController();
  String userName;

  // checks if name is valid then saves name and sends to page2
  void _signMeUp() {
    setState(() {
      if (formKey.currentState.validate()) {
        String userName = userNameController.text;
        saveNamePreference(userName).then((_) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation1, animation2) => Page2(),
              transitionsBuilder: (context, animation1, animation2, child) =>
                  FadeTransition(opacity: animation1, child: child),
              transitionDuration: Duration(milliseconds: 300),
            ),
          );
        });
      }
    });
  }

  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            child: Center(
              child: Column(children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(
                      0, MediaQuery.of(context).size.height * 0.4, 0, 0),
                  width: 220.0,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 100),
                    opacity: _nameEntered ? 0.0 : 1.0,
                    child: Form(
                      key: formKey,
                      child: TextFormField(
                        style: TextStyle(fontSize: 25),
                        maxLength: 15,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: GoogleFonts.roboto(fontSize: 18),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                        ),
                        validator: (val) {
                          if (val == "") {
                            return "Please enter a name";
                          }
                          return null;
                        },
                        controller: userNameController,
                        onChanged: (text) {
                          userName = text;
                          FirebaseFunctions.currentUserData["userName"] = text;
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  height: 50,
                  width: 100,
                  child: RaisedButton(
                      onPressed: () {
                        _signMeUp();
                      },
                      color: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        //side: BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        "Go",
                        style: GoogleFonts.roboto(
                            fontSize: 20, color: Colors.white),
                      )),
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

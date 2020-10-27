// page 1, this is start/home page

import 'package:Rendezvous/pages/firebaseFunctions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'createOrJoinPage.dart';
import '../globalVar.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  File imagePicked;
  final picker = ImagePicker();

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
  final userNameController = new TextEditingController(text: Global.userName ?? "");

  
  String userName = Global.userName ?? "";

  String userImageSaved = FirebaseFunctions.currentUserData["profileImage"];

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

  Future getImage() async {

    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if(pickedFile != null) {
        setState(() {
            imagePicked = File(pickedFile.path);
        });

        userImageSaved = null;
        Global.profileImage = File(pickedFile.path);
        Global.profileImageURL = pickedFile.path;
        Global.updateProfileImage = true;
    }
  }
  

  @override
  Widget build(BuildContext context) {
    // screen height
    var screenHeight = MediaQuery.of(context).size.height;
    // did you choose an image
    // var showAnonymous = imagePicked == null ? true : false;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            child: Center(
              child: Column(
                  children: <Widget>[
                /*GestureDetector(
                  onTap: () {
                    getImage();
                  },
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, screenHeight * 0.2, 0, 0),
                    width: screenHeight * 0.2,
                    height: screenHeight * 0.2,
                    child: showAnonymous
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(100.0),
                            child: Image(
                              image: userImageSaved != null ? NetworkImage(userImageSaved) : AssetImage('images/anonymous.png'),
                            ),
                          )
                        : null,
                    decoration: !showAnonymous
                        ? new BoxDecoration(
                            shape: BoxShape.circle,
                            image: new DecorationImage(
                                fit: BoxFit.cover,
                                image: new FileImage(imagePicked)))
                        : null,
                  ),
                ),
                CupertinoButton(
                    child: Text("Choose Profile Image"),
                    onPressed: () {
                      getImage();
                    }),*/
                Container(
                  margin: EdgeInsets.fromLTRB(0, screenHeight * 0.35, 0, 0),
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
                          if (val == "" || val == null) {
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

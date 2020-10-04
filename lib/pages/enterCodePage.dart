// 8-4, the enter code page

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globalVar.dart';
import '../appBar.dart';
import 'firebaseFunctions.dart';
import 'firebaseFunctions.dart';
import 'mapRenderPage.dart';
import 'package:flutter_fadein/flutter_fadein.dart';

bool loadingScreen = false;

class Page4 extends StatefulWidget {
  final String roomCode;
  Page4({Key key, this.roomCode, this.name}) : super(key: key);
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

  final textController = FadeInController();
  final codeAnimController = FadeInController();
  final buttonController = FadeInController();
  _Page4State(this.roomCode, this.name);

  final codeController = TextEditingController();

  void _sendDataToPage3(BuildContext context) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MapRender(),
        ));
  }

  Future<bool> _fadeInFunc() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        textController.fadeIn();
      });
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        codeAnimController.fadeIn();
      });
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        buttonController.fadeIn();
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _fadeInFunc();
    loadingScreen = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return (loadingScreen == true)
        ? Container(
            decoration: BoxDecoration(
              color: Color(Global.backgroundColor),
            ),
            child: Center(
              child: SpinKitPulse(
                size: 280,
                color: Colors.black38,
              ),
            ),
          )
        : Scaffold(
            appBar: appBarMain(context),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: Column(children: <Widget>[
                    FadeIn(
                      controller: textController,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(0,
                            MediaQuery.of(context).size.height * 0.25, 0, 20),
                        child: Text(
                          "Enter Code Below:",
                          style: GoogleFonts.roboto(fontSize: 25),
                        ),
                      ),
                    ),
                    FadeIn(
                      controller: codeAnimController,
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                        width: 200.0,
                        child: Form(
                          key: formKey,
                          child: TextFormField(
                            maxLength: 5,
                            decoration: InputDecoration(
                              hintText: 'e.g. abcde',
                              hintStyle: GoogleFonts.roboto(fontSize: 18),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
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
                              String msg;
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
                          ),
                        ),
                      ),
                    ),
                    FadeIn(
                      controller: buttonController,
                      child: Container(
                        height: 50,
                        width: 100,
                        child: RaisedButton(
                          color: Colors.black54,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            //side: BorderSide(color: Colors.grey),
                          ),
                          child: Text(
                            "Go",
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                          // When the user presses the button, show an alert dialog containing
                          // the text that the user has entered into the text field.
                          onPressed: () async {
                            if (formKey.currentState.validate()) {
                              setState(() {
                                loadingScreen = true;
                              });
                              print("Before");
                              bool isSuccess =
                                  await FirebaseFunctions.addCurrentUserToRoom(
                                      this.roomCode);
                              print("After");
                              print(isSuccess);
                              if (isSuccess) {
                                await FirebaseFunctions
                                    .refreshFirebaseUserData();
                                await FirebaseFunctions
                                    .refreshFirebaseRoomData();
//              sendToRoom();
                                _sendDataToPage3(context);
                              } else {
                                setState(() {
                                  loadingScreen = false;
                                  isValid = 'false';
                                  validationMessage = "Invalid code entered";
                                  print('code not valid');
                                });
                                this.setState(() {
                                  validationMessage = "Invalid code entered";
                                });
                              }
                            }
                          },
                          // to show Go text in button
                        ),
                      ),
                    ),
                    SizedBox(height: 30)
                  ]),
                ),
              ),
            ),
          );
  }
}

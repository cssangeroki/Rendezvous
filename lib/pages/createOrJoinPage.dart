// page 2, create room or join a room

import 'package:Rendezvous/pages/enterCodePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_fadein/flutter_fadein.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../appBar.dart';
import 'firebaseFunctions.dart';
import 'insertNamePage.dart';
import 'mapRenderPage.dart';

import '../globalVar.dart';

bool loadingScreen = false;

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
    _fadeInFunc();
    loadingScreen = false;
  }

  void _updateName(String name) {
    setState(() {
      this._name = name;
    });
  }

  _createRoomCode() async {
    setState(() {
      loadingScreen = true;
    });

    // create unique roomCode

    String roomCode = await FirebaseFunctions.createFirebaseRoom(_name);
    roomCode = FirebaseFunctions.roomData["roomCode"];

    // create a room, send user to room

    //databaseMethods.createMapRoom(roomCode, name);
    print("roomCode is: " + roomCode);
    saveRoomCodePreference(roomCode).then((_) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => MapRender(),
          transitionsBuilder: (context, animation1, animation2, child) =>
              FadeTransition(opacity: animation1, child: child),
          transitionDuration: Duration(milliseconds: 300),
        ),
      );
    });
  }

  final nameController = FadeInController();
  final button1Controller = FadeInController();
  final button2Controller = FadeInController();
  bool _absorb = true;
  Future<bool> _fadeInFunc() {
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        nameController.fadeIn();
      });
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        button1Controller.fadeIn();
      });
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        button2Controller.fadeIn();
      });
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      setState(() {
        _absorb = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return (loadingScreen == true)
        ? Container(
            color: Color(Global.backgroundColor),
            /*decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/Map_loading.png"),
                fit: BoxFit.cover,
              ),
            ),*/
            child: Center(
              child: SpinKitPulse(
                size: 280,
                color: Colors.black38,
              ),
            ),
          )
        : Scaffold(
            appBar: appBarMain(context),
            backgroundColor: Color(Global.backgroundColor),
            body: SafeArea(
              child: AbsorbPointer(
                absorbing: _absorb,
                child: SingleChildScrollView(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(children: <Widget>[
                        FadeIn(
                          controller: nameController,
                          duration: Duration(milliseconds: 800),
                          curve: Curves.easeIn,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                                10,
                                MediaQuery.of(context).size.height * 0.29,
                                10,
                                20),
                            child: Text(
                              "Hello, $_name" ?? "Name is Null",
                              style: GoogleFonts.roboto(fontSize: 28),
                              overflow: TextOverflow.fade,
                              softWrap: true,
                            ),
                          ),
                        ),
                        FadeIn(
                          controller: button1Controller,
                          // Optional paramaters
                          duration: Duration(milliseconds: 800),
                          curve: Curves.easeIn,
                          child: Container(
                            margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Container(
                              height: 50,
                              width: 160,
                              child: RaisedButton(
                                  elevation: 3,
                                  onPressed: () {
                                    _createRoomCode();
                                  },
                                  color: Colors.black54,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    //side: BorderSide(color: Colors.grey),
                                  ),
                                  child: Text(
                                    "Create Room",
                                    style: GoogleFonts.roboto(
                                        fontSize: 20, color: Colors.white),
                                  )),
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        FadeIn(
                          controller: button2Controller,
                          duration: Duration(milliseconds: 1000),
                          curve: Curves.easeIn,
                          child: Container(
                            height: 50,
                            width: 160,
                            margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                            child: RaisedButton(
                                elevation: 3,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (context, animation1, animation2) =>
                                              Page4(),
                                      transitionsBuilder: (context, animation1,
                                              animation2, child) =>
                                          FadeTransition(
                                              opacity: animation1,
                                              child: child),
                                      transitionDuration:
                                          Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30.0),
                                    side: BorderSide(color: Colors.grey)),
                                child: Text(
                                  "Join Room",
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    color: Colors.black,
                                  ),
                                )),
                          ),
                        ),

                        /*ButtonTheme(
                  minWidth: 200.0,
                  height: 30.0,
                  padding: EdgeInsets.all(10.0),
                  buttonColor: Color(0xffcaf7dc),
                  hoverColor: Color(0xffffccbb),
                  child: RaisedButton(
                    child: Text("Join a Room", style: textSize20()),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Page4()));
                    },
                  ),
                ),*/
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}

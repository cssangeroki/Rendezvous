import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/firebaseFunctions.dart';
import 'pages/insertNamePage.dart';
import 'pages/mapRenderPage.dart';
import 'globalVar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  //runApp(MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _signInAnonymously();
  runApp(MyApp());
}

Future<void> _signInAnonymously() async {
  try {
    final UserCredential result = await FirebaseAuth.instance.signInAnonymously();
    User user = result.user;
    if (user == null){
      print("Error writing user to the database");
    }
    else{
      print(FirebaseFunctions.currentUID);
    }
    FirebaseFunctions.currentUID = user.uid;

    await FirebaseFunctions.refreshFirebaseUserData();
    await FirebaseFunctions.refreshFirebaseRoomData();
  } catch (e) {
    print("Error writing user to database");
    print(e);
  }
}

void pushToHomeScreen(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => MapRender()));
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    String initialRoute = '/page1';
    if (FirebaseFunctions.currentUserData["roomCode"] != null) {
      initialRoute = '/map';
    }
    return MaterialApp(
        title: 'Retrieve Text Input',
        theme: ThemeData(
          scaffoldBackgroundColor: Color(Global.backgroundColor),
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false,
        home: Page1(),
        routes: {
          '/map': (BuildContext context) => MapRender(),
          '/page1': (BuildContext context) => Page1()
        },
        initialRoute: initialRoute);
  }
}

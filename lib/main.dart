import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/firebaseFunctions.dart';
import 'pages/page1.dart';
import 'pages/page3.dart';

import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  //runApp(MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await _signInAnonymously();
  runApp(MyApp());
}

Future<void> _signInAnonymously() async {
  try {
    final AuthResult result = await FirebaseAuth.instance.signInAnonymously();
    FirebaseUser user = result.user;
    FirebaseFunctions.currentUID = user.uid;

    await FirebaseFunctions.refreshFirebaseUserData();
    await FirebaseFunctions.refreshFirebaseRoomData();
  } catch (e) {
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
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'Goldplay',
                fontSizeFactor: 1.1,
                fontSizeDelta: 2.0,
              ),
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

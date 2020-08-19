import 'package:flutter/material.dart';

Widget appBarMain(BuildContext context) {
  return AppBar(
    brightness: Brightness.light,
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
    title: Text(
      'Rendezvous',
      style: TextStyle(color: Colors.black, fontFamily: 'Goldplay'),
    ),
    backgroundColor: Color(0xfffddd75),
  );
}

//InputDecoration textFieldDecoration(String hintText) {
//  return InputDecoration(hintText: hintText);
//}
TextStyle buttonTextSize30() {
  return TextStyle(fontSize: 30.0, color: Colors.black);
}

TextStyle buttonTextSize25() {
  return TextStyle(fontSize: 25.0, color: Colors.black);
}

TextStyle buttonTextSize20() {
  return TextStyle(fontSize: 20.0, color: Colors.black);
}

TextStyle TextSize15() {
  return TextStyle(
      fontSize: 15.0, color: Colors.blueAccent, fontWeight: FontWeight.bold);
}

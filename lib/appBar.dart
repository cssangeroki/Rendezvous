import 'package:flutter/material.dart';
import 'globalVar.dart';

Widget appBarMain(BuildContext context) {
  return AppBar(
    elevation: 0,
    //toolbarHeight: 90,
    brightness: Brightness.light,
    iconTheme: IconThemeData(
      color: Colors.black,
    ),
    backgroundColor: Color(Global.backgroundColor),
  );
}

//InputDecoration textFieldDecoration(String hintText) {
//  return InputDecoration(hintText: hintText);
//}

TextStyle textSize35() {
  return TextStyle(fontSize: 35.0, color: Colors.black);
}

TextStyle textSize30() {
  return TextStyle(fontSize: 35.0, color: Colors.black, fontFamily: 'Goldplay');
}

TextStyle buttonTextSize30() {
  return TextStyle(fontSize: 30.0, color: Colors.black);
}

TextStyle buttonTextSize25() {
  return TextStyle(fontSize: 25.0, color: Colors.black);
}

TextStyle textSize20() {
  return TextStyle(fontSize: 20.0, color: Colors.black);
}

TextStyle textSize18() {
  return TextStyle(fontSize: 18.0, color: Colors.black);
}

TextStyle textSize18Alpha() {
  return TextStyle(
    fontSize: 18.0,
    fontFamily: 'GoldPlay',
    color: Colors.black.withAlpha(200),
  );
}

TextStyle textSize15Black45() {
  return TextStyle(
      fontSize: 15.0, color: Colors.black45, fontWeight: FontWeight.bold);
}

TextStyle textSize15Grey() {
  return TextStyle(
      fontSize: 15.0, color: Color((0xff757575)), fontWeight: FontWeight.bold);
}

TextStyle textSize15Blue() {
  return TextStyle(
      fontSize: 15.0, color: Colors.blueAccent, fontWeight: FontWeight.bold);
}

TextStyle textSize12Grey() {
  return TextStyle(
      fontSize: 12.0, color: Colors.grey, fontWeight: FontWeight.w500);
}

BorderRadius onlyTop20() {
  return BorderRadius.only(
      topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0));
}

BorderRadius onlyTop10() {
  return BorderRadius.only(
      topLeft: Radius.circular(10.0), topRight: Radius.circular(10.0));
}

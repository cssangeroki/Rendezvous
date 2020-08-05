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
    backgroundColor: Color(0xffcaf7dc),
  );
}

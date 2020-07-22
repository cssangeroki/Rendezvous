//map 8-6
import 'package:flutter/material.dart';

class Page6 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous Page 6'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn6",
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
//          Navigator.push(
//              context,
//              MaterialPageRoute(
//                  builder: (context) => Page1(
//                        userName: "Test",
//                      ))
//                      );
        },
        child: Text('Home'), // to show Go text in button
      ),
    );
  }
}

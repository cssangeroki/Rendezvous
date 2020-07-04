// 8-4, the enter code page

import 'package:flutter/material.dart';

import 'page3.dart';
import 'page5.dart';

class Page4 extends StatelessWidget {
  final codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous Page 4'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.blueGrey,
              minRadius: 170,
              backgroundImage: AssetImage('images/Rendezvous_logo.png'),
            ),
            TextField(
              decoration: InputDecoration(hintText: 'Enter Code:'),
              // connected to textField, listen and save user input
              controller: codeController,
            ),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn4",
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Page5()));
        },
        child: Text('Page 5'), // to show Go text in button
      ),
    );
  }
}

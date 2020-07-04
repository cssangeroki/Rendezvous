// page 2, create room or join a room

import 'package:flutter/material.dart';
import 'page1.dart';
import 'page3.dart';
import 'page4.dart';

class Page2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous page 2'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.blueGrey,
              minRadius: 170,
              backgroundImage: AssetImage('images/Rendezvous_logo.png'),
            ),
            Card(
              child: Row(
                children: <Widget>[
                  //print(_userNameController.text)
                  Center(
                      child: Text('nameEntered')), // to be fixed with database
                ],
              ),
            ),
          ]),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          FloatingActionButton(
            heroTag: "btn2.1",
            // When the user presses the button, show an alert dialog containing
            // the text that the user has entered into the text field.
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Page1()));
            },
            child: Text('Page 1'), // to show Go text in button
          ),
          FloatingActionButton(
            heroTag: "btn2.2",
            // When the user presses the button, show an alert dialog containing
            // the text that the user has entered into the text field.
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MapRender()));
            },
            child: Text('MapRender'), // to show Go text in button
          ),
        ],
      ),
    );
  }
}

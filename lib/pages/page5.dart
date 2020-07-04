//map 8-5
import 'package:flutter/material.dart';

import 'page6.dart';

class Page5 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous Page 5'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn5",
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => Page6()));
        },
        child: Text('Page 6'), // to show Go text in button
      ),
    );
  }
}

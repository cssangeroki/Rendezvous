// page 2, create room or join a room

import 'package:flutter/material.dart';

import 'page4.dart';
import 'page3.dart';

class Page2 extends StatelessWidget {
  final String name;
  Page2({Key key, @required this.name}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous page 2'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: <Widget>[
            Image(
              image: AssetImage('images/Rendezvous_logo.png'),
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: Text(
                "Hello, ${name}:" ?? "Name is Null",
                style: new TextStyle(
                  fontSize: 30.0,
                  color: Colors.black,
                ),
              ),
              margin: EdgeInsets.fromLTRB(0, 10.0, 0, 0),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 15.0),
              child: ButtonTheme(
                minWidth: 200.0,
                height: 30.0,
                padding: EdgeInsets.all(10.0),
                buttonColor: Colors.white,
                child: RaisedButton(
                  child: Text("Create a Room",
                      style:
                          new TextStyle(fontSize: 20.0, color: Colors.black)),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MapRender(
                                  name: name,
                                )));
                  },
                ),
              ),
            ),
            ButtonTheme(
              minWidth: 200.0,
              height: 30.0,
              padding: EdgeInsets.all(10.0),
              buttonColor: Colors.white,
              hoverColor: Colors.grey,
              child: RaisedButton(
                child: Text("Join a Room",
                    style: new TextStyle(fontSize: 20.0, color: Colors.black)),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Page4(name: name)));
                },
              ),
            ),
          ]),
        ),
      ),

      /*floatingActionButton: Row(
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
      */
    );
  }
}

import 'package:flutter/material.dart';
import './people.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retrieve Text Input',
      home: MyCustomForm(),
    );
  }
}

// Define a custom Form widget.
class MyCustomForm extends StatefulWidget {
  @override
  _MyCustomFormState createState() => _MyCustomFormState();
}

// Define a corresponding State class.
// This class holds the data related to the Form.
class _MyCustomFormState extends State<MyCustomForm> {
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  final List<People> people = [People(name: 'john')];
  String nameInput; // name variable to be stored

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous Home Page'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: Colors.blueGrey,
              minRadius: 170,
              backgroundImage: AssetImage('images/Rendezvous_logo.png'),
            ),
            Card(
              elevation: 5,
              shadowColor: Colors.blue,
              child: Container(
                //padding: EdgeInsets.symmetric(horizontal: 35.0),
                child: TextField(
                  decoration: InputDecoration(hintText: 'Enter Your Name:'),
                  onChanged: (value) {
                    nameInput = value;
                  },
                ),
              ),
            ),
            // Text(
            // 'Enter Your Name:',
            // style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
            // ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 35.0),
            //   child: TextField(
            //     controller: myController,
            //   ),
            // ),
            RaisedButton(
              elevation: 5,
              child: Text('GO'),
              textColor: Colors.red,
              color: Colors.white,
              onPressed: () {
                return Card(
                  child: Text(nameInput),
                );
                //print(nameInput);
              },
            ),
            Column(
              // displays name on screen
              children: people.map((tx) {
                return Card(
                  child: Text(nameInput),
                );
              }).toList(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                // Retrieve the text the that user has entered by using the
                // TextEditingController.
                content: Text(myController.text),
              );
            },
          );
        },
        tooltip: 'Show me the value!',
        child: Text('Go'), // to show Go text in button
        // child: Icon(Icons.text_fields),
      ),
    );
  }
}

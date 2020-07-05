// page 1, this is start/home page

import 'package:flutter/material.dart';

import 'page2.dart';

class Page1 extends StatefulWidget {
  String userName;
  Page1({Key key, @required this.userName}) : super(key: key);

  @override
  _Page1State createState() => _Page1State(userName);
}

class _Page1State extends State<Page1> {
  bool isLoading = false;

  // for firebase data storage
  //DatabaseMethods databaseMethods = new DatabaseMethods();

  final formKey = GlobalKey<FormState>();

  String userName;

  _Page1State(this.userName);
  // Create a text controller and use it to retrieve the current value
  // of the TextField.
  final userNameController = TextEditingController();

//  TextEditingController userNameTextEditingController =
//      new TextEditingController();

  signMeUp() {
    if (formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      // this can be used for future login with firebase
//      Map<String, String> userInfoMap = {
//        "name": userNameTextEditingController.text,
//        "email": userNameTextEditingController.text
//      };

      //databaseMethods.uploadUserInfo(userInfoMap);
      _sendDataToPage2(context);
    }
  }

  void _sendDataToPage2(BuildContext context) {
    String personName = userName;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Page2(
            name: personName,
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rendezvous (Home Page)'),
      ),
      body: isLoading
          ? Container(child: Center(child: CircularProgressIndicator()))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    minRadius: 160,
                    backgroundImage: AssetImage('images/Rendezvous_logo.png'),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                    child: Text(
                      "Enter a display name:",
                      style: TextStyle(
                        fontSize: 30.0,
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 20.0, 0, 0),
                    width: 300.0,
                    child: Form(
                      key: formKey,
                      child: TextFormField(
                        validator: (val) {
                          return val.isEmpty ? "Please Enter a Name" : null;
                        },
                        onChanged: (text) {
                          userName = text;
                        },
                        //controller: userNameController,
                        decoration:
                            InputDecoration(hintText: 'Enter text here'),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn1",
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          signMeUp();
        },
        child: Text('Go'), // to show Go text in button
      ),
    );
  }
}

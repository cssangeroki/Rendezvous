import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:share/share.dart';
import 'pages/firebaseFunctions.dart';

//This will be used for the share button for the room code and address
class ShareButton extends StatelessWidget{
  ShareButton(this.hintString, this.sendText);
  final String hintString;
  final String sendText;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 80,
      padding: EdgeInsets.fromLTRB(60, 0, 60, 0),
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: RaisedButton(
        color: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(hintString,
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: () {Share.share(
          sendText,
        );
        }
      ),
    );
  }
}

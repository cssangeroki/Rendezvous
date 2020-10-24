//This file will be used to create error checking and feedback widgets

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'globalVar.dart';

//import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:url_launcher/url_launcher.dart';
//import 'pages/firebaseFunctions.dart';

class AddressSearchBarError extends StatefulWidget {
  @override
  _AddressSearchBarErrorState createState() => _AddressSearchBarErrorState();
}

class _AddressSearchBarErrorState extends State<AddressSearchBarError> {
  @override
  void initState() {
    super.initState();
    listenToSearchAddressError();
  }

  void listenToSearchAddressError() {
    Global.errorFindingUserAddressListener.addListener(() {
      if (!mounted){
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    Global.errorFindingUserAddressListener.removeListener(() {});
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Global.errorFindingUserAddress == false
        ? Container(
            height: 50.0,
          )
        : Container(
            height: 50.0,
            child: Text(
              "Sorry. It seems that there was a problem trying to find the location you entered. Please try again, or enter a location close to your desired address",
              style: TextStyle(color: Colors.grey),
            ),
          );
  }
}

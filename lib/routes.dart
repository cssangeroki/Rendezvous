//This file will be used to add the routes widget.
//This will allow the user to route to the final location by pressing a button
// and opening up the built in maps application (Maps for Apple, Google Maps for Android)

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'globalVar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/firebaseFunctions.dart';

class Routes extends StatelessWidget {
  Future<void> launchMap() async {
    //First, we will store the final LatLng in a local variable
    GeoPoint tempFinal = FirebaseFunctions.roomData["Final LatLng"];
    LatLng finalDest = LatLng(tempFinal.latitude, tempFinal.longitude);
    String mapUrl = '';
    //Now, we check if the device is apple or android
    //If it's Android, set the Url to google maps
    if (Platform.isAndroid) {
      mapUrl =
          "https://www.google.com/maps/search/?api=1&query=${finalDest.latitude},${finalDest.longitude}";
    }
    //Else, it must be apple, so we set the Url to apple Maps
    else {
      mapUrl =
          "https://maps.apple.com/?q=${finalDest.latitude},${finalDest.longitude}";
    }
    //Now, we simply want to try loading the maps
    if (await canLaunch(mapUrl)) {
      await launch(mapUrl);
    } else {
      throw 'Could not launch $mapUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 100,
      padding: EdgeInsets.fromLTRB(60, 0, 60, 0),
      margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: RaisedButton(
        color: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text("Route",
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: () async {
          await launchMap();
        },
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:async';

import 'package:Rendezvous/globalVar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
//Will use these import for autocompleting text
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:Rendezvous/pages/firebaseFunctions.dart';
const String mapsAPI_KEY = "AIzaSyBV961Ztopz9vyZrJq0AYAMJUTHmluu3FM";


//This class will be used to create the final location search bar for the user, with autocomplete
//It accepts a boolean as argument, which will determine whether the search bar is being used for the final location or not
class FinalLocationSearchBar extends StatefulWidget {
  // final bool finalLoc;
  // const FinalLocationSearchBar(this.finalLoc);
  @override
  _FinalLocationSearchBarState createState() => _FinalLocationSearchBarState();
}

class _FinalLocationSearchBarState extends State<FinalLocationSearchBar> {

  List<String> suggestedAddresses = [];
  AutoCompleteTextField addressSearchField;
  GlobalKey<AutoCompleteTextFieldState> key = new GlobalKey();
  String newAddress;
  bool isFinalLoc;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //isFinalLoc = widget.finalLoc;
  }
  //This function will be used to notify the maps page when the user changes their address
  void finalAddressChanged() async{
    //Need to first write the new address to the database, then alert the value notifier
    var response = await http.post(
        "https://maps.googleapis.com/maps/api/geocode/json?address=$newAddress&key=$mapsAPI_KEY");
    if (response.statusCode == 200) {
      var decoded = await convert.jsonDecode(response.body);
      //Get the placemark from the search address, and then store it in _center
      LatLng finalLatLng = LatLng(
          decoded['results'][0]['geometry']['location']['lat'],
          decoded['results'][0]['geometry']['location']['lng']);
      FirebaseFunctions.setFinalPosition("", newAddress, finalLatLng);
      Global.finalLocationChanged.value ^= true;
    }
    else{
      print("Need to add error checking here");
    }
  }

  Future<void> autoCompleteSuggestions(String searchString) async {
    //First thing we will do is clear suggestedAddresses List
    suggestedAddresses.clear();
    if (searchString == "" || searchString == null) {
      return;
    }
    //Searching for places similar to the location being searched. Biased to 100km radius of the user current location
    var response = await http.post(
        "https://maps.googleapis.com/maps/api/place/queryautocomplete/json?key=$mapsAPI_KEY&location=${Global
            .userPos.latitude},${Global.userPos
            .longitude}&radius=100000&input=$searchString");
    if (response.statusCode == 200) {
      var decoded = await convert.jsonDecode(response.body);
      //If the we the http request fails, let the user know we are unable to find any suggestions
      if (decoded['status'] != 'OK') {
        suggestedAddresses.add("Unable to find any suggestions");
        return;
      }
      //Otherwise, I will set a variable as the predictions category for the user
      var predictions = decoded['predictions'];
      //Add the top 5 suggestions to our List of suggestedAddresses
      setState(() {
        for (int i = 0; i < 5; i++) {
          try {
            suggestedAddresses.add(predictions[i]["description"]);
          } catch (e) {
            //If there is an error adding a prediction, simply break and only display the predictions added so far
            break;
          }
        }
      });
    }
  }

  //This widget will be used to display the hints
  Widget suggestedHints(String hint) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
            child: Text(
              hint,
              style: TextStyle(fontSize: 16.0, color: Colors.lightBlue),
              softWrap: true,
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
      height: 50.0,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.white,
      ),
      child: addressSearchField = AutoCompleteTextField(
        key: key,
        clearOnSubmit: false,
        //Suggestions that will be shown
        suggestions: suggestedAddresses,
        //Filters results suggested
        itemFilter: (item, query) {
          return item.toString().toLowerCase().startsWith(query.toLowerCase());
        },
        //Sorts suggestions
        itemSorter: (a, b) {
          return a.toString().compareTo(b.toString());
        },
        itemSubmitted: (item) {
          setState(() {
            addressSearchField.textField.controller.text = item;
            newAddress = item;
            Global.userAddress = newAddress;
            finalAddressChanged();
          });
        },
        //UI for each row of suggestions
        itemBuilder: (context, item) {
          return suggestedHints(item);
        },
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            hintText: "Enter your address...",
            contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                //This line is used to remove the keyboard whenever the search button is pressed
                FocusManager.instance.primaryFocus.unfocus();
                //Needs this check in case user hits search without entering anything
                if (newAddress == null) {
                  return;
                }
                Global.userAddress = newAddress;
                finalAddressChanged();
                //Navigator.pop(context);
              },
              iconSize: 30.0,
            )),
        textChanged: (val) {
          setState(() {
            newAddress = val;
            autoCompleteSuggestions(val);
          });
        },
      ),
    );
  }
}


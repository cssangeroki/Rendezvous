//This file will hold the MapRenderState class

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//import 'package:geoflutterfire/geoflutterfire.dart';
import 'pages/firebaseFunctions.dart';
import 'dart:async';

//import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'src/locations.dart' as locations;

import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//import 'firebaseFunctions.dart';
//import 'page4.dart';

//import "pages/page3.dart";
//import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'backendFunctions.dart';
import 'dart:convert';
import 'package:link/link.dart';

double finalLon;
double finalLat;

String finalCatagory;
// double finalRad;

List resultCords = [];
List names = [];
List locations = [];
List urls = [];
List images = [];
//A string that will store the category searched for on the Yelp search
String category;

//Below are variables we will use for the sliders
double midSliderVal = 5;
double finalRad = midSliderVal;

double userSliderVal = 5;

//Here I'm creating a reference to our firebase
final firebase = Firestore.instance;

//This function will be used to copy the user names from userNames to namesList
void changeNames(List<String> userNames, List<String> namesList) {
  //First clear namesList, in case it already has data
  namesList.clear();
  //Then simply set namesList to be equal to userNames.
  namesList = userNames;
}

//Below is a function that gets the users current location, or last known location.
//The function will return a Position variable
Future<Position> currentLocation() async {
//First, I want to check if location services are available
//Lines below are to check if location services are enabled
  GeolocationStatus geolocationStatus =
      await Geolocator().checkGeolocationPermissionStatus();
//If we get access to the location services, we should get the current location, and return it
  if (geolocationStatus == GeolocationStatus.granted) {
    print("Using location services to find current location");
//Get the current location and return it
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }
//Else, if we get any other value, we will return the last known position
  else {
    print("Using last known location");
    Position position = await Geolocator()
        .getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    return position;
  }
}

//Function that will connect to yelp API
Future<void> _findingPlaces() async {
  print("Searching for your place");
  names.clear();
  resultCords.clear();
  locations.clear();
  urls.clear();
  images.clear();
  double finalRadMiles = finalRad * 1609.344;
  var businesses = "";
  businesses = await BackendMethods.getLocations(
      finalLon, finalLat, finalCatagory, finalRadMiles.toInt());
  var lat;
  var lon;
  var name;
  var address;
  var url;
  var image;
  for (var place in jsonDecode(businesses)) {
    lat = place['coordinates']['latitude'];
    lon = place['coordinates']['longitude'];
    var myLatlng = new LatLng(lat, lon);
    resultCords.add(myLatlng);

    name = place['name'];
    names.add(name);

    address = place['location'];
    locations.add(address);

    url = place['url'];
    urls.add(url);

    image = place['image_url'];
    images.add(image);
  }
  print(names);
  print("Locations: $resultCords");
  print("testing if I got a response:");
}

/*class GoogleMaps extends StatefulWidget {
  final String userDocID = FirebaseFunctions.currentUID;
  final String roomDocID = FirebaseFunctions.currentUserData["roomCode"];

//FirebaseFunctions.currentUserData[“roomCode”]
// FirebaseFunctions.currentUID
  @override
  _GoogleMapsState createState() => _GoogleMapsState();
}*/

class _GoogleMaps {
  final String userDocID = FirebaseFunctions.currentUID;
  final String roomDocID = FirebaseFunctions.currentUserData["roomCode"];
  GoogleMapController mapController;

//Creating a variable currPosition that will be used to store the users current position
  Position currPosition;
  static List<String> nameList = [];
  static StreamSubscription<QuerySnapshot> memberListener;

//Initializing center of map
  static LatLng _center;

//Using another LatLng variable to track the current center of the map, to place markers
  static LatLng _lastMapPosition = _center;

//String that will be used to store the address
  String searchAddr;

//Creating a variable markers that will be used to implement a marker in google maps
  Set<Marker> _markers = {};

//Going to create a string which will store the midpoint address
  String midAddress;

//Marker _markers;
//Function initState initialises the state of variables
//It returns a reference to the listener, so that we may turn off the listener at a later time
  StreamSubscription<QuerySnapshot> initState() {
     initFunctionCaller();
     return memberListener;
  }

  void initFunctionCaller() async {
    await _getUserLocation();
    _lastMapPosition = _center;
    await _onAddMarkerButtonPressed();
    await _initMarkers();
  }

//Function used to get users original position
  Future<void> _getUserLocation() async {
    currPosition = await currentLocation();
    _center = LatLng(currPosition.latitude, currPosition.longitude);
    await FirebaseFunctions.pushUserLocation(
        currPosition.latitude, currPosition.longitude);
  }

//Getting the user address from the location coordinates
  Future<void> _getUserAddress() async {
    try {
      List<Placemark> p = await Geolocator()
          .placemarkFromCoordinates(_center.latitude, _center.longitude);

      Placemark place = p[0];

      searchAddr =
          "${place.name}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
    } catch (e) {
      print(e);
    }
  }

  //This function will be used to initialise my markers, by accessing the user data from firebase
  Future<void> _initMarkers() async {
    //print("initMarkers called");
    memberListener = firebase
        .collection("rooms")
        .document(roomDocID)
        .collection("users")
        .snapshots()
        .listen((snapshot) async {
      clearOtherUserUserMarkers();
      await callAddOtherUserMarkers(snapshot);
      await findMidpoint(_markers);
    });
    //print("Markers = $_markers");
  }

  //This function clears all other markers other than the current users and the midpoint
  void clearOtherUserUserMarkers() {
    //Adding a line that will clear the markers that is not the current user, to update in case a user leaves
    _markers.removeWhere((element) =>
        element.markerId.value != "User" &&
        element.markerId.value != "Midpoint");
  }

  //This function will be used to clear the markers, and call addOtherUserMarkers. Is there to enforce more modularity
  Future<void> callAddOtherUserMarkers(QuerySnapshot snapshot) async {
    List<String> userNames = [];
    userNames.clear();
    for (var user in snapshot.documents) {
      //print("Here. Number of markers = ${_markers.length}");
      String newUserName = user.data["userName"];
      userNames.add(newUserName);
      //If the user is not equal to the current user, then we need to add that users location to markers
      if (user.documentID != userDocID) {
        print("Found other users");
        await addOtherUserMarkers(user);
      }
      changeNames(userNames, nameList);
    }
  }

  //In this function, I iterate through every user in the document, and get there location and add it to markers
  //All other users will have their BitMapDescriptor as Magenta in color, so that we can differentiate from other users
  Future<void> addOtherUserMarkers(DocumentSnapshot userLocations) async {
    print("Users doc ID = " + userLocations.documentID);
    GeoPoint newUserLoc = userLocations.data["location"];
    //If for some reason the user doesn't have a location yet, simply return
    if (newUserLoc == null) {
      return;
    }
    String newUserName = userLocations.data["userName"];
    //if the user is already in our markers array, I will just update their position
    _markers.removeWhere(
        (marker) => marker.markerId.value == userLocations.documentID);
    _markers.add(Marker(
      markerId: MarkerId(userLocations.documentID),
      position: LatLng(newUserLoc.latitude, newUserLoc.longitude),
      infoWindow: InfoWindow(title: newUserName, snippet: ""),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
    ));
    //print("Finished adding users location");
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
    _lastMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) async {
    print("Creating Map");
    mapController = controller;
    print("Done creating Map!");
    _lastMapPosition = _center;
  }

//Function to get the address for the midpoint from the
  Future<void> placefromLatLng(LatLng mid) async {
//Here, I will get the placemark from the coordinates
    List<Placemark> p = await Geolocator()
        .placemarkFromCoordinates(mid.latitude, mid.longitude);

    Placemark place = p[0];
    midAddress =
        "${place.name}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
    print("MidAddress updated to $midAddress");
  }

  //This function will be used to add the yelp markers
  void addYelpMarkers() {
    print("Entered Yelp markers. resultCords = ${resultCords.length}");
    //First, remove all the current yelp markers
    _markers.removeWhere((element) => (element.infoWindow.snippet != '' &&
        element.infoWindow.snippet != "Midpoint"));
    print("Removed yelp markers. resultCords = ${resultCords.length}");
    //For every location we found, we need to add a marker
    for (int i = 0; i < resultCords.length; i++) {
      _markers.add(Marker(
        markerId: MarkerId(resultCords[i].toString()),
        position: LatLng(resultCords[i].latitude, resultCords[i].longitude),
        infoWindow: InfoWindow(title: names[i], snippet: locations[i]),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
            .hueGreen), //Setting midpoint marker to blue so it's identifiable
      ));
    }
    print(_markers.length);
    print(_markers);
  }

  Future<void> findMidpoint(Set<Marker> userPositions) async {
    print("Entered findMidpoint");
    double currentMidLat = 0;
    double currentMidLon = 0;
    //Start off by removing the midpoint marker
    _markers.removeWhere((marker) => marker.markerId.value == "Midpoint");
//   var newLoc = locations[0];
    for (var userPosition in userPositions) {
//Want to skip the midpoint and remove it in case it is still there
      if (userPosition.markerId.value == "Midpoint") {
        _markers.removeWhere((marker) => marker.markerId.value == "Midpoint");
        continue;
      }
      currentMidLat = (userPosition.position.latitude + currentMidLat);
      currentMidLon = (userPosition.position.longitude + currentMidLon);
    }
    //print("Number of markers = ${userPositions.length})");
    currentMidLat = currentMidLat / (userPositions.length);
    currentMidLon = currentMidLon / (userPositions.length);

    finalLat = currentMidLat;
    finalLon = currentMidLon;

    print("Lat = $currentMidLat, and Long = $currentMidLon");
    await placefromLatLng(LatLng(currentMidLat, currentMidLon));
//      currentMidLat = currentMidLat / (locations.length);
//      currentMidLon = currentMidLon / (locations.length);
//      placefromLatLng(LatLng(currentMidLat, currentMidLon));
    _markers.add(Marker(
      markerId: MarkerId('Midpoint'),
      position: LatLng(currentMidLat, currentMidLon),
      infoWindow: InfoWindow(title: midAddress, snippet: 'Midpoint'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
          .hueBlue), //Setting midpoint marker to blue so it's identifiable
    ));
    //Now I find places around the midpoint, and display all the Yelp markers
    await _findingPlaces();
    addYelpMarkers();
  }

  //Need to test updateUserLocation, as the userDocID currently is an invalid ID, so it doesn't work
  //This function will be used to update the users location on firebase
  void updateUserLocation() async {
    await firebase
        .collection("rooms")
        .document(roomDocID)
        .collection("users")
        .document(userDocID)
        .updateData(
            {"location": GeoPoint(_center.latitude, _center.longitude)});
    print("Updated users location");
  }

  //This function will change the marker of the current user, so that a user can only edit their own marker
  Future<void> _onAddMarkerButtonPressed() async {
    //Here I find if there is already a user marker. If there is, toRemove is set to that marker. Otherwise toRemove is set to NULL
//Getting the correct address in searchAddr. Using await to ensure we get the right address.
    print("Entered _onAddMarkerButtonPressed. Center = $_center");
    await _getUserAddress();
    //First I remove the toRemove marker from _markers
    _markers.removeWhere((marker) => marker.markerId.value == "User");
    //Then I add the Users new location
    _markers.add(Marker(
      markerId: MarkerId("User"),
      position: _lastMapPosition,
      infoWindow: InfoWindow(title: searchAddr, snippet: ''),
//infoWindow: InfoWindow(),
      icon: BitmapDescriptor.defaultMarker,
    ));
    //print("Markers length before midpoint = ${_markers.length}");
    print(
        "Users Marker location before firebase update = ${_markers.where((element) => element.markerId.value == "User")}");
    updateUserLocation();
    print(
        "Users Marker location after firebase update = ${_markers.where((element) => element.markerId.value == "User")}");
    //findMidpoint(_markers);
  }

  void _searchandNavigate() async {
//Get the placemark from the search address, and then store the center and userAddress
    await Geolocator().placemarkFromAddress(searchAddr).then((value) async {
      //Set our _center location to the new position
      _center = LatLng(value[0].position.latitude, value[0].position.longitude);
//Set our _lastMapPosition also to the new position
      _lastMapPosition = _center;
      //Now I replace the users current position marker with the new marker
      await _onAddMarkerButtonPressed();
//With the placemark that will be stored in 'value', we move our camera to that position.
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target:
              LatLng(value[0].position.latitude, value[0].position.longitude),
          zoom: 15.0)));
    });
  }

  /*
  Google Maps Widget below

   */

  //Here, we add the widget that will be built. This widget will be used to display the google maps, as well as the locations
  Widget googleMapsDisplay(){
    if (_center == null){
      return Container(
        child: Center(
          child: Text(
            'loading map..',
            style: TextStyle(
                fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
          ),
        ),
      );
    }
    else{
      return Container(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 11.0,
              ),
              markers: _markers,
//Adding the marker property to Google Maps Widget
              onCameraMove:
              _onCameraMove, //Moving the center each time we move on the map, by calling _onCameraMove
            ),
            Positioned(
              top: 30,
              right: 15,
              left: 15,
              child: Container(
                height: 50.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.0),
                  color: Colors.white,
                ),
                child: TextField(
                  decoration: InputDecoration(
                      hintText: "Enter address...",
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.only(left: 15.0, top: 15.0),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: _searchandNavigate,
                        iconSize: 30.0,
                      )),
                  onChanged: (val) {
                    searchAddr = val;
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
//Adding another floating button to mark locations
                    FloatingActionButton(
                      onPressed: _onAddMarkerButtonPressed,
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: Colors.redAccent,
                      child: const Icon(
                        Icons.add_location,
                        size: 36.0,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
} //End of _GoogleMaps class

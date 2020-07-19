import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//import 'package:geoflutterfire/geoflutterfire.dart';
import 'firebaseFunctions.dart';
import 'dart:async';

//import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'src/locations.dart' as locations;

import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebaseFunctions.dart';
import 'page1.dart';
import 'page2.dart';
//import 'page4.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../backendFunctions.dart';
import 'dart:convert';
import 'package:link/link.dart';

//lib/backendFunctions.dart

double finalLon;
double finalLat;

String finalCatagory;
// double finalRad;

List resultCords = [];
List names = [];
List locations = [];
List urls = [];
List images = [];

//Map rendering stuff
//Check the below link for some explanation of how a lot of the methods work
//https://medium.com/@rajesh.muthyala/flutter-with-google-maps-and-google-place-85ccee3f0371
//Going to create a function that gets the users current location, or last known location.
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

//A string that will store the category searched for on the Yelp search
String category;

//Below are variables we will use for the sliders
double midSliderVal = 5;
double finalRad = midSliderVal;

double userSliderVal = 25;

//Here I'm creating a reference to our firebase
final firebase = Firestore.instance;

class MapRender extends StatefulWidget {
  final String roomCode;
  final String name;
  final String userDocID = FirebaseFunctions.currentUID;
  final String roomDocID = FirebaseFunctions.currentUserData["roomCode"];

//FirebaseFunctions.currentUserData[“roomCode”]
// FirebaseFunctions.currentUID
  MapRender({Key key, @required this.roomCode, @required this.name})
      : super(key: key);

  @override
  _MapRenderState createState() => _MapRenderState();
}

class _MapRenderState extends State<MapRender> {
  GoogleMapController mapController;

//Get the current position, and store it in the variable currPosition
//Need to learn how to get return value from future class
  Position currPosition;
  static List<String> nameList = [];

//const int longitude = currPosition.longitude;

  //MapType _currentMapType = MapType.normal;

//Initializing center of map
  static LatLng _center; //= LatLng(45.521563, -122.677433);
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
  @override
  void initState() {
    super.initState();
    initFunctionCaller();
    getRoomCodePreference().then(_updateRoomCode); // initialize stored roomCode
    getNamePreference().then(_updateName);

    //I also want to update the users location in the database
  }

  String _roomCode = "";

  void _updateRoomCode(String roomCode) {
    setState(() {
      this._roomCode = roomCode;
    });
  }

  String _name = "";

  void _updateName(String name) {
    setState(() {
      this._name = name;
    });
  }

  void initFunctionCaller() async {
    await _getUserLocation();
    _onAddMarkerButtonPressed();
    _lastMapPosition = _center;
    await _initMarkers();
//_getUserAddress();
    //print("Done initialising variabels for map");
    //print(_center);
  }

//Function used to get users original position
  Future<void> _getUserLocation() async {
    currPosition = await currentLocation();
    print("Current Position = " + currPosition.toString());
    setState(() {
      _center = LatLng(currPosition.latitude, currPosition.longitude);
    });
    print("Center = " + _center.toString());
    bool pushedLocation = await FirebaseFunctions.pushUserLocation(
        currPosition.latitude, currPosition.longitude);
  }

//Getting the user address from the location coordinates
  Future<void> _getUserAddress() async {
    try {
      List<Placemark> p = await Geolocator()
          .placemarkFromCoordinates(_center.latitude, _center.longitude);

      Placemark place = p[0];

      setState(() {
        searchAddr =
            "${place.name}, ${place.thoroughfare}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  //This function will be used to initialise my markers, by accessing the user data from firebase
  Future<void> _initMarkers() async {
    //print("initMarkers called");
    firebase
        .collection("rooms")
        .document(widget.roomDocID)
        .collection("users")
        .snapshots()
        .listen((snapshot) async {
      //Adding a line that will clear the markers that is not the current user, to update in case a user leaves
      setState(() {
        _markers.removeWhere((element) =>
            element.markerId.value != "User" &&
            element.markerId.value != "Midpoint");
      });

      List<String> userNames = [];
      userNames.clear();
      for (var user in snapshot.documents) {
        //print("Here. Number of markers = ${_markers.length}");
        //Id the user is not equal to the current user, then we need to add that users location to markers

        String newUserName = user.data["userName"];
        userNames.add(newUserName);
        if (user.documentID != widget.userDocID) {
          await addOtherUserMarkers(user);
        }
      }
      nameList.clear();
      nameList = userNames;
      //print("Got to this point before markers were initialised");
      //Here, I call the midpoint function, so that if another user changes their location, the midpoint changes
      await findMidpoint(_markers);
    });
    //print("Markers = $_markers");
  }

  //In this function, I iterate through every user in the document, and get there location and add it to markers
  //All other users will have their BitMapDescriptor as Magenta in color, so that we can differentiate from other users
  Future<void> addOtherUserMarkers(DocumentSnapshot userLocations) async {
    //print("Users doc ID = " + userLocations.documentID);
    GeoPoint newUserLoc = userLocations.data["location"];
    //If for some reason the user doesn't have a location yet, simply return
    if (newUserLoc == null) {
      return;
    }
//    var newUserinfo = await firebase
//        .collection("users")
//        .document(userLocations.documentID)
//        .get();
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
    _onAddMarkerButtonPressed();
//We wait to receive the users current position
//The initial position of the map should now be set to the users initial position
//_center = LatLng(currPosition.latitude, currPosition.longitude);
  }

//Function to get the address for the midpoint from the
  Future<void> placefromLatLng(LatLng mid) async {
//Here, I will get the placemark from the coordinates
    List<Placemark> p = await Geolocator()
        .placemarkFromCoordinates(mid.latitude, mid.longitude);

    Placemark place = p[0];
    setState(() {
      midAddress =
          "${place.name}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
    });
    print("MidAddress updated to $midAddress");
  }

  //This function will be used to add the yelp markers
  void addYelpMarkers() {
    print("Entered Yelp markers. resultCords = ${resultCords.length}");
    //First, remove all the current yelp markers
    //_markers.removeWhere((element) => element.markerId.value == 'Yelp');
    //For every location we found, we need to add a marker
    setState(() {
      for (int i = 0; i < resultCords.length; i++) {
        _markers.add(Marker(
          markerId: MarkerId(names[i]),
          position: LatLng(resultCords[i].latitude, resultCords[i].longitude),
          infoWindow: InfoWindow(title: names[i], snippet: locations[i]),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
              .hueGreen), //Setting midpoint marker to blue so it's identifiable
        ));
      }
    });
    print(_markers.length);
    print(_markers);
  }

  Future<void> findMidpoint(Set<Marker> userPositions) async {
    double currentMidLat = 0;
    double currentMidLon = 0;
    //Start off by removing the midpoint marker
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "Midpoint");
    });
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
    setState(() {
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
    });
    //print("Midpoint address = " + midAddress);
    //Now I find places around the midpoint, and display all the Yelp markers
    await _findingPlaces();
    addYelpMarkers();
  }

  //Need to test updateUserLocation, as the userDocID currently is an invalid ID, so it doesn't work
  //This function will be used to update the users location on firebase
  void updateUserLocation() async {
    await firebase
        .collection("rooms")
        .document(widget.roomDocID)
        .collection("users")
        .document(widget.userDocID)
        .updateData(
            {"location": GeoPoint(_center.latitude, _center.longitude)});
  }

  //This function will change the marker of the current user, so that a user can only edit their own marker
  Future<void> _onAddMarkerButtonPressed() async {
    //Here I find if there is already a user marker. If there is, toRemove is set to that marker. Otherwise toRemove is set to NULL
//Getting the correct address in searchAddr. Using await to ensure we get the right address.
    print("Entered _onAddMarkerButtonPressed. Center = $_center");
    await _getUserAddress();
    setState(() {
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
    });
    //print("Markers length before midpoint = ${_markers.length}");
    updateUserLocation();
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

  /* String _roomCode = "";

  void _updateRoomCode(String roomCode) {
    setState(() {
      this._roomCode = roomCode;
    });
  }

  String _name = "";
  void _updateName(String name) {
    setState(() {
      this._name = name;
    });
  }
*/
  var _arrLength;

  void _updateYelpVenues() {
    setState(() {
      _arrLength = names.length;
    });
  }

  /*Widget _viewYelp() {
    _updateYelpVenues();
    if (_arrLength == null || _arrLength == 0) {
      return Text("No Places Found");
    }

    //Using ListView.seperated instead of .builder to create a seperated list
    return ListView.separated(
      itemCount: _arrLength,
      itemBuilder: (BuildContext context, int index) {
        //return new Text(names[index]);
        return new Container(
          //padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
          child: Link(
            url: urls[index],
            child: Row(children: [
              Container(
                alignment: Alignment.centerLeft,
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: NetworkImage(
                            "'https:///flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'"))),
              ),
              Text(
                "${names[index]} \n (Click to open Yelp page)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                //textAlign: TextAlign.right,
              ),
            ]),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => Divider(),
      //);
      // },
    );
  }*/

  Widget _viewYelp() {
    _updateYelpVenues();
    if (_arrLength == null || _arrLength == 0) {
      return Text("No Places Found");
    }

    return Card(
      elevation: 4,
      child: ListView.builder(
        itemCount: _arrLength,
        itemBuilder: (BuildContext context, int index) {
          //return new Text(names[index]);
          return new Container(
            //padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
            child: Link(
              url: urls[index],
              child: Row(
                children: <Widget>[
                  Container(
                    height: 110,
                    width: 90,
                    child: Image.network(
                      images[index] == null
                          ? 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910'
                          : '${images[index]}',
                      // 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910',
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 5.0,
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        MergeSemantics(
                          child: Row(
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  "${names[index]} ",
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Theme.of(context).primaryColor),
                                  textAlign: TextAlign.left,
                                ),
                                //textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Click to open Yelp page',
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey),
                        ),
                        SizedBox(height: 5),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
        topLeft: Radius.circular(75.0), topRight: Radius.circular(75.0));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Maps'),
          backgroundColor: Colors.lightBlue,
        ),
        body: SlidingUpPanel(
//maxHeight: 600,
          backdropEnabled: true,
          borderRadius: radius,
          panel: Center(
// yelp info will display here
              child: Container(
                  padding: EdgeInsets.fromLTRB(0, 80, 0, 0),
                  child:
                      /*ValueListenableBuilder(
                  valueListenable: _arrLength,
                  builder: (BuildContext context, int value, _) {
                    return */
                      _viewYelp())
              /* ListView.builder(
                        itemCount: _arrLength,
                        itemBuilder: (BuildContext context, int index) {
                          return new Text(names[index]);
                        } //);
                        // },
                        )),*/
              ),
          collapsed: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: radius,
            ),
            child: Center(
              child: Text(
                'Swipe up for menu',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          minHeight: 100,
          body: _center == null
              ? Container(
                  child: Center(
                    child: Text(
                      'loading map..',
                      style: TextStyle(
                          fontFamily: 'Avenir-Medium', color: Colors.grey[400]),
                    ),
                  ),
                )
              : Container(
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
                              setState(() {
                                searchAddr = val;
                              });
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 16.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            children: <Widget>[
//Adding another floating button to mark locations
                              FloatingActionButton(
                                onPressed: _onAddMarkerButtonPressed,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.padded,
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
                ),
        ),
        drawer: Theme(
          data: Theme.of(context).copyWith(
            canvasColor:
                Colors.blue, //This will change the drawer background to blue.
            //other styles
          ),
          child: Container(
            width: 350,
            child: Drawer(
// Add a ListView to the drawer. This ensures the user can scroll
// through the options in the drawer if there isn't enough vertical
// space to fit everything.
              child: ListView(
// Important: Remove any padding from the ListView.
//padding: EdgeInsets.only(),
                children: <Widget>[
                  Container(
                    height: 80.0,
                    margin: EdgeInsets.all(0),
                    child: DrawerHeader(
                      child: Container(
                        child: Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: ListTile(
                      title: Text(
                        'People in this room:',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                    child: ListTile(
                      title: Text(
                        "${nameList.join("\n")}" ?? "Name is Null",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  Container(
                    child: ListTile(
                      title: Text(
                        'Searching for:',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  //Search bar

                  Container(
                    margin: EdgeInsets.all(15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.white,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 1.5),
                          ),
                          hintText: "Enter category...",
                          contentPadding:
                              EdgeInsets.only(left: 15.0, top: 15.0),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: _findingPlaces,
                            iconSize: 20.0,
                          )),
                      onChanged: (val) {
                        setState(() {
                          category = val;
                          finalCatagory = category;
                        });
                      },
                    ),
                  ),
                  //Below are the sliders
                  Container(
                    child: ListTile(
                      title: Text(
                        'Range from your location: ${userSliderVal} mi',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.red[500],
                      inactiveTrackColor: Colors.red[100],
                      trackShape: RectangularSliderTrackShape(),
                      trackHeight: 4.0,
                      thumbColor: Colors.white,
                      thumbShape:
                          RoundSliderThumbShape(enabledThumbRadius: 10.0),
                      overlayColor: Colors.red.withAlpha(32),
                      overlayShape:
                          RoundSliderOverlayShape(overlayRadius: 28.0),
                    ),
                    child: Container(
                      margin: EdgeInsets.all(5),
                      /*
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20))), */
                      child: Slider(
                        value: userSliderVal,
                        onChanged: (double val) {
                          //We need to connect the yelp API here

                          setState(() {
                            userSliderVal = val;
                          });
                        },
                        min: 1,
                        max: 25,
                        divisions: 24,
                      ),
                    ),
                  ),
                  Container(
                    child: ListTile(
                      title: Text(
                        'Range from midpoint: ${midSliderVal} mi',
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.red[500],
                        inactiveTrackColor: Colors.red[100],
                        trackShape: RectangularSliderTrackShape(),
                        trackHeight: 4.0,
                        thumbColor: Colors.white,
                        thumbShape:
                            RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        overlayColor: Colors.red.withAlpha(32),
                        overlayShape:
                            RoundSliderOverlayShape(overlayRadius: 28.0),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(5),
                        /*decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                            ),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                                */
                        child: Slider(
                          value: midSliderVal,
                          onChanged: (double val) {
                            //We need to connect the yelp API here
                            setState(() {
                              midSliderVal = val;

                              //can I do this
                              finalRad = midSliderVal;

                              _findingPlaces();
                              addYelpMarkers();
                            });
                            _updateYelpVenues();
                          },
                          min: 1,
                          max: 25,
                          divisions: 24,
                        ),
                      )),
                  Container(
                    child: ListTile(
                      title: Text(
                        'Your Code:',
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: ListTile(
                      title: Text(
                        "${FirebaseFunctions.roomData["roomCode"]}" ??
                            "roomCode is Null",
                        style: TextStyle(
                          fontSize: 35,
                        ),
                      ),
                      onTap: null,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 15.0),
                    width: 50,
                    child: ButtonTheme(
                      minWidth: double.infinity,
                      height: 60.0,
                      padding: EdgeInsets.all(10.0),
                      buttonColor: Colors.white,
                      child: RaisedButton(
                        child: Text("Leave Room",
                            style: new TextStyle(
                                fontSize: 20.0, color: Colors.black)),
                        onPressed: () {
                          FirebaseFunctions.removeCurrentUserFromRoom(
                              FirebaseFunctions.roomData["roomCode"]);
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/page1', (route) => false);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
//);
  }
}

//Function that will connect to yelp API
void _findingPlaces() async {
  print("Searching for your place");
  //finalRad.toInt()
  names.clear();
  resultCords.clear();
  locations.clear();
  urls.clear();
  images.clear();

  double finalRadMiles = finalRad * 1609.344;

  var businesses = "";

  businesses = await BackendMethods.getLocations(
      finalLon, finalLat, finalCatagory, finalRadMiles.toInt());

  //var buss = "";
  //buss = await BackendMethods.getLocations( -118.30198471, 34.16972651);

  //print(buss);
  var lat;
  var lon;
  var name;
  var address;
  var url;
  var image;

  for (var place in jsonDecode(businesses)) {
    lat = place['coordinates']['latitude'];
    lon = place['coordinates']['longitude'];

    //  print(lat);
    //  print(lon);

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

    // print("image_url");
    // print(image);

    // print(names);
    // print(address);

    //names.add(name);

  }

  print(names);
  print("Locations: $resultCords");
  print("testing if I got a response:");
  //print(businesses==null);
}

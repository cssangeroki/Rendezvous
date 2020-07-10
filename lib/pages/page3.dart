import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'src/locations.dart' as locations;

import 'package:geolocator/geolocator.dart';

import 'page1.dart';
import 'page2.dart';
import 'page4.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//Map rendering stuff
//Check the below link for some explanation of how a lot of the methods work
//https://medium.com/@rajesh.muthyala/flutter-with-google-maps-and-google-place-85ccee3f0371
//Note: This does not work on android for some reason. I was not able to find out why, but the source of the problem had something to do with starting at the user's location.
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
double userSliderVal = 25;

//Here I'm creating a reference to our firebase
final firebase = Firestore.instance;

class MapRender extends StatefulWidget {
  final String roomCode;
  final String name;
  final String documentID;
  MapRender({Key key, @required this.roomCode, @required this.name, @required this.documentID})
      : super(key: key);

  @override
  _MapRenderState createState() => _MapRenderState();
}

class _MapRenderState extends State<MapRender> {
  GoogleMapController mapController;

//Get the current position, and store it in the variable currPosition
//Need to learn how to get return value from future class
  Position currPosition;

//const int longitude = currPosition.longitude;

  MapType _currentMapType = MapType.normal;

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

  void initFunctionCaller() async {
    await _getUserLocation();
    _lastMapPosition = _center;
//_getUserAddress();
    _onAddMarkerButtonPressed();
    print("Done initialising variabels for map");
    print(_center);
  }

//Function used to get users original position
  Future<void> _getUserLocation() async {
    currPosition = await currentLocation();
    print("Current Position = " + currPosition.toString());
    setState(() {
      _center = LatLng(currPosition.latitude, currPosition.longitude);
    });
    print("Center = " + _center.toString());
  }

//Getting the user address from the location coordinates
  Future<void> _getUserAddress() async {
    try {
      List<Placemark> p = await Geolocator()
          .placemarkFromCoordinates(_center.latitude, _center.longitude);

      Placemark place = p[0];

      setState(() {
        searchAddr =
            "${place.name}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
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
  Future<void> placefromLatLng(LatLng mid) async{
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

  void findMidpoint(Set<Marker> locations) async{
    double currentMidLat = 0;
    double currentMidLon = 0;

//   var newLoc = locations[0];
    Marker toRemove;
    for (var location in locations) {
//Want to skip the midpoint so that it doesn't affect the position of the new midpoint.
//If there is a Midpoint marker, I will store it in toRemove so I can remove it later
      if (location.markerId == MarkerId("Midpoint")) {
//print("Found Midpoint marker");
//print(location.toString());
        toRemove = _markers.firstWhere(
            (marker) => marker.markerId.value == "Midpoint",
            orElse: () => null);
        continue;
      }
      currentMidLat = (location.position.latitude + currentMidLat);
      currentMidLon = (location.position.longitude + currentMidLon);
    }
    setState(() {
      _markers.remove(toRemove);
    });
    currentMidLat = currentMidLat / (locations.length);
    currentMidLon = currentMidLon / (locations.length);
    await placefromLatLng(LatLng(currentMidLat, currentMidLon));
//Over here I remove the current midpoint marker, so I can add it again later
    setState(() {
//      _markers.remove(toRemove);
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
    print("Midpoint address = " + midAddress);
  }

  void _onAddMarkerButtonPressed() async {
//deleting the current marker and replacing it with the new one

//Comment this out to get multiple markers
//_markers = {};
//Getting the correct address in searchAddr. Using await to ensure we get the right address.
    await _getUserAddress();
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(_lastMapPosition.toString()),
        position: _lastMapPosition,
        infoWindow: InfoWindow(title: searchAddr, snippet: ''),
//infoWindow: InfoWindow(),
        icon: BitmapDescriptor.defaultMarker,
      ));
      findMidpoint(_markers);
    });
  }

  void _searchandNavigate() {
//Get the placemark from the search address, and then store the center and userAddress
    Geolocator().placemarkFromAddress(searchAddr).then((value) async {
//With the placemark that will be stored in 'value', we move our camera to that position.
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target:
              LatLng(value[0].position.latitude, value[0].position.longitude),
          zoom: 15.0)));
//Set our _center location to the new position
      _center = LatLng(value[0].position.latitude, value[0].position.longitude);
//Set our _lastMapPosition also to the new position
      _lastMapPosition = _center;
//Then get the actual full address of that location, and finally call _onAddMarkerButtonPressed so that a marker is added at that location
      _getUserAddress();
      await _onAddMarkerButtonPressed();
    });
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

  @override
  Widget build(BuildContext context) {
    BorderRadiusGeometry radius = BorderRadius.only(
        topLeft: Radius.circular(75.0), topRight: Radius.circular(75.0));
    return MaterialApp(
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
            child: Text("Yelp info will be found here"),
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
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: ListTile(
                      title: Text(
                        "$_name:" ?? "Name is Null",
                        style: TextStyle(
                          fontSize: 30,
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
                            });
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
                        "$_roomCode:" ?? "roomCode is Null",
                        style: TextStyle(
                          fontSize: 30,
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
                          Navigator.pop(context);
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
void _findingPlaces() {
  print("Searching for your place");
}

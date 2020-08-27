//This file will hold the MapRenderState class

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'pages/firebaseFunctions.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//import 'pages/mapRenderPage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import "globalVar.dart";
import "findYelpPlaces.dart";
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

//Import needed for calculating route time
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

//Here I'm creating a reference to our firebase
final firebase = Firestore.instance;
String _mapStyle;
String mapsAPI_KEY = "AIzaSyBV961Ztopz9vyZrJq0AYAMJUTHmluu3FM";
GlobalKey<GoogleMapsState> mapsKey = GlobalKey<GoogleMapsState>();
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

class GoogleMaps extends StatefulWidget {
  //const GoogleMaps ({Key key}) : super(key: key);
  //GlobalKey<_GoogleMapsState> myKey = GlobalKey();
  //final _GoogleMapsState mapsState = new _GoogleMapsState();
//  static of(BuildContext context, {bool root = false}) => root
//      ? context.findRootAncestorStateOfType<_GoogleMapsState>()
//      : context.findAncestorStateOfType<_GoogleMapsState>();

  @override
  GoogleMapsState createState() => GoogleMapsState(); //mapsState;

//  void addYelpMarkers(){
//    mapsState.addYelpMarkers();
//  }
}

class GoogleMapsState extends State<GoogleMaps> {
  //Creating a global key to access class state outside of the class

  final String userDocID = FirebaseFunctions.currentUID;
  final String roomDocID = FirebaseFunctions.currentUserData["roomCode"];
  GoogleMapController mapController;

//Creating a variable currPosition that will be used to store the users current position
  Position currPosition;
  LatLng currLocation;

  //static List<String> nameList = [];
  BitmapDescriptor myIcon;

  //static StreamSubscription<QuerySnapshot> memberListener;

//Initializing center of map
  static LatLng _center;

//Using another LatLng variable to track the current center of the map, to place markers
  static LatLng _lastMapPosition = _center;

//String that will be used to store the address
  String searchAddr;

//Creating a variable markers that will be used to implement a marker in google maps
  Set<Marker> _markers = {};

  //Creating a variable that will be used to store the Paths
  Set<Polyline> _polylines = {};

  //This will hold each polyline coordinate as a LatLng pair
  List<LatLng> polylineCoordinates = [];

  //This is what will actually be used to generate the polylines between each LatLng
  PolylinePoints polylinePoints = PolylinePoints();

//Going to create a string which will store the midpoint address
  String midAddress;

  //Creating a variable that will trigger the confirm location dialog box
  bool confirmDialogTrigger = false;

  //Boolean that will let us know if the user dragged their marker or not
  bool userMarkerDragged = false;

  String finalLocName;
  String finalLocAddress;
  LatLng finalLatLng;

//Marker _markers;
//Function initState initialises the state of variables
//It returns a reference to the listener, so that we may turn off the listener at a later time
  @override
  void initState() {
    super.initState();
    setBitmapIcon();
    setMapStyle();
    initFunctionCaller();
  }

  void setMapStyle() {
    rootBundle.loadString('assets/map_style.txt').then((string) {
      _mapStyle = string;
    });
  }

  void setBitmapIcon() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(size: Size(2, 2)), 'images/person.png')
        .then((onValue) {
      myIcon = onValue;
    });
  }

  void initFunctionCaller() async {
    addYelpMarkersWhenFindYPCalled();
    setFinalLocationWhenButtonPressedOnSlideBar();
    await _getUserLocation();
    _lastMapPosition = _center;
    await _onAddMarkerButtonPressed();
    await _initMarkers();
    await initialiseFinalRouteOnEnter();
  }

  //This functions will listen to when the function addYelpMarkers is called outside and will add the yelpMarkers to the widget
  void addYelpMarkersWhenFindYPCalled() {
    Global.findYPCalled.addListener(() {
      setState(() {
        print("entered YP listener");
        addYelpMarkers();
      });
    });
    //Global.findYPCalled.value = false;
  }

  //This function will be used to listen to if the final location was set on the slide up bar
  void setFinalLocationWhenButtonPressedOnSlideBar() {
    Global.finalLocationChanged.addListener(() async {
      //print(
      //  "Location changed. Final Address = ${FirebaseFunctions.roomData["Final Location Address"]}");
      await routeToFinalLoc();
      Global.finalLocationChanged.value = false;
    });
  }

  //This function will be used initialise the route to the final location when someone enters a room
  Future<void> initialiseFinalRouteOnEnter() async {
    if (FirebaseFunctions.roomData["Final Location"] != null) {
      await routeToFinalLoc();
      calculateTravelTime();
    }
  }

  //Helper function that just gets the LatLng of the Final Address, and then calls setPolyLines
  Future<void> routeToFinalLoc() async {
    //If no final location is set, no routing needs to be done
    if (FirebaseFunctions.roomData["Final Location"] == null) {
      return;
    }
    //Otherwise, we route the user to the final location
    await Geolocator()
        .placemarkFromAddress(
            "${FirebaseFunctions.roomData["Final Location"]}, ${FirebaseFunctions.roomData["Final Location Address"]}")
        .then((value) async {
      finalLatLng =
          LatLng(value[0].position.latitude, value[0].position.longitude);
      addFinalLocMarker();
      setPolyLines();
      calculateTravelTime();
    });
  }

  void addFinalLocMarker() {
    setState(() {
      _markers
          .removeWhere((element) => element.markerId.value == "Final Location");
      _markers.add(Marker(
          markerId: MarkerId("Final Location"),
          position: LatLng(finalLatLng.latitude, finalLatLng.longitude),
          infoWindow: InfoWindow(
              title: FirebaseFunctions.roomData["Final Location"],
              snippet: "Final Location"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          onTap: () {
            setState(() {
              confirmDialogTrigger = false;
            });
          }));
    });
  }

  //Function that will send an http request to google maps to calculate the travel time
  void calculateTravelTime() async {
    //We send an http request to get to the google maps api, to get the travel time
    var response = await http.post(
        "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=${currLocation.latitude},${currLocation
        .longitude}&destinations=${finalLatLng.latitude},${finalLatLng.longitude}&departure_time=now&key=$mapsAPI_KEY");
    //Now, we will decode the json response
    if (response.statusCode == 200){
        var decoded = convert.jsonDecode(response.body);
        print("Decode = $decoded");
        print("decoded datatype = ${decoded.runtimeType}");
        //var rows = decoded['rows'];
        int timeTaken = decoded['rows'][0]["elements"][0]["duration"]["value"];
        print("Time taken is $timeTaken");
        Global.hours = (timeTaken / 3600).floor();
        Global.minutes = ((timeTaken % 3600)/ 60).ceil();
        //Notify other parts that the time changed
        Global.timeChanged.notifyListeners();

    }

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
      print(_center);
      Placemark place = p[0];

      setState(() {
        searchAddr =
            "${place.name}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  //This function will be used to initialise my markers, by accessing the user data from firebase
  Future<void> _initMarkers() async {
    //print("initMarkers called");
    Global.memberListener = firebase
        .collection("rooms")
        .document(roomDocID)
        .collection("users")
        .snapshots()
        .listen((snapshot) async {
      clearOtherUserMarkers();
      await callAddOtherUserMarkers(snapshot);
      await findMidpoint(_markers);
    });
    //print("Markers = $_markers");
  }

  //This function clears all other markers other than the current users and the midpoint
  void clearOtherUserMarkers() {
    //Adding a line that will clear the markers that is not the current user, to update in case a user leaves
    setState(() {
      _markers.removeWhere((element) =>
          element.markerId.value != "User" &&
          element.markerId.value != "Midpoint" &&
          element.markerId.value != "Final Location");
    });
  }

  //This function will be used to clear the markers, and call addOtherUserMarkers. Is there to enforce more modularity
  Future<void> callAddOtherUserMarkers(QuerySnapshot snapshot) async {
    List<String> userNames = [];
    //userNames.clear();
    for (var user in snapshot.documents) {
      //print("Here. Number of markers = ${_markers.length}");
      String newUserName = user.data["userName"];
      userNames.add(newUserName);
      //If the user is not equal to the current user, then we need to add that users location to markers
      if (user.documentID != userDocID) {
        print("Found other users");
        await addOtherUserMarkers(user);
      }
    }
    changeNames(userNames, Global.nameList);
    print("nameList is ${Global.nameList}");
    Global.mapRPnameListListener.notifyListeners();
    Global.mapRPnameListListener.value = true;
  }

  //This function will be used to copy the user names from userNames to namesList
  void changeNames(List<String> userNames, List<String> namesList) {
    //First clear namesList, in case it already has data
    namesList.clear();
    //Then simply add all names in userNames to namesList
    namesList.addAll(userNames);
  }

  //In this function, I iterate through every user in the document, and get there location and add it to markers
  //All other users will have their BitMapDescriptor as Magenta in color, so that we can differentiate from other users
  Future<void> addOtherUserMarkers(DocumentSnapshot userLocations) async {
    GeoPoint newUserLoc = userLocations.data["location"];
    //If for some reason the user doesn't have a location yet, simply return
    if (newUserLoc == null) {
      return;
    }
    String newUserName = userLocations.data["userName"];
    setState(() {
      //if the user is already in our markers array, I will just update their position
      _markers.removeWhere(
          (marker) => marker.markerId.value == userLocations.documentID);
      _markers.add(Marker(
          markerId: MarkerId(userLocations.documentID),
          position: LatLng(newUserLoc.latitude, newUserLoc.longitude),
          infoWindow: InfoWindow(title: newUserName, snippet: ""),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueMagenta),
          onTap: () {
            setState(() {
              confirmDialogTrigger = false;
            });
          }));
    });
    //print("Finished adding users location");
  }

  void _onCameraMove(CameraPosition position) {
    if (userMarkerDragged == true) {
      return;
    }
    //print("Camera Moved");
    _center = position.target;
    _lastMapPosition = position.target;
  }

  void _onMapCreated(GoogleMapController controller) async {
    print("Creating Map");
    mapController = controller;
    mapController.setMapStyle(_mapStyle);

    print("Done creating Map!");
    _lastMapPosition = _center;
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
    //print("MidAddress updated to $midAddress");
  }

  //This function will be used to add the yelp markers
  void addYelpMarkers() {
    //print("Entered Yelp markers. resultCords = ${Global.resultCords.length}");
    //First, remove all the current yelp markers
    _markers.removeWhere((element) =>
        (element.infoWindow.snippet != 'Your Location' &&
            element.infoWindow.snippet != "Midpoint" &&
            element.infoWindow.snippet != "Final Location" &&
            element.infoWindow.snippet != ''));
    //For every location we found, we need to add a marker
    setState(() {
      for (int i = 0; i < Global.resultCords.length; i++) {
        _markers.add(Marker(
          markerId: MarkerId(Global.resultCords[i].toString()),
          position: LatLng(
              Global.resultCords[i].latitude, Global.resultCords[i].longitude),
          infoWindow:
              InfoWindow(title: Global.names[i], snippet: Global.locations[i]),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          //Setting midpoint marker to blue so it's identifiable
          onTap: () {
            setState(() {
              confirmDialogTrigger = true;
              finalLocName = Global.names[i];
              finalLocAddress = Global.locations[i];
              finalLatLng = LatLng(Global.resultCords[i].latitude,
                  Global.resultCords[i].longitude);
              //confirmFinalPosition();
            });
          }, //Want to add a stateless widget here,
        ));
      }
    });
    //print(_markers.length);
    //print(_markers);
  }

  Future<void> findMidpoint(Set<Marker> userPositions) async {
    //print("Entered findMidpoint");
    double currentMidLat = 0;
    double currentMidLon = 0;
    //Start off by removing the midpoint marker
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "Midpoint");
    });
//   var newLoc = locations[0];
    int length = 0;
    for (var userPosition in userPositions) {
//Want to skip the midpoint and remove it in case it is still there
      if (userPosition.markerId.value == "Final Location") {
        // _markers.removeWhere((marker) => marker.markerId.value == "Midpoint");
        continue;
      }
      currentMidLat = (userPosition.position.latitude + currentMidLat);
      currentMidLon = (userPosition.position.longitude + currentMidLon);
      length += 1;
    }
    //print("Number of markers = ${userPositions.length})");
    currentMidLat = currentMidLat / (length);
    currentMidLon = currentMidLon / (length);

    Global.finalLat = currentMidLat;
    Global.finalLon = currentMidLon;

    //print("Lat = $currentMidLat, and Long = $currentMidLon");
    await placefromLatLng(LatLng(currentMidLat, currentMidLon));
//      currentMidLat = currentMidLat / (locations.length);
//      currentMidLon = currentMidLon / (locations.length);
//      placefromLatLng(LatLng(currentMidLat, currentMidLon));
    setState(() {
      _markers.add(Marker(
          markerId: MarkerId('Midpoint'),
          position: LatLng(currentMidLat, currentMidLon),
          infoWindow: InfoWindow(title: midAddress, snippet: 'Midpoint'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            setState(() {
              confirmDialogTrigger = true;
              finalLocName = "Midpoint";
              finalLocAddress = midAddress;
              finalLatLng = LatLng(currentMidLat, currentMidLon);
              //confirmFinalPosition();
            });
          } //Setting midpoint marker to blue so it's identifiable
          ));
    });
    //Now I find places around the midpoint, and display all the Yelp markers
    Global.resultCords.clear();
    await YelpPlaces.findingPlaces();
    Global.mapRPfindYPListener.notifyListeners();
    Global.mapRPfindYPListener.value = true;
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
    //print("Updated users location");
  }

  //This function will change the marker of the current user, so that a user can only edit their own marker
  Future<void> _onAddMarkerButtonPressed() async {
//Getting the correct address in searchAddr. Using await to ensure we get the right address.
    await _getUserAddress();
    currLocation = _lastMapPosition;
    //First I remove the toRemove marker from _markers
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == "User");
      //Then I add the Users new location
      _markers.add(Marker(
        markerId: MarkerId("User"),
        position: _lastMapPosition,
        infoWindow: InfoWindow(title: searchAddr, snippet: 'Your Location'),
        icon: myIcon,
        onTap: () {
          setState(() {
            confirmDialogTrigger = false;
          });
        },
        draggable: true,
        onDragEnd: (newLatLng) async {
          userMarkerDragged = true;
          _center = newLatLng;
          _lastMapPosition = newLatLng;
          _onCameraMove(CameraPosition(target: newLatLng));
          mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(newLatLng.latitude, newLatLng.longitude),
                  zoom: 11.0)));
          await _onAddMarkerButtonPressed();
        },
      ));
    });
    updateUserLocation();
    //Reroute to the final location from the users new position
    await routeToFinalLoc();
    userMarkerDragged = false;
  }

  void searchAndNavigate() async {
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

  void setPolyLines() async {
    polylineCoordinates.clear();
    PointLatLng userLocation =
        PointLatLng(currLocation.latitude, currLocation.longitude);
    PointLatLng destination =
        PointLatLng(finalLatLng.latitude, finalLatLng.longitude);
    //Get the route using the google api key
    PolylineResult route = await polylinePoints?.getRouteBetweenCoordinates(
        mapsAPI_KEY, userLocation, destination);
    if (route != null) {
      route.points.forEach((element) {
        polylineCoordinates.add(LatLng(element.latitude, element.longitude));
      });
    }
    //This line actually changes the route on the map
    setState(() {
      _polylines.clear();
      _polylines.add(Polyline(
          polylineId: PolylineId("Final Route"),
          color: Colors.deepPurpleAccent,
          points: polylineCoordinates));
    });
  }

  //Widget for when a marker is tapped
  Widget confirmFinalPosition() {
    if ((FirebaseFunctions.currentUserData["userName"] ==
            FirebaseFunctions.roomData["host"]) &&
        (confirmDialogTrigger == true)) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                FirebaseFunctions.setFinalPosition(
                    finalLocName, finalLocAddress);
              });
              //setPolyLines();
            },
            materialTapTargetSize: MaterialTapTargetSize.padded,
            backgroundColor: Colors.greenAccent,
            child: const Icon(
              Icons.check_circle,
              size: 36.0,
            ),
          ));
    }
    return SizedBox.shrink(); //FloatingActionButton();//Container();
  }

  /*
  Google Maps Widget below

   */

  //Here, we add the widget that will be built. This widget will be used to display the google maps, as well as the locations

  @override
  Widget build(BuildContext context) {
    return _center == null
        ? Container(
            child: Center(
              child: Text(
                'loading map..',
                style: TextStyle(
                  fontSize: 50,
                  fontFamily: 'Avenir-Medium',
                  color: Color(Global.blackColor),
                ),
              ),
            ),
          )
        : Container(
            child: Stack(
              children: <Widget>[
                Container(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,

                    initialCameraPosition: CameraPosition(
                      target: _center,
                      zoom: 14.0,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: _markers,
//Adding the marker property to Google Maps Widget
                    onCameraMove: _onCameraMove,
                    polylines:
                        _polylines, //Moving the center each time we move on the map, by calling _onCameraMove
                  ),
                ),
                Container(
                    padding: EdgeInsets.fromLTRB(10, 63, 0, 0),
                    child: FloatingActionButton(
                      backgroundColor: Color(Global.backgroundColor),
                      child: Icon(
                        Icons.menu,
                        size: 40,
                        color: Colors.black.withAlpha(150),
                      ),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    )),
                Positioned(
                  top: 65,
                  right: 15,
                  left: 80,
                  child: Container(
                    height: 50.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
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
                            onPressed: searchAndNavigate,
                            iconSize: 30.0,
                          )),
                      onChanged: (val) {
                        searchAddr = val;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 130.0, 16.0, 16.0),
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
                        ),
                        confirmFinalPosition(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
} //End of _GoogleMaps class

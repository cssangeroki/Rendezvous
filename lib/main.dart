import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/firebaseFunctions.dart';
import 'pages/firebaseFunctions.dart';
import 'pages/page1.dart';
import 'pages/page3.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/*
//Below are some the libraries I use for the map implementation - Adarsh
import 'dart:async';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'src/locations.dart' as locations;

import 'package:geolocator/geolocator.dart';
*/
void main() async {
  //runApp(MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await _signInAnonymously();
  runApp(MyApp());
}

Future<void> _signInAnonymously() async {
  try {
    final AuthResult result = await FirebaseAuth.instance.signInAnonymously();
    FirebaseUser user = result.user;
    FirebaseFunctions.currentUID = user.uid;

    await FirebaseFunctions.refreshFirebaseUserData();
    await FirebaseFunctions.refreshFirebaseRoomData();
  } catch (e) {
    print(e);
  }
}

void pushToHomeScreen(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => MapRender()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    String initialRoute = '/page1';
    if (FirebaseFunctions.currentUserData["roomCode"] != null) {
      initialRoute = '/map';
    }
    return MaterialApp(
        title: 'Retrieve Text Input',
        theme: ThemeData(
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'Goldplay',
                fontSizeFactor: 1.1,
                fontSizeDelta: 2.0,
              ),
        ),
        debugShowCheckedModeBanner: false,
        home: Page1(),
        routes: {
          '/map': (BuildContext context) => MapRender(),
          '/page1': (BuildContext context) => Page1()
        },
        initialRoute: initialRoute);
  }
}

/*
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
  String nameInput = (''); // name variable to be stored

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
}*/

/*
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

class MapRender extends StatefulWidget {
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

  //Marker _markers;
  //Function initState initialises the state of variables
  @override
  void initState(){
    super.initState();
    initFunctionCaller();
  }

  void initFunctionCaller() async{
    await _getUserLocation();
    _lastMapPosition = _center;
    //_getUserAddress();
    _onAddMarkerButtonPressed();
    print("Done initialising variabels for map");
    print(_center);
  }
  //Function used to get users original position
  Future <void> _getUserLocation() async {
    currPosition = await currentLocation();
    print("Current Position = " + currPosition.toString());
    setState(() {
      _center = LatLng(currPosition.latitude, currPosition.longitude);
    });
    print("Center = " + _center.toString());
  }

  //Getting the user address from the location coordinates
  Future <void> _getUserAddress() async {
    try {
      List<Placemark> p = await Geolocator().placemarkFromCoordinates(
          _center.latitude, _center.longitude);

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

  void _onAddMarkerButtonPressed() async{
    //deleting the current marker and replacing it with the new one
    _markers = {};
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
    });
  }

  void _searchandNavigate(){
    //Get the placemark from the search address, and then store the center and userAddress
    Geolocator().placemarkFromAddress(searchAddr).then((value) async{
      mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target:
          LatLng(value[0].position.latitude, value[0].position.longitude),
          zoom: 15.0)));
      _center = LatLng(value[0].position.latitude, value[0].position.longitude);
      _lastMapPosition = _center;
      _getUserAddress();
      await _onAddMarkerButtonPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: Text('Maps'),
              backgroundColor: Colors.lightBlue,
            ),
            body: _center == null
                ? Container(
              child: Center(
                child: Text(
                  'loading map..',
                  style: TextStyle(
                      fontFamily: 'Avenir-Medium',
                      color: Colors.grey[400]),
                ),
              ),
            )
                : Container(
              child: Stack(children: <Widget>[
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
                    child: Column(children: <Widget>[
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
                    ]),
                  ),
                )
              ]),
            )));
  }
}*/

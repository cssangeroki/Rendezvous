import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'firebaseFunctions.dart';
import '../expandedSection.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sliding_up_panel/sliding_up_panel.dart';

//import 'package:link/link.dart';
import "../googleMaps.dart";
import "../globalVar.dart";
import "../findYelpPlaces.dart";

//Below are variables we will use for the sliders
double midSliderVal = 5;
double userSliderVal = 5;

String category;
//Here I'm creating a reference to our firebase
final firebase = Firestore.instance;
GlobalKey<_MapRenderState> renderKey = GlobalKey<_MapRenderState>();

class MapRender extends StatefulWidget {
  final Widget child;
  final bool expand;

  MapRender({this.expand = false, this.child});
  @override
  _MapRenderState createState() => _MapRenderState();
}

class _MapRenderState extends State<MapRender> {
  List<String> nameList = Global.nameList;
  final String userDocID = FirebaseFunctions.currentUID;
  final String roomDocID = FirebaseFunctions.currentUserData["roomCode"];
  StreamSubscription<DocumentSnapshot> roomListener;

  var _isExpanded = new List<bool>.filled(50, false, growable: true);

  @override
  void initState() {
    super.initState();
    Global.finalRad = midSliderVal;
    newPlacesListener();
    nameListListener();
    listenToRoom();
  }

  //Another function that creates a listener for the roomData (Not the users, but other room data)
  void listenToRoom() {
    var locChanged = false;
    roomListener = firebase
        .collection("rooms")
        .document(roomDocID)
        .snapshots()
        .listen((event) {
      setState(() {
        FirebaseFunctions.roomData["host"] = event.data["host"];
        //If the final location changed, we will alert the listener so that the route can be changed
        if (FirebaseFunctions.roomData["Final Location"] != event.data["Final Location"]){
          locChanged = true;
        }
        FirebaseFunctions.roomData["Final Location"] =
            event.data["Final Location"];
        FirebaseFunctions.roomData["Final Location Address"] =
            event.data["Final Location Address"];
        if (locChanged == true){
          Global.finalLocationChanged.notifyListeners();
        }
      });
    });
  }

  //This function will be used to set a listener for whenever findingYelpPlaces is called in other widgets
  void newPlacesListener() {
    Global.mapRPfindYPListener.addListener(() {
      _updateYelpVenues();
      Global.mapRPfindYPListener.value = false;
    });
  }

  //This function just lets the app reset to show the users names whenever the users change
  void nameListListener() {
    Global.mapRPnameListListener.addListener(() {
      setState(() {
        nameList = Global.nameList;
      });
      Global.mapRPnameListListener.value = false;
    });
  }

  //This functions is used when we search a category for yelp
  void searchingYelpCategory() async {
    print("Entered searchingYelpCategory");
    await YelpPlaces.findingPlaces();
    print("Returned from findingPlaces");
    Global.findYPCalled.notifyListeners();
    Global.findYPCalled.value = true;
    _updateYelpVenues();
  }

  var _arrLength;

  void _updateYelpVenues() {
    YelpPlaces.updateYelpVenues();
    setState(() {
      _arrLength = Global.arrLength;
    });
  }

  void _toggleExpand(var index) {
    setState(() {
      _isExpanded[index] = !_isExpanded[index];
    });
  }

  Widget _viewYelp() {
    _updateYelpVenues();
    if (_arrLength == null) {
      return Text(
        "Loading Places",
        style: TextStyle(
            color: Colors.black, fontFamily: 'Goldplay', fontSize: 30),
      );
    }

    if (_arrLength == 0) {
      return Container(
        height: 500,
        width: 500,
        color: Color(Global.backgroundColor),
        child: Text(
          "No Places Found.",
          style: TextStyle(
              color: Colors.black, fontFamily: 'Goldplay', fontSize: 30),
        ),
        alignment: Alignment.center,
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(7, 0, 7, 0),
      child: Container(
        child: ListView.builder(
          itemCount: _arrLength,
          itemBuilder: (BuildContext context, int index) {
            //return new Text(names[index]);
            return new Container(
              margin: EdgeInsets.fromLTRB(15, 10, 15, 10),
              decoration: BoxDecoration(
                color: Color(Global.whiteColor),
                //border: Border.all(color: Colors.black38),
                borderRadius: BorderRadius.all(Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.6),
                    spreadRadius: 0.5,
                    blurRadius: 6,
                    offset: Offset(7, 6), // changes position of shadow
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    //padding: EdgeInsets.fromLTRB(10, 0, 10, 0),

                    /*child: Link(
                  url: Global.urls[index],*/
                    child: Row(
                      children: <Widget>[
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.87,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        topRight: Radius.circular(10)),
                                  ),
                                  child: InkWell(
                                    onTap: () => _toggleExpand(index),
                                    child: Container(
                                      child: Row(
                                        children: <Widget>[
                                          Container(
                                            width: 90,
                                            height: 90,
                                            padding: EdgeInsets.all(8),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10),
                                              ),
                                              child: Image.network(
                                                Global.images[index] == null
                                                    ? 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910'
                                                    : '${Global.images[index]}',
                                                // 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5.0),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                MergeSemantics(
                                                  child: Row(
                                                    children: <Widget>[
                                                      Flexible(
                                                        child: Container(
                                                          padding: EdgeInsets
                                                              .fromLTRB(
                                                                  0, 0, 0, 0),
                                                          child: Text(
                                                            "${Global.names[index]} ",
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            softWrap: true,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'GoldPlay',
                                                              color: Colors
                                                                  .black
                                                                  .withAlpha(
                                                                      200),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                              fontSize: 18,
                                                            ),
                                                            textAlign:
                                                                TextAlign.left,
                                                          ),
                                                        ),
                                                        //textAlign: TextAlign.right,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                AnimatedOpacity(
                                                  // If the widget is visible, animate to 0.0 (invisible).
                                                  // If the widget is hidden, animate to 1.0 (fully visible).
                                                  opacity: !_isExpanded[index]
                                                      ? 1.0
                                                      : 0.0,
                                                  duration: Duration(
                                                      milliseconds: 500),

                                                  child: Text(
                                                    'Click to see more information',
                                                    maxLines: 1,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                ExpandedSection(
                                    expand: _isExpanded[index],
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          padding:
                                          EdgeInsets.fromLTRB(60, 0, 0, 5),
                                          width: double.infinity,
                                          child: Text(
                                            "Address: ${Global.locations[index]} ",
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            style: TextStyle(
                                              color: Color(Global.blackColor),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              EdgeInsets.fromLTRB(60, 0, 0, 5),
                                          width: double.infinity,
                                          child: Text(
                                            "Rating: ${Global.ratings[index]} ",
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            style: TextStyle(
                                              color: Color(Global.blackColor),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              EdgeInsets.fromLTRB(60, 0, 0, 5),
                                          width: double.infinity,
                                          child: Text(
                                            Global.phoneNums[index] == ''
                                                ? 'Phone number is unavailable'
                                                : 'Phone Number: ${Global.phoneNums[index]}',
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color:
                                                    Color(Global.blackColor)),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Container(
                                          padding:
                                              EdgeInsets.fromLTRB(60, 0, 0, 5),
                                          width: double.infinity,
                                          child: Text(
                                            Global.prices[index] == null
                                                ? 'Price is unavailable'
                                                : 'Price: ${Global.prices[index]}',
                                            overflow: TextOverflow.ellipsis,
                                            softWrap: true,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Color(0xff757575)),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          height: 95,
                                          child: Row(children: <Widget>[
                                            //Final Position Button

                                            Container(
                                              margin: EdgeInsets.fromLTRB(
                                                  20, 0, 0, 0),
                                              height: 70,
                                              width: 70,
                                              child: FittedBox(
                                                child: FloatingActionButton(
                                                  backgroundColor:
                                                      Color(0xff21bf73),
                                                  child: Icon(
                                                    Icons.check_circle,
                                                    size: 40,
                                                  ),
                                                  elevation: 2,
                                                  onPressed: (){
                                                    FirebaseFunctions.setFinalPosition(Global.names[index], Global.locations[index]);
                                                  },
                                                ),
                                              ),
                                            ),

                                            //Yelp Button
                                            Container(
                                                height: 70,
                                                width: 70,
                                                margin: EdgeInsets.fromLTRB(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.44,
                                                    0,
                                                    0,
                                                    0),
                                                child: FittedBox(
                                                  child: FloatingActionButton(
                                                      backgroundColor:
                                                          Color(0xffaa1802),
                                                      child: Container(
                                                        height: 50,
                                                        width: 50,
                                                        child: Image.asset(
                                                          'images/yelp_icon.png',
                                                        ),
                                                      ),
                                                      elevation: 2,
                                                      onPressed: () {
                                                        launch(
                                                            Global.urls[index]);
                                                      }),
                                                )),

                                            SizedBox(
                                              height: 20,
                                            )
                                          ]),
                                        ),
                                      ],
                                    )),
                                /*Container(
                        margin: EdgeInsets.fromLTRB(8, 8, 8, 8),
                        height: 90,
                        width: 90,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          child: Image.network(
                            Global.images[index] == null
                                ? 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910'
                                : '${Global.images[index]}',
                            // 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910',
                            fit: BoxFit.cover,
                          ),
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
                                    child: Container(
                                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: Text(
                                        "${Global.names[index]} ",
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: true,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color:
                                                Theme.of(context).primaryColor),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    //textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              child: Text(
                                'Click to open Yelp page',
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey),
                              ),
                            ),
                            SizedBox(height: 5),
                          ],
                        ),
                      )*/
                              ],
                              // ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _slideUpPanel() {
    return SlidingUpPanel(
      //maxHeight: 600,
      backdropEnabled: true,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
      panel: Center(
        child: Container(
            decoration: BoxDecoration(
              color: Color(Global.backgroundColor),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            padding: EdgeInsets.fromLTRB(0, 80, 0, 0),
            child: _viewYelp()),
      ),
      collapsed: Container(
        decoration: BoxDecoration(
          color: Color(Global.backgroundColor),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
        ),
        child: Center(child: Container()),
      ),
      minHeight: MediaQuery.of(context).size.height * 0.10,
      maxHeight: MediaQuery.of(context).size.height * 0.70,
      body: GoogleMaps(),
    );
  }

  Widget _viewDrawer() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Color(Global
            .backgroundColor), //This will change the drawer background to blue.
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
                    'Host:',
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
                    "${FirebaseFunctions.roomData["host"]}",
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
                    'Final Location: ',
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
                  title: SelectableText(
                    "${FirebaseFunctions.roomData["Final Location"]}" ??
                        "No location set",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    enableInteractiveSelection: true,
                  ),
                  onTap: null,
                ),
              ),
              Container(
                child: ListTile(
                  title: Text(
                    'Final Location Address:',
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
                  title: SelectableText(
                    "${FirebaseFunctions.roomData["Final Location Address"]}" ??
                        "No address set",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                    enableInteractiveSelection: true,
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
              _categoryBar(),

              Container(
                child: ListTile(
                  title: Text(
                    'Range from midpoint: $midSliderVal mi',
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  onTap: null,
                ),
              ),
              _midpointSlider(),
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
                  child: _leaveRoomButton()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryBar() {
    return Container(
      margin: EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        color: Colors.white,
      ),
      child: TextField(
        decoration: InputDecoration(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            hintText: "Enter category...",
            contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: searchingYelpCategory,
              iconSize: 20.0,
            )),
        onChanged: (val) {
          setState(() {
            category = val;
            Global.finalCategory = category;
          });
        },
      ),
    );
  }

  Widget _midpointSlider() {
    return SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: Colors.black,
          inactiveTrackColor: Color(0xff757575),
          trackShape: RectangularSliderTrackShape(),
          trackHeight: 8.0,
          thumbColor: Colors.white,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
          overlayColor: Colors.red.withAlpha(300),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
        ),
        child: Container(
          child: Slider(
            value: midSliderVal,
            onChanged: (double val) {
              //We need to connect the yelp API here
              setState(() {
                midSliderVal = val;
              });
            },
            onChangeEnd: (double val) async {
              setState(() {
                //can I do this
                Global.finalRad = val;
              });
              searchingYelpCategory();
            },
            min: 1,
            max: 25,
            divisions: 24,
          ),
        ));
  }
/*
  Widget _userSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.red[500],
        inactiveTrackColor: Colors.red[100],
        trackShape: RectangularSliderTrackShape(),
        trackHeight: 4.0,
        thumbColor: Colors.white,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
        overlayColor: Colors.red.withAlpha(32),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
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
    );
  }*/

  Widget _leaveRoomButton() {
    return ButtonTheme(
      minWidth: double.infinity,
      height: 60.0,
      padding: EdgeInsets.all(10.0),
      buttonColor: Colors.white,
      child: RaisedButton(
        child: Text("Leave Room",
            style: new TextStyle(fontSize: 20.0, color: Colors.black)),
        onPressed: () async {
          //Adding some code to turn off all listeners
          Global.mapRPnameListListener.removeListener(() {});
          //Global.mapRPnameListListener.dispose();
          Global.mapRPfindYPListener.removeListener(() {});
          //Global.mapRPfindYPListener.dispose();
          Global.findYPCalled.removeListener(() {});
          //Global.findYPCalled.dispose();
          Global.finalLocationChanged.removeListener(() {});

          String roomCodeString = FirebaseFunctions.roomData["roomCode"];

          await Firestore.instance
              .collection("rooms")
              .document(roomCodeString)
              .collection("users")
              .getDocuments()
              .then((data) {
            print("I'm running");
            print(data.documents.length);
            Global.memberListener.cancel();
            roomListener.cancel();
            FirebaseFunctions.removeCurrentUserFromRoom(
                roomCodeString, data.documents.length);
          });

          Navigator.pushNamedAndRemoveUntil(
              context, '/page1', (route) => false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        //appBar: appBarMain(context),
        body: Container(
          color: Color(Global.backgroundColor),
          child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: _slideUpPanel()),
        ),
        drawer: _viewDrawer(),
      ),
    );
//);
  }
}

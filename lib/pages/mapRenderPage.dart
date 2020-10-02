import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:async/async.dart';

import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../appBar.dart';
import 'firebaseFunctions.dart';
import '../expandedSection.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; //Alternate Rating

//import 'package:link/link.dart';
import "../googleMaps.dart";
import "../globalVar.dart";
import "../findYelpPlaces.dart";
import 'package:share/share.dart';
//import "../dynamicLinks.dart";
import 'dart:convert';



import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

//Will use these import for autocompleting text
import 'package:autocomplete_textfield/autocomplete_textfield.dart';

//import for the route button on the info page
import '../routes.dart';

//import for error checking
import '../errorChecking.dart';
import '../backendFunctions.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

const String mapsAPI_KEY = "AIzaSyBV961Ztopz9vyZrJq0AYAMJUTHmluu3FM";
//Below are variables we will use for the sliders
double midSliderVal = 1;
double userSliderVal = 5;

bool slideUpPanelCollapsed = true;
String newAddress;

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

class Message {
  static List messages = [];

  static Future<List<Widget>> getAndUpdateMessages(size,
      {isUpdate = false, var message}) async {
    if (!isUpdate) {
      messages = await BackendMethods.getMessages(FirebaseFunctions.roomData["groupChatID"]);
    } else {
      messages.add(message);
    }

    String userID = FirebaseFunctions.currentUID;

    List<Widget> msgList = <Widget>[];

    DateTime currentDate = messages.length == 0 ? DateTime.now() : DateTime.parse(messages[0]["dateCreated"]).toLocal();
    bool didAdd = false;

    for (var message in messages) {
      DateTime datetime = DateTime.parse(message["dateCreated"]).toLocal();

      if (currentDate.day == datetime.day &&
          currentDate.year == datetime.year &&
          currentDate.month == datetime.month) {
      
        if (!didAdd) {
          Widget msgTitle = Message.createDayTitle(BackendMethods.convertDateToPresentDate(datetime, isTitle: true));
          msgList.add(msgTitle);
          didAdd = true;
        }
      } else {
        currentDate = datetime;
        didAdd = false;
      }
     
      NetworkImage profileImage = FirebaseFunctions.roomData["profileImages"][message["from"]];
      String name = FirebaseFunctions.roomData["userNames"][message["from"]] ?? null;
      
      if(profileImage == null || name == null) {
        // if one of them is null, have to run bottom code
        Map<String, dynamic> attributes = jsonDecode(message["attributes"]);
        String profileImageURL = attributes["profileImage"];
        // when the user of this message left the chat, here's the backup data
        NetworkImage cachedData = Global.imageCache[profileImageURL];
        if(profileImage == null) {
          if(cachedData != null) {
            profileImage = cachedData;
          } else {
            Global.imageCache[profileImageURL] = NetworkImage(profileImageURL);
            profileImage = Global.imageCache[profileImageURL];
          }
        }

        if(name == null) {
          name = attributes["userName"];
        }
      }
    
      Widget msg = Message.createMessage(
          size,
          name,
          message["body"],
          datetime,
          userID == message["from"],
          profileImage != null ? profileImage : null);
      msgList.add(msg);
    }

    if (msgList.length == 0) {
      msgList.add(Message.createDayTitle("No messages found"));
    }

    return msgList;
  }

  static Widget createDayTitle(String title) {
    return new Container(
        child: Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                decoration: TextDecoration.underline,
                fontStyle: FontStyle.italic)));
  }

  static Widget createMessage(double size, String who, String text,
      DateTime date, bool isMe, NetworkImage img) {
    Color backgroundColor = isMe
        ? Color.fromRGBO(240, 215, 255, 1.0)
        : Color.fromRGBO(236, 236, 236, 1.0);
    var showAnonymous = img == null ? true : false;
    return Container(
        child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
                    width: size * 0.08,
                    height: size * 0.08,
                    child: showAnonymous
                        ? Image(
                            image: AssetImage('images/anonymous.png'),
                          )
                        : null,
                    decoration: !showAnonymous
                        ? new BoxDecoration(
                            shape: BoxShape.circle,
                            image: new DecorationImage(
                                fit: BoxFit.cover, image: img))
                        : null,
                  ),
                  Align(
                      alignment: Alignment.centerRight,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                              width: size,
                              color: backgroundColor,
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  20, 10.0, 20.0, 10),
                                              child: Text(isMe ? "Me" : who,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold))),
                                          Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  20, 0, 20.0, 10),
                                              child: Text(text,
                                                  textAlign: TextAlign.left))
                                        ]),
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                  20, 0, 20.0, 10),
                                              child: Text(
                                                  BackendMethods
                                                      .convertDateToPresentDate(
                                                          date),
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                      fontStyle:
                                                          FontStyle.italic))),
                                        ])
                                  ]))))
                ])));
  }
}

class _MapRenderState extends State<MapRender>
    with SingleTickerProviderStateMixin {
  List<String> nameList = Global.nameList;
  final String userDocID = FirebaseFunctions.currentUID;
  final String roomDocID = FirebaseFunctions.currentUserData["roomCode"];
  StreamSubscription<DocumentSnapshot> roomListener;
  int hours;
  int min;

  String sortCategory = "Distance";

  String timeDisplayText;
  bool doSendMessage = false;
  List<Widget> messages = [];
  bool didRetrieveMessages = false;
  double height = 0;
  final textController = TextEditingController();

  double keyboardPadding = 0.0;
  double currentKeyBoardPadding = 0.0;
  bool isTextEditing = false;

  String messageBody;

  ScrollController scrollController = new ScrollController();
  double maxHeightScroll = 0.0;

  List<String> suggestedAddresses = [];

  AutoCompleteTextField addressSearchField;
  GlobalKey<AutoCompleteTextFieldState> key = new GlobalKey();

  CancelableOperation futureToCancel;

  var _isExpanded = new List<bool>.filled(50, false, growable: true);

  @override
  void initState() {
    super.initState();
    Global.finalRad = midSliderVal;
    listenToTime();
    newPlacesListener();
    nameListListener();
    listenToRoom();
    searchingForCategory();
  }

  void callbackSocket(String type, data) async {
    if (type == "messageAdded") {
      Future<List<Widget>> futureMsgs = Message.getAndUpdateMessages(MediaQuery.of(context).size.width * 0.75);

      futureMsgs.then((msgs) async {

        setState(() {
          messages = msgs;
          maxHeightScroll = 0.0;
        });

        Timer(Duration(milliseconds: 500), () {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      });
    }
  }

  //Another function that creates a listener for the roomData (Not the users, but other room data)
  void listenToRoom() {
    var locChanged = false;
    roomListener = firebase
        .collection("rooms")
        .document(roomDocID)
        .snapshots()
        .listen((event) {
      if (!mounted) {
        return;
      }
      setState(() {
        FirebaseFunctions.roomData["groupChatID"] = event.data["groupChatID"];
        FirebaseFunctions.roomData["host"] = event.data["host"];
        FirebaseFunctions.roomData["host UID"] = event.data["host UID"];
        //If the final location changed, we will alert the listener so that the route can be changed
        if (FirebaseFunctions.roomData["Final Location"] !=
            event.data["Final Location"]) {
          locChanged = true;
        }
        FirebaseFunctions.roomData["Final Location"] =
            event.data["Final Location"];
        FirebaseFunctions.roomData["Final Location Address"] =
            event.data["Final Location Address"];
        FirebaseFunctions.roomData["Final LatLng"] = event.data["Final LatLng"];
        if (locChanged == true) {
          //Global.finalLocationChanged.notifyListeners();
          Global.finalLocationChanged.value ^= true;
        }
      });
    });
  }

  void listenToTime() {
    Global.timeChanged.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        hours = Global.hours;
        min = Global.minutes;
        if (hours == -1 || min == -1) {
          timeDisplayText =
              "Sorry, a problem occurred retrieving the travel time";
        } else {
          timeDisplayText = "Approximately ${hours}hrs ${min}min";
        }
      });
    });
  }

  //This is called whenever we search for a category on the googleMaps page.
  //We simply call setState to update the app to show whether it is searching for places or not
  void searchingForCategory() {
    Global.searchingPlaces.addListener(() {
      setState(() {});
    });
  }

  //This function will be used to set a listener for whenever findingYelpPlaces is called in other widgets
  void newPlacesListener() {
    Global.mapRPfindYPListener.addListener(() {
      if (!mounted) {
        return;
      }
      sortCategory = "Distance";
      _updateYelpVenues();
    });
  }

  //This function just lets the app reset to show the users names whenever the users change
  void nameListListener() {
    Global.mapRPnameListListener.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        nameList = Global.nameList;
      });
    });
  }

  //This functions is used when we search a category for yelp
  void searchingYelpCategory() async {
    if (futureToCancel != null) {
      futureToCancel.cancel();
    }
    //Set searching Category to true so that the loading sign shows
    Global.searchingCategory = true;
    //print("Future is Canceled: ${futureToCancel.isCanceled}");
    futureToCancel = CancelableOperation.fromFuture(YelpPlaces.findingPlaces(),
        onCancel: () {
      print("findingPlaces canceled");
    });
    await futureToCancel.value;
    if (futureToCancel.isCanceled) {
      return;
    }
    //If the future is not cancelled, set the result to false, so that the result is displayed
    Global.searchingCategory = false;
    //await YelpPlaces.findingPlaces();
    Global.findYPCalled.value ^= true;
    _updateYelpVenues();
  }

  //This function will be used to notify the maps page when the user changes their address
  void userAddressChanged() {
    Global.userLocChanged.value ^= true;
  }

  var _arrLength;

  void _updateYelpVenues() {
    if (!mounted) {
      return;
    }
    YelpPlaces.updateYelpVenues();
    setState(() {
      _arrLength = Global.arrLength;
    });
  }

  //This function will be used to suggest address when the user searches
  Future<void> autoCompleteSuggestions(String searchString) async {
    //First thing we will do is clear suggestedAddresses List
    suggestedAddresses.clear();
    if (searchString == "" || searchString == null) {
      return;
    }
    //Searching for places similar to the location being searched. Biased to 100km radius of the user current location
    var response = await http.post(
        "https://maps.googleapis.com/maps/api/place/queryautocomplete/json?key=$mapsAPI_KEY&location=${Global.userPos.latitude},${Global.userPos.longitude}&radius=100000&input=$searchString");
    if (response.statusCode == 200) {
      var decoded = await convert.jsonDecode(response.body);
      //If the we the http request fails, let the user know we are unable to find any suggestions
      if (decoded['status'] != 'OK') {
        suggestedAddresses.add("Unable to find any suggestions");
        return;
      }
      //Otherwise, I will set a variable as the predictions category for the user
      var predictions = decoded['predictions'];
      //Add the top ten suggestions to our List of suggestedAddresses
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

  void _toggleExpand(var index) {
    setState(() {
      for (var i = 0; i < _isExpanded.length; i++) {
        if (i == index) {
          _isExpanded[index] = !_isExpanded[index];
        } else {
          _isExpanded[i] = false;
        }
      }
    });
  }

  void clearGlobalArrays() {
    Global.names.clear();
    Global.resultCords.clear();
    Global.locations.clear();
    Global.urls.clear();
    Global.images.clear();
    Global.ratings.clear();
    Global.phoneNums.clear();
    Global.prices.clear();
    Global.isOpen.clear();
    Global.addresses.clear();
    Global.states.clear();
    Global.cities.clear();
    Global.zipCodes.clear();
  }

  void changeOrderToPrice() {
    setState(() {
      for (var place in Global.orderedByPrice) {
        Global.names.add(place['name']);
        Global.resultCords.add(LatLng(place['coordinates']['latitude'],
            place['coordinates']['longitude']));
        Global.locations.add(place['location']);
        Global.urls.add(place['url']);
        Global.images.add(place['image_url']);
        Global.ratings.add(place['rating']);
        Global.isOpen.add(place['isOpen']);
        Global.phoneNums.add(place['phone']);
        Global.prices.add(place['price']);
      }
    });
  }

  void changeOrderToRating() {
    setState(() {
      for (var place in Global.orderedByRating) {
        Global.names.add(place['name']);
        Global.resultCords.add(LatLng(place['coordinates']['latitude'],
            place['coordinates']['longitude']));
        Global.locations.add(place['location']);
        Global.urls.add(place['url']);
        Global.images.add(place['image_url']);
        Global.ratings.add(place['rating']);
        Global.isOpen.add(place['isOpen']);
        Global.phoneNums.add(place['phone']);
        Global.prices.add(place['price']);
      }
    });
  }

  void changeOrderToDistance() {
    setState(() {
      for (var place in Global.orderedByDistance) {
        Global.names.add(place['name']);
        Global.resultCords.add(LatLng(place['coordinates']['latitude'],
            place['coordinates']['longitude']));
        Global.locations.add(place['location']);
        Global.urls.add(place['url']);
        Global.images.add(place['image_url']);
        Global.ratings.add(place['rating']);
        Global.isOpen.add(place['isOpen']);
        Global.phoneNums.add(place['phone']);
        Global.prices.add(place['price']);
      }
    });
  }

  //Function used to return the button color to show highlighted button
  Color sortOrderButtonColor(String category) {
    if (sortCategory == category) {
      return Colors.black;
    }
    return Colors.white;
  }

  //Function used to return the color of the text of the sorting buttons
  Color sortOrderButtonTextColor(String category) {
    if (sortCategory == category) {
      return Colors.white;
    }
    return Colors.black;
  }

  Widget _viewYelp() {
    _updateYelpVenues();
    if (_arrLength == null) {
      return Text(
        "Loading Places",
        style: textSize30(),
      );
    }

    if (_arrLength == 0) {
      return Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Text(
          "No Places Found.",
          style: textSize30(),
        ),
        alignment: Alignment.center,
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(7, 0, 7, 0),
      child: Column(children: <Widget>[
        Container(
          height: 100,
          padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: Column(children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 0, 0),
              alignment: Alignment.centerLeft,
              child: Text("Showing $_arrLength results for: ",
                  style: GoogleFonts.roboto(
                      fontSize: 20, fontWeight: FontWeight.w500)),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(15, 5, 0, 0),
              alignment: Alignment.centerLeft,
              child: Text(
                  Global.finalCategory != null
                      ? "${Global.finalCategory}"
                      : "All",
                  style: GoogleFonts.roboto(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ]),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(15, 5, 7, 0),
          alignment: Alignment.centerLeft,
          child: Text("Sort by:",
              style: GoogleFonts.roboto(
                  fontSize: 15, fontWeight: FontWeight.w400)),
        ),
        _sortButtons(),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 4,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.88,
            child: ListView.builder(
              itemCount: _arrLength,
              itemBuilder: (BuildContext context, int index) {
                //return new Text(names[index]);
                return new Container(
                  margin: EdgeInsets.fromLTRB(0, 5, 0, 10),
                  decoration: BoxDecoration(
                    //border: Border.all(color: Colors.black38),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.6),
                        spreadRadius: 0.3,
                        blurRadius: 6,
                        offset: Offset(0, 6), // changes position of shadow
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
                            /*Center(
                            child: */
                            Container(
                              width: MediaQuery.of(context).size.width * 0.88,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _collapsedContainer(index),
                                  _expandedContainer(index),
                                ],
                                // ),
                              ),
                            ),
                            //),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sortButtons() {
    return Wrap(
      alignment: WrapAlignment.start,
      children: <Widget>[
        Container(
          height: 40,
          width: 100,
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          //color: Colors.blue,
          child: RaisedButton(
            elevation: 5,
            color: sortOrderButtonColor("Distance"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(color: Colors.grey),
            ),
            child: Text(
              "Distance",
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: sortOrderButtonTextColor('Distance'),
              ),
            ),
            onPressed: () {
              clearGlobalArrays();
              changeOrderToDistance();
              setState(() {
                sortCategory = "Distance";
              });
            },
          ),
        ),
        Container(
          height: 40,
          width: 100,
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          //color: Colors.blue,
          child: RaisedButton(
            elevation: 5,
            color: sortOrderButtonColor("Price"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(color: Colors.grey),
            ),
            child: Text(
              "Price",
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: sortOrderButtonTextColor('Price'),
              ),
            ),
            onPressed: () {
              //Want to add a function here that changes the slide up bar ordering;
              clearGlobalArrays();
              changeOrderToPrice();
              setState(() {
                sortCategory = "Price";
              });
            },
          ),
        ),
        Container(
          height: 40,
          width: 100,
          padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
          //color: Colors.blue,
          child: RaisedButton(
            elevation: 5,
            color: sortOrderButtonColor("Rating"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
              side: BorderSide(color: Colors.grey),
            ),
            child: Text(
              "Rating",
              style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sortOrderButtonTextColor('Rating')),
            ),
            onPressed: () {
              clearGlobalArrays();
              changeOrderToRating();
              setState(() {
                sortCategory = "Rating";
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _collapsedContainer(index) {
    return Container(
      width: 500,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        color: Colors.white,
      ),
      child: InkWell(
        onTap: () => _toggleExpand(index),
        child: Container(
          child: ClipRect(
            child: Row(
              children: <Widget>[
                ClipRect(
                  child: AnimatedContainer(
                    height: !_isExpanded[index] ? 90 : 160,
                    width: !_isExpanded[index]
                        ? 90
                        : MediaQuery.of(context).size.width * 0.88,
                    duration: Duration(milliseconds: 950),
                    curve: Curves.fastLinearToSlowEaseIn,
                    padding: !_isExpanded[index] ? EdgeInsets.all(8) : null,
                    child: !_isExpanded[index]
                        ? ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Image.network(
                              Global.images[index] == ''
                                  ? 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910'
                                  : '${Global.images[index]}',
                              // 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910',
                              fit: BoxFit.cover,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10)),
                            child: Image.network(
                              Global.images[index] == ''
                                  ? 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910'
                                  : '${Global.images[index]}',
                              // 'https://firebasestorage.googleapis.com/v0/b/rendezvous-b51b4.appspot.com/o/photo-1550747545-c896b5f89ff7.jpeg?alt=media&token=eb3eb883-86da-4b89-87e1-7490fd518910',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: !_isExpanded[index] ? 5 : 0,
                ),
                !_isExpanded[index]
                    ? Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            MergeSemantics(
                              child: Row(
                                children: <Widget>[
                                  Flexible(
                                    child: Container(
                                      width: !_isExpanded[index]
                                          ? double.infinity
                                          : 0,
                                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: Text(
                                        "${Global.names[index]} ",
                                        overflow: !_isExpanded[index]
                                            ? TextOverflow.ellipsis
                                            : null,
                                        softWrap: true,
                                        style: GoogleFonts.roboto(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18),
                                        /*textAlign:
                                                                  TextAlign
                                                                      .left,*/
                                      ),
                                    ),
                                    //textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5),
                            AnimatedContainer(
                              // If the widget is visible, animate to 0.0 (invisible).
                              // If the widget is hidden, animate to 1.0 (fully visible).
                              width: !_isExpanded[index] ? double.infinity : 0,
                              duration: Duration(milliseconds: 500),
                              child: Text(
                                'Click to see more information',
                                maxLines: 1,
                                style: textSize12Grey(),
                              ),
                            ),
                            SizedBox(height: 5),
                          ],
                        ),
                      )
                    : Container(
                        color: Colors.transparent,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget starRating(int index) {
    double rating = Global.ratings[index].toDouble();
    return RatingBarIndicator(
      itemBuilder: (context, _) => Icon(
        Icons.star,
        color: Color(Global.yellowColor),
      ),
      rating: rating,
      itemCount: 5,
      itemSize: 25.0,
      direction: Axis.horizontal,
    );
  }

  Widget _expandedContainer(index) {
    return Flexible(
      child: ExpandedSection(
        expand: _isExpanded[index],
        child: InkWell(
          onTap: () => _toggleExpand(index),
          child: Container(
            padding: EdgeInsets.fromLTRB(10, 20, 0, 0),
            height: 220,
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Row(children: <Widget>[
                      Container(
                        child: starRating(index),//Text(Global.ratings[index] == null ? '' : '${Global.ratings[index]}'), //
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Text(
                          Global.prices[index] == null
                              ? ''
                              : '${Global.prices[index]}',
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ]),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: Text(
                        '${Global.names[index]}',
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w700, fontSize: 20),
                        softWrap: true,
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        "${Global.locations[index]} ",
                        softWrap: true,
                        style: GoogleFonts.roboto(fontSize: 16),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        Global.phoneNums[index] == ''
                            ? ''
                            : '${Global.phoneNums[index]}',
                        softWrap: true,
                        style: GoogleFonts.roboto(fontSize: 16),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      //Yelp Button

                      Container(
                        height: 70,
                        width: 70,
                        margin: EdgeInsets.fromLTRB(40, 5, 0, 0),
                        child: FittedBox(
                          child: FloatingActionButton(
                              heroTag: null,
                              backgroundColor: Color(0xfff2f2f2),
                              child: Container(
                                height: 30,
                                width: 30,
                                child: Image.asset(
                                  'images/yelp_icon.png',
                                ),
                              ),
                              elevation: 3,
                              onPressed: () {
                                launch(Global.urls[index]);
                              }),
                        ),
                      ),
                      slideUpFinalLocSet(index),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget slideUpFinalLocSet(int index) {
    if (FirebaseFunctions.currentUID ==
        FirebaseFunctions.roomData["host UID"]) {
      return //Final Location Button
          Container(
        margin: EdgeInsets.fromLTRB(40, 20, 0, 0),
        height: 70,
        width: 70,
        child: FittedBox(
          child: FloatingActionButton(
            heroTag: null,
            backgroundColor: Colors.greenAccent,
            child: Icon(
              Icons.check_circle,
              size: 35,
              //color: Color(0xff21bf73),
            ),
            elevation: 4,
            onPressed: () {
              FirebaseFunctions.setFinalPosition(Global.names[index],
                  Global.locations[index], Global.resultCords[index]);
            },
          ),
        ),
      );
    }
    //Otherwise, we return an empty container
    return Container();
  }

  Widget slideUpPanelDisplayText() {
    //If the backend returned an error for the findingYelpPlaces call, we print an error
    if (Global.errorFindingYelpPlaces == true) {
      return Container(
        padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
        child: Text(
          'Sorry, but there seems to be a problem with retrieving the yelp Places. Please try searching again',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    } else if (Global.searchingCategory == false && Global.arrLength > 0) {
      return Container(
        padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
        child: Text(
          'Showing ${Global.arrLength} results for: ${Global.finalCategory} within ${Global.finalRad}mi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    } else if (Global.searchingCategory == false && Global.arrLength == 0) {
      return Container(
        padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
        child: Text(
          'No places found for: ${Global.finalCategory} within ${Global.finalRad}mi. Try increasing the search radius or changing the category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      sortCategory = "Distance";
      return Container(
        padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                    child: Text(
                  "Searching for: ${Global.finalCategory}",
                  softWrap: true,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
                Padding(
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: Center(
                    child: Container(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _collapsedSlideUpPanel() {
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 6,
                  blurRadius: 5,
                  offset: Offset(0, 0), // changes position of shadow
                ),
              ],
            ),
            child: SizedBox(
              width: 80,
              height: 8,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.fromLTRB(0, 25, 0, 0),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: onlyTop20(),
          ),
          child: slideUpPanelDisplayText(),
        ),
      ],
    );
  }

  GlobalKey _drawerKey = GlobalKey();

  Widget _slideUpPanel() {
    // for the keyboard
    if (isTextEditing) {
      final RenderBox box = _drawerKey.currentContext?.findRenderObject();
      if (box == null) {
        print("Closed");
        setState(() {
          currentKeyBoardPadding = 0.0;
        });
      }
    }
    return SingleChildScrollView(
      child: SlidingUpPanel(
        //maxHeight: 600,
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 9,
            offset: Offset(0, 15),
          ),
        ],
        backdropEnabled: true,
        borderRadius: onlyTop20(),
        panel: Container(
          padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
          child: Center(
            child: Container(
                decoration: BoxDecoration(
                  color: Color(Global.backgroundColor),
                  borderRadius: onlyTop20(),
                ),
                child: _viewYelp()),
          ),
        ),

        collapsed: _collapsedSlideUpPanel(),
        minHeight: 135,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        body: GoogleMaps(),
      ),
    );
  }

  Widget _tab2Contents() {
    return new Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: ListView(
        children: <Widget>[
          Container(
            child: ListTile(
              title: Text(
                'Final Location: ',
                style: textSize20(),
              ),
              onTap: null,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(30, 0, 0, 10),
            child: SelectableText(
                FirebaseFunctions.roomData["Final Location"] != null
                    ? "${FirebaseFunctions.roomData["Final Location"]},\n${FirebaseFunctions.roomData["Final Location Address"]}"
                    : "No location set",
                style: textSize20(),
                enableInteractiveSelection: true, onTap: () {
              Share.share(
                  "${FirebaseFunctions.roomData["Final Location"]}, ${FirebaseFunctions.roomData["Final Location Address"]}");
            }),
          ),
          Container(
            child: ListTile(
              title: Text(
                'Time Taken:',
                style: textSize20(),
              ),
              onTap: null,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(30, 0, 0, 10),
            child: SelectableText(
              hours != null ? timeDisplayText : "0hrs 0min",
              style: textSize20(),
              enableInteractiveSelection: true,
            ),
          ),
          Routes(),
        ],
      ),
    );
  }

  Widget _leaveRoomButton() {
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
        child: Text("Leave Room",
            style: new TextStyle(fontSize: 20.0, color: Colors.white)),
        onPressed: () async {
          //Adding some code to turn off all listeners
          Global.mapRPnameListListener.removeListener(() {});
          Global.mapRPfindYPListener.removeListener(() {});
          Global.findYPCalled.removeListener(() {});
          Global.finalLocationChanged.removeListener(() {});
          Global.timeChanged.removeListener(() {});
          Global.userLocChanged.removeListener(() {});

          //Reset the category
          Global.finalCategory = "All";

          String roomCodeString = FirebaseFunctions.roomData["roomCode"];
          String groupChatID = FirebaseFunctions.roomData["groupChatID"];
          String memberID = FirebaseFunctions.currentUserData["memberID"];

          await Firestore.instance
              .collection("rooms")
              .document(roomCodeString)
              .collection("users")
              .getDocuments()
              .then((data) {
            //print("I'm running");
            //print(data.documents.length);
            Global.memberListener.cancel();
            roomListener.cancel();
            FirebaseFunctions.removeCurrentUserFromRoom(
                roomCodeString, data.documents.length,
                groupChatID: groupChatID, memberID: memberID);
          });

          Navigator.pushNamedAndRemoveUntil(
              context, '/page1', (route) => false);
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
          trackHeight: 3.0,
          thumbColor: Colors.white,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.0),
          overlayColor: Color(Global.yellowColor).withAlpha(90),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 23.0),
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
            onChangeStart: (val) {},
            onChangeEnd: (double val) {
              setState(() {
                //can I do this
                print("Entered onChangeEnd");
                Global.finalRad = val;
                searchingYelpCategory();
              });
            },
            min: 1,
            max: 25,
            divisions: 24,
          ),
        ));
  }

  Widget _tab1Contents() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: ListView(
        children: <Widget>[
          Container(
            child: ListTile(
              title: Text(
                'People in this room:',
                style: textSize20(),
              ),
              onTap: null,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
            child: Text(
              "${nameList.join("\n")}" ?? "Name is Null",
              style: textSize20(),
            ),
          ),
          Container(
            child: ListTile(
              title: Text(
                'Host:',
                style: textSize20(),
              ),
              onTap: null,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
            child: Text(
              "${FirebaseFunctions.roomData["host"]}",
              style: textSize20(),
            ),
          ),
          Container(
            child: ListTile(
              title: Text(
                'Change your location to:',
                style: textSize20(),
              ),
              onTap: null,
            ),
          ),
          //Search bar
          _addressBar(),
          AddressSearchBarError(),
          Container(
            child: ListTile(
              title: Text(
                'Range from midpoint: $midSliderVal mi',
                style: textSize18(),
              ),
              onTap: null,
            ),
          ),
          _midpointSlider(),
          Container(
            child: ListTile(
              title: Text(
                'Your Code:',
                style: textSize20(),
              ),
              onTap: null,
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
            child: ListTile(
              title: SelectableText(
                "${FirebaseFunctions.roomData["roomCode"]}" ??
                    "roomCode is Null",
                style: textSize35(),
                enableInteractiveSelection: true,
                onTap: () async {
                  //String link =
                  //    await DynamicLinkService.createAppLink("Join my room!");
                  Share.share(
                    "${FirebaseFunctions.roomData["roomCode"]}",//\n$link",
                    subject: "Let's Rendezvous! Join my room!",
                  );
                },
              ),
              onTap: null,
            ),
          ),
          _leaveRoomButton(),
          Container(
            height: 120.0,
          )
        ],
      ),
    );
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

  Widget _addressBar() {
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
            userAddressChanged();
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
                userAddressChanged();
                //Navigator.pop(context);
              },
              iconSize: 30.0,
            )),
        textChanged: (val) {
          setState(() {
            newAddress = val;
            //Global.userAddress = val;
            autoCompleteSuggestions(val);
            //Global.finalCategory = category;
          });
        },
      ),
    );
  }

  Widget _tab3Contents() {
    //double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    if (!didRetrieveMessages) {
      setState(() {
        didRetrieveMessages = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Future<List<Widget>> futureMsgs = Message.getAndUpdateMessages(MediaQuery.of(context).size.width * 0.75);

        futureMsgs.then((msgs) async {
          await BackendMethods.establishSocket(callbackSocket);
          setState(() {
            messages = msgs;
            height = MediaQuery.of(context).size.width * 0.75;
          });
        });
      });
    } else if (maxHeightScroll == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (scrollController.hasClients) {
          double h = scrollController.position.maxScrollExtent;
          setState(() {
            maxHeightScroll = h == 0.0 ? 1.0 : h;
            scrollController = new ScrollController(initialScrollOffset: h);
          });
        }
      });
    }

    return new GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            currentKeyBoardPadding = 0.0;
            isTextEditing = false;
          });
        },
        child: Container(
            height: MediaQuery.of(context).size.height,
            width: double.infinity,
            child: Column(children: <Widget>[
              Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  height: currentKeyBoardPadding != null
                      ? height * 0.64 - currentKeyBoardPadding
                      : height * 0.64,
                  child: new ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.vertical,
                      itemCount: messages.length,
                      itemBuilder: (BuildContext ctx, int index) {
                        return messages[index];
                      })),
              Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                          height: height * 0.20,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextFormField(
                                    textInputAction: TextInputAction.done,
                                    controller: textController,
                                    onEditingComplete: () {
                                      // when on hits the done button

                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        isTextEditing = false;
                                        currentKeyBoardPadding = 0.0;
                                      });
                                    },
                                    onChanged: (text) {
                                      bool isNotEmpty = true;
                                      if (text.replaceAll(" ", "") == "" ||
                                          text == null) {
                                        isNotEmpty = false;
                                      }

                                      setState(() {
                                        doSendMessage = isNotEmpty;
                                        messageBody = text;
                                      });
                                    },
                                    onTap: () {
                                      Timer(Duration(milliseconds: 500), () {
                                        scrollController.jumpTo(scrollController
                                            .position.maxScrollExtent);
                                      });

                                      Future<bool> waiting() async {
                                        await Future.delayed(
                                            const Duration(seconds: 1));
                                        return true;
                                      }

                                      if (keyboardPadding == 0.0) {
                                        waiting().then((value) {
                                          double keyboardHeight =
                                              MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom;
                                          if (keyboardHeight != 0.0) {
                                            setState(() {
                                              isTextEditing = true;
                                              keyboardPadding = keyboardHeight;
                                              currentKeyBoardPadding =
                                                  keyboardHeight;
                                            });
                                          }
                                        });
                                      } else {
                                        setState(() {
                                          currentKeyBoardPadding =
                                              keyboardPadding;
                                          isTextEditing = true;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                        hintText: "Enter message",
                                        border: InputBorder.none,
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(25.0)),
                                            borderSide:
                                                BorderSide(color: Colors.grey)),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(25.0)),
                                            borderSide: BorderSide(
                                                color: Colors.grey))),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null),
                                Padding(
                                    padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                                    child: CupertinoButton(
                                        color: doSendMessage
                                            ? Color.fromRGBO(106, 171, 249, 1.0)
                                            : Color.fromRGBO(
                                                236, 236, 236, 1.0),
                                        onPressed: () async {
                                          if (messageBody != null &&
                                              doSendMessage) {
                                            String message = messageBody;

                                            await BackendMethods.sendMessage(
                                                FirebaseFunctions
                                                    .roomData["groupChatID"],
                                                message,
                                                BackendMethods
                                                    .getCurrentUTCTime(),
                                                FirebaseFunctions.currentUID);
                                            textController.clear();
                                            setState(() {
                                              doSendMessage = false;
                                              messageBody = null;
                                            });
                                          }
                                        },
                                        child: Text("Send")))
                              ]))))
            ])));
  }

  Widget _viewDrawer() {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Color(Global
            .backgroundColor), //This will change the drawer background to blue.
        //other styles
      ),
      // 0.88
      child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          child: Drawer(
            key: _drawerKey,
            child: DefaultTabController(
              length: 3,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Container(
                    height: MediaQuery.of(context).size.height * 0.08,
                  ),
                  Container(
                    height: 50,
                    color: Color(Global.backgroundColor),
                    child: TabBar(
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.black38,
                        labelStyle:
                            TextStyle(fontSize: 20, fontFamily: 'Roboto'),
                        unselectedLabelStyle:
                            TextStyle(fontSize: 15, fontFamily: 'Roboto'),
                        indicator: BubbleTabIndicator(
                          indicatorColor: Color(Global.yellowColor),
                          padding: EdgeInsets.fromLTRB(-24, -12, -24, 16),
                          indicatorHeight: 2,
                        ),
                        tabs: [
                          Tab(text: "Info"),
                          Tab(text: "Venue"),
                          Tab(text: "Chat"),
                        ]),
                  ),
                  Expanded(
                    child: Container(
                      child: TabBarView(children: [
                        _tab1Contents(),
                        _tab2Contents(),
                        _tab3Contents(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
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

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          //appBar: appBarMain(context),
          body: Container(
            color: Color(Global.backgroundColor),
            child: ClipRRect(borderRadius: onlyTop10(), child: _slideUpPanel()),
          ),

          drawer: _viewDrawer(),
        ),
      ),
    );
//);
  }
}

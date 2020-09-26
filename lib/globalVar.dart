import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class Global {
  static StreamSubscription<QuerySnapshot> memberListener;
  static List<LatLng> resultCords = [];
  static List<String> names = [];
  static List<String> locations = [];
  static List urls = [];
  static List images = [];
  static List ratings = [];
  static List isOpen = [];
  static List phoneNums = [];
  static List prices = [];
  static List addresses = [];
  static List cities = [];
  static List states = [];
  static List zipCodes = [];

  static double finalMidLon;
  static double finalMidLat;
  static String finalCategory = "All";
  static double finalRad;
  static double finalTime;

  static var primaryColor = 0xffffe8df;
  static var blackColor = 0xff888888;
  static var backgroundColor = 0xfff4f4f4;
  static var whiteColor = 0xffffffff;
  static var yellowColor = 0xffffcd3c;

  static var profileImage;
  static var updateProfileImage = false;

  static var arrLength;

  static List<String> nameList = [];

  static ValueNotifier findYPCalled = ValueNotifier(false);

  static ValueNotifier mapRPfindYPListener = ValueNotifier(false);

  static ValueNotifier mapRPnameListListener = ValueNotifier(false);

  static ValueNotifier finalLocationChanged = ValueNotifier(false);

  static ValueNotifier userLocChanged = ValueNotifier(false);

  static String userAddress;

  //Variables used to display travel time
  static int hours;
  static int minutes;

  //
  static ValueNotifier timeChanged = ValueNotifier(false);

  static LatLng userPos;

  //Creating a ValueNotifier to let the slideUpBar know when we are searching for places
  static ValueNotifier searchingPlaces = ValueNotifier(false);

  static bool searchingCategory = false;

  //Below are going to be variables that will be used for error checking
  static bool errorFindingUserAddress = false;
  static ValueNotifier errorFindingUserAddressListener = ValueNotifier(false);

  //Error checker for failure to get yelp places
  static bool errorFindingYelpPlaces = false;

  //Below are dictionaries that will be used for the different sorts
  static List<Map<String, dynamic>> orderedByPrice = [];
  //static List<Map<String, dynamic>> orderedByBestMatch = [];
  static List<Map<String, dynamic>> orderedByDistance = [];
  static List<Map<String, dynamic>> orderedByRating = [];
}

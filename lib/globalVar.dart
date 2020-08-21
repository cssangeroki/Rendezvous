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

  static double finalLon;
  static double finalLat;
  static String finalCategory;
  static double finalRad;
  static double finalTime;

  static var primaryColor = 0xffffe8df;
  static var blackColor = 0xff888888;
  static var backgroundColor = 0xfff4f4f4;
  static var whiteColor = 0xffffffff;

  static var arrLength;

  static List<String> nameList = [];

  static ValueNotifier findYPCalled = ValueNotifier(false);

  static ValueNotifier mapRPfindYPListener = ValueNotifier(false);

  static ValueNotifier mapRPnameListListener = ValueNotifier(false);
}

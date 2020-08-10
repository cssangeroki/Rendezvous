import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';

class Global{
  static StreamSubscription<QuerySnapshot> memberListener;
  static List<LatLng> resultCords = [];
  static List<String> names = [];
  static List<String> locations = [];
  static List urls = [];
  static List images = [];
  static List ratings =[];
  static List isOpen=[];
  static double finalLon;
  static double finalLat;
  static String finalCategory;
  static double finalRad;
  static double finalTime;

  static var arrLength;

  static List<String> nameList = [];

  static ValueNotifier findYPCalled = ValueNotifier(false);

  static ValueNotifier mapRPfindYPListener = ValueNotifier(false);

  static ValueNotifier mapRPnameListListener = ValueNotifier(false);
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Global{
  static StreamSubscription<QuerySnapshot> memberListener;
  static List<LatLng> resultCords = [];
  static List<String> names = [];
  static List<String> locations = [];
  static List urls = [];
  static List images = [];
  static double finalLon;
  static double finalLat;
  static String finalCategory;
  static double finalRad;

  static var arrLength;

  static List<String> nameList = [];
}
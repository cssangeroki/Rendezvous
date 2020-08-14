//This file will simply have the class YelpPlaces, and the functions _findingPlaces.
//It is so to increase modularity and have certain variables be accessed via different pages

import 'backendFunctions.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'globalVar.dart';
class YelpPlaces {
  //Function that will connect to yelp API
  static Future<void> findingPlaces() async {
    print("Searching for your place");
    Global.names.clear();
    Global.resultCords.clear();
    Global.locations.clear();
    Global.urls.clear();
    Global.images.clear();
    Global.ratings.clear();
    Global.phoneNums.clear();
    Global.prices.clear();
    double finalRadMiles = Global.finalRad * 1609.344;
    var businesses = "";
    businesses = await BackendMethods.getLocations(
        Global.finalLon, Global.finalLat, Global.finalCategory, finalRadMiles.toInt());
    var lat;
    var lon;
    var name;
    var address;
    var url;
    var image;
    var rating;
    var open;
    var phone;
    var price;

    for (var place in jsonDecode(businesses)) {
      lat = place['coordinates']['latitude'];
      lon = place['coordinates']['longitude'];
      var myLatlng = new LatLng(lat, lon);
      Global.resultCords.add(myLatlng);

      name = place['name'];
      Global.names.add(name);

      address = place['location'];
      Global.locations.add(address);

      url = place['url'];
      Global.urls.add(url);

      image = place['image_url'];
      Global.images.add(image);

      rating = place['rating'];
      Global.ratings.add(rating);



      open = place['isOpen'];
      Global.isOpen.add(open);

      phone= place['phone'];
      Global.phoneNums.add(phone);

      price=place['price'];
      Global.prices.add(price);


    }
    print(Global.phoneNums);
    // print("Locations: ${Global.resultCords}");
    // print("testing if I got a response:");
  }

  static void updateYelpVenues() {
      Global.arrLength = Global.names.length;
  }
}

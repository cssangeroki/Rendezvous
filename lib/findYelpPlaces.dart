//This file will simply have the class YelpPlaces, and the functions _findingPlaces.
//It is so to increase modularity and have certain variables be accessed via different pages

import 'backendFunctions.dart';
import 'dart:async';
import 'package:async/async.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'globalVar.dart';

class YelpPlaces {
  static CancelableOperation futureToCancel;

  //Function that will connect to yelp API
  static Future<void> findingPlaces() async {
    Global.names.clear();
    Global.resultCords.clear();
    Global.locations.clear();
    Global.urls.clear();
    Global.images.clear();
    Global.ratings.clear();
    Global.phoneNums.clear();
    Global.prices.clear();
    double finalRadMiles = Global.finalRad * 1609.344;
    var businesses;
    //businesses = await BackendMethods.getLocations(Global.finalLon,
    //  Global.finalLat, Global.finalCategory, finalRadMiles.toInt());
    if (futureToCancel != null) {
      futureToCancel.cancel();
    }
    futureToCancel = CancelableOperation.fromFuture(
        BackendMethods.getLocations(Global.finalLon, Global.finalLat,
            Global.finalCategory, finalRadMiles.toInt()), onCancel: () {
      print("Backend Call Cancelled");
    });
    try {
      businesses = await futureToCancel.value;
      Global.errorFindingYelpPlaces = false;
    } catch (e) {
      //If there is an error, we set an error checker to a value
      Global.errorFindingYelpPlaces = true;
      return;
    }
    print(businesses);
    if (futureToCancel.isCanceled == true) {
      return;
    }
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
    var addr;
    var city;
    var state;
    var zip;

    for (var place in jsonDecode(businesses)) {
      lat = place['coordinates']['latitude'];
      lon = place['coordinates']['longitude'];
      var myLatlng = new LatLng(lat, lon);
      Global.resultCords.add(myLatlng);

      name = place['name'];
      Global.names.add(name);

      addr = place['location'];
      Global.locations.add(addr);

      url = place['url'];
      Global.urls.add(url);

      image = place['image_url'];
      Global.images.add(image);

      rating = place['rating'];
      Global.ratings.add(rating);

      open = place['isOpen'];
      Global.isOpen.add(open);

      phone = place['phone'];
      Global.phoneNums.add(phone);

      price = place['price'];
      Global.prices.add(price);

      address = place['address'];
      Global.addresses.add(address);

      city = place['city'];
      Global.cities.add(city);

      state = place['state'];
      Global.states.add(state);

      zip = place['zip_code'];
      Global.zipCodes.add(zip);
    }
    print("done");
  }

  static void updateYelpVenues() {
    Global.arrLength = Global.names.length;
  }
}

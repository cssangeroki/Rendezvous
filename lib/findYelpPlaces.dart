//This file will simply have the class YelpPlaces, and the functions _findingPlaces.
//It is so to increase modularity and have certain variables be accessed via different pages

import 'dart:math';

import 'backendFunctions.dart';
import 'dart:async';
import 'package:async/async.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'globalVar.dart';

class YelpPlaces {
  static double meterToMiles = 0.000621371;
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
    Global.zipCodes.clear();
    Global.cities.clear();
    Global.addresses.clear();
    Global.states.clear();
    Global.distances.clear();

    Global.orderedByPrice.clear();
    Global.orderedByDistance.clear();
    Global.orderedByRating.clear();

    double finalRadMiles = Global.finalRad * 1609.344;
    var businesses;
    //businesses = await BackendMethods.getLocations(Global.finalLon,
    //  Global.finalLat, Global.finalCategory, finalRadMiles.toInt());
    if (futureToCancel != null) {
      futureToCancel.cancel();
    }
    futureToCancel = CancelableOperation.fromFuture(
        BackendMethods.getLocations(Global.finalMidLon, Global.finalMidLat,
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
    //This if statement is in case there is an error propo
    if (Global.errorFindingYelpPlaces == true) {
      Global.errorFindingYelpPlaces = true;
      return;
    }
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
      //Check if the place is actually withing the given radius. If it isn't, skip this place and don't add it to our displayed places
      bool validPlace = haversineDist(myLatlng);
      if (validPlace == false){
        continue;
      }
      addToDifferentOrders(place);
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

      Global.distances.add(place['distance'].toDouble() * meterToMiles);
    }
    sortOrderedByPrice();
    sortOrderedByRating();
    print("done");
    updateYelpVenues();
  }

  //This function simply adds the place to our orderedByPrice array
  static void addToDifferentOrders (dynamic place){
    Global.orderedByPrice.add(place);
    Global.orderedByDistance.add(place);
    Global.orderedByRating.add(place);
  }

  //This function sorts our orderedByPrice array
  static void sortOrderedByPrice(){
    Global.orderedByPrice.sort((a, b){
      return a['price'].toString().compareTo(b['price'].toString());
    });
  }

  static void sortOrderedByRating(){
    Global.orderedByRating.sort((a, b){
      return  -1 * a['rating'].compareTo(b['rating']);
    });
  }

  static void updateYelpVenues() {
    Global.arrLength = Global.names.length;
  }

  //This function uses the haversine formula as described on https://en.wikipedia.org/wiki/Haversine_formula
  //to calculate the distance between a newPlace and a midpoint, to ensure that the new place is within the
  //given radius.
  static bool haversineDist(LatLng newPlace) {
    double midLatRad = convertToRadians(Global.finalMidLat);
    double midLonRad = convertToRadians(Global.finalMidLon);
    double newLatRad = convertToRadians(newPlace.latitude);
    double newLonRad = convertToRadians(newPlace.longitude);
    double distanceInKm = Global.finalRad * 1.60934;
    var hav = haversine(midLatRad, newLatRad) +
        cos(midLatRad) *
            cos(newLatRad) *
            haversine(midLonRad, newLonRad);
    //print("Have = $hav");
    double radEarth = 6371;
    var dist = 2*radEarth*asin(sqrt(hav));
    //print("Distance of this place = $dist");
    //If the distance calculated is within the radius, return true, so we can display this location
    if (dist <= distanceInKm){
      //print("Returning true");
      return true;
    }
    //Otherwise return false
    return false;
  }

  //This function will be implementing the haversine formula to calculate angles
  static double haversine(double val1, double val2) {
    double newVal = val2 - val1;
    double toReturn = sin(newVal) * sin(newVal);
    return toReturn;
  }

  static double convertToRadians(double val){
    return val*pi/180;
  }
}

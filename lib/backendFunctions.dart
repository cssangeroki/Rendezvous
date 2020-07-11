import 'package:http/http.dart' as http;
import 'dart:convert';

class BackendMethods {

  static const String rootURL = 'https://rendezvousbackend.herokuapp.com';

  //              returns the businesses
  static getLocations(double longitude, double latitude, [String term, int radius]) async {

    print("Start getting data");


    var bodyJSON = <String, dynamic>{
                            'longitude': longitude,
                            'latitude': latitude,
                          };
    if(term != null) {
      bodyJSON['term'] = term;
    }
    if(radius != null) {
      bodyJSON['radius'] = radius;
    }
    final res = await http.post('$rootURL/yelpRoutes/nearby', 
                          headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                          },
                          body: jsonEncode(bodyJSON));
    
    if (res.statusCode == 200) {
        Map<String, dynamic> businesses = json.decode(res.body) as Map<String, dynamic>;
        return businesses;
    }
    else {
      return {"error":1};
    }
  }


}
import 'dart:convert';
import "globalVar.dart";
import 'package:Rendezvous/pages/firebaseFunctions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/firebaseFunctions.dart';




class BackendMethods {
  static const String rootURL = 'https://rendezvousbackend.herokuapp.com';

  static IO.Socket socket;

  static getCurrentUTCTime() {
    return DateTime.now().toUtc().toIso8601String();
  }

  static establishSocket(callback) async {
      socket = IO.io(rootURL, <String, dynamic>{
      'transports': ['websocket'],
      });
      
      socket.on('connect', (_) async {
        String token = await getToken();
        await FirebaseFunctions.refreshChatToken(token);
        socket.emit('syncMessages', {"token":token, "channelID":FirebaseFunctions.roomData["groupChatID"]});
      }); 

      socket.on("messageAdded", (data){
        callback("messageAdded", data);
      });

      socket.on("error", (data){
        print(data);
      });
    
      socket.on("memberJoined", (data){
        print(data);
      });
    

      socket.on('syncMessages', (data){
          print(data);
      });



      socket.emit('connect');

      socket.connect();

  }

  static disconnectSocket() {
    socket.disconnect();
  }

  static leaveRoom(String groupChatID, String memberID, int membersLength) async {

    var request = <String,dynamic>{
      "channelID" : groupChatID,
      "membersLength" : membersLength,
      "memberID" : memberID
    };
    
    print(request);
    final response = await http.post("$rootURL/twilioRoutes/leaveChat", headers: <String, String>{
      'Content-type': 'application/json; charset=UTF-8'
    },
    body: jsonEncode(request));


    if(response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {"error":1};
    }
  }

  static convertDateToPresentDate(DateTime date, {isTitle=false}) {
    
    var dateString = "";

    var minDate = DateTime.now().subtract(new Duration(days: 6));
    if(isTitle) {
        if(date.isAfter(minDate)) {
            final dateFormat = new DateFormat('EEEE');
            dateString = dateFormat.format(date);
        } else {
            final dateFormat = new DateFormat('MMMM dd, yyy');
            dateString = dateFormat.format(date);
        }
        return dateString;
    }

  
    final dateFormat = new DateFormat('hh:mm aaa');
    dateString = dateFormat.format(date);
    return dateString;
  }

  static joinGroupChat(String identity, String groupChatID) async {
      print("Called twice");
      var bodyJSON = <String, dynamic>{'identity':identity, 'channelID':groupChatID};
      final res = await http.post('$rootURL/twilioRoutes/joinGroupChat',
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8'
            },
            body: jsonEncode(bodyJSON));

      if(res.statusCode == 200) {
          return jsonDecode(res.body);
      } else {
          return {"error":1};
      }  
  }


  static createGroupChat(String identity) async {

    var bodyJSON = <String, dynamic>{'identity':identity};

    final res = await http.post('$rootURL/twilioRoutes/createGroupChat',
        headers: <String, String>{
          'Content-type':'application/json; charset=UTF-8'
        },
        body: jsonEncode(bodyJSON));

    if(res.statusCode == 200) {
        return jsonDecode(res.body);
    } else {
        return {"error":1};
    }
  }

  static sendMessage(String channelID, String messageContent, String dateCreated, String from) async {

    var bodyJSON = <String, dynamic>{
        'channelID':channelID,
        'messageContent':messageContent,
        'from':from,
        'dateCreated':dateCreated
    };
    final res = await http.post('$rootURL/twilioRoutes/pushMessage',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(bodyJSON));
    if(res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      return {"error":1};
    }
  }


  static getMessages(String channelID) async {
      var bodyJSON = <String, dynamic>{
        'channelID':channelID
      };
      final res = await http.post("$rootURL/twilioRoutes/getMessages",
        headers: <String, String>{
          'Content-type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(bodyJSON)
      );
      if(res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return {"error":1};
      }

  }



  static getToken() async {
      var bodyJSON = <String, dynamic>{
        'identity' : FirebaseFunctions?.currentUID
    };

    final res = await http.post('$rootURL/twilioRoutes/getToken',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(bodyJSON));

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['token'];
    } else {
      return {"error": 1};
    }

  }






  //              returns the businesses
  static getLocations(double longitude, double latitude,
      [String term, int radius, int time]) async {
    print("Start getting data");

    var bodyJSON = <String, dynamic>{
      'longitude': longitude,
      'latitude': latitude,
    };
    if (term != null) {
      bodyJSON['term'] = term;
    }
    if (radius != null) {
      bodyJSON['radius'] = radius;
    }

    if (time!=null){
      bodyJSON['open_at']= time;
    }

    bodyJSON['sort_by'] = 'distance';

    bodyJSON['limit'] = 25;
    //  bodyJSON['limit'] = 5;

    final res = await http.post('$rootURL/yelpRoutes/nearby',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(bodyJSON));
    print("check statement 1");
    if (res.statusCode == 200) {
      print("check statement 2");


      print(res.body);

      return res.body;
    } else {
      Global.errorFindingYelpPlaces = true;
      return {"error": 1};
    }
  }
}

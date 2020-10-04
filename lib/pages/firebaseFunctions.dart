import 'package:flutter/material.dart';
import 'package:secure_random/secure_random.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:Rendezvous/backendFunctions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:Rendezvous/backendFunctions.dart';
import 'dart:io';
import 'package:Rendezvous/globalVar.dart';

import '../globalVar.dart';


class FirebaseFunctions {
  static String currentUID;
  static Map<String, dynamic> currentUserData = {
    "roomCode": null,
    "userName": null,
  };
  static Map<String, dynamic> roomData = {
    "roomCode": null,
    "host": null,
    "host UID": null,
    "Final Location": null,
    "Final Location Address": null,
    "Final LatLng": null,
    "profileImages": {},
    "userNames": {}
  };

  static refreshChatToken(String token) async {
      await Firestore.instance.collection("users").document(FirebaseFunctions?.currentUID).updateData({
          "chatToken" : token
      }).then((value) {
          FirebaseFunctions.currentUserData["chatToken"] = token;
      });
  }

  static uploadImage(String path, String fileName, File img) async {
      final StorageReference storageReference = FirebaseStorage().ref().child(path).child(fileName);
      final StorageUploadTask uploadTask = storageReference.putFile(img);
      await uploadTask.onComplete;
      // Return the image url

      String url = await storageReference.getDownloadURL();
      Global.profileImage = NetworkImage(url);
      
      return url;
    }

  static refreshFirebaseRoomData() async {
    if (FirebaseFunctions.currentUserData["roomCode"] != null) {
      await Firestore.instance
          .collection("rooms")
          .document(currentUserData["roomCode"])
          .get()
          .then((snapshot) {
        FirebaseFunctions.roomData["roomCode"] = snapshot.data["roomCode"];
        FirebaseFunctions.roomData["host"] = snapshot.data["host"];
        FirebaseFunctions.roomData["host UID"] = snapshot.data["host UID"];
        FirebaseFunctions.roomData["Final Location"] =
            snapshot.data["Final Location"];
        FirebaseFunctions.roomData["Final Location Address"] =
            snapshot.data["Final Location Address"];
        FirebaseFunctions.roomData["Final LatLng"] = snapshot.data["Final LatLng"];
        FirebaseFunctions.roomData["groupChatID"] = snapshot.data["groupChatID"];
      });

      await Firestore.instance.collection("rooms")
          .document(currentUserData["roomCode"]).collection('users').getDocuments().then((v) {
               var names = {};
               var imagesURL = {};
              for(var doc in v.documents) {
                  names[doc.documentID] = doc.data["userName"];
                  var imageURL = doc.data["profileImage"];
                  if (imageURL!= null) {   
                      imagesURL[doc.documentID] = NetworkImage(imageURL);     
                  }
              }
              FirebaseFunctions.roomData["userNames"] = names;
              FirebaseFunctions.roomData["profileImages"] = imagesURL;
          });
    }
  }

  static pushUserLocation(double latitude, double longitude) {
    GeoPoint point = GeoPoint(latitude, longitude);

    Firestore.instance
        .collection("rooms")
        .document(FirebaseFunctions.currentUserData["roomCode"])
        .collection("users")
        .document(FirebaseFunctions?.currentUID)
        .updateData({
      "location": point,
    }).catchError((e) {
      print(e.toString());
      return false;
    }).then((value) {
      return true;
    });
  }

  static refreshFirebaseUserData() async {
    await Firestore.instance
        .collection("users")
        .document(FirebaseFunctions?.currentUID)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        FirebaseFunctions.currentUserData = snapshot.data;
        if(snapshot.data["profileImage"] != null) {
            Global.profileImage = NetworkImage(snapshot.data["profileImage"]);
        }
      } else {
        Firestore.instance
            .collection("users")
            .document(FirebaseFunctions?.currentUID)
            .setData({
          "userName": null,
          "userID": FirebaseFunctions?.currentUID
        }).then((value) {
          FirebaseFunctions.currentUserData = {
            "userName": null,
            "userID": FirebaseFunctions?.currentUID
          };
        });
      }
    });
  }

  static checkExist(String roomName) async {
    bool exists = false;
    try {
      await Firestore.instance.document("rooms/$roomName").get().then((doc) {
        if (doc.exists)
          exists = true;
        else
          exists = false;
      });
      return exists;
    } catch (e) {
      return false;
    }
  }

  static addCurrentUserToRoom(String roomCode, {bool callBackend=true, String memberCode=""}) async {
    // might want to check if room exists here?
    String userName = FirebaseFunctions.currentUserData["userName"];
    var roomData = {
      "userID": FirebaseFunctions.currentUserData["userID"],
      "userName": userName,
    };

    Global.userName = userName;

    String memberID = memberCode;
    var userData = {"roomCode": roomCode, "memberID": memberID, "userName": userName};
    FirebaseFunctions.currentUserData["memberID"] = memberID;
    if(Global.updateProfileImage) {
        String imageID = await FirebaseFunctions.uploadImage("profileImages", FirebaseFunctions.currentUserData["userID"], Global.profileImage);
        Global.updateProfileImage = false;
        Global.profileImage = NetworkImage(imageID);
        roomData["profileImage"] = imageID;
        userData["profileImage"] = imageID;
        FirebaseFunctions.currentUserData["profileImage"] = imageID;
    }

    if(FirebaseFunctions.currentUserData["profileImage"] != null) {
        roomData["profileImage"] = FirebaseFunctions.currentUserData["profileImage"];
    }


    bool isValid = await FirebaseFunctions.checkExist(roomCode);
    if (!isValid) {
      return isValid;
    }


    await Firestore.instance
        .collection("rooms")
        .document(roomCode)
        .collection("users")
        .document(FirebaseFunctions?.currentUID)
        .setData(roomData).then((value) async {
      FirebaseFunctions.currentUserData["roomCode"] = roomCode;
      //this line gets the host when the user joins the room
      await Firestore.instance
          .collection("rooms")
          .document(roomCode)
          .get()
          .then((value) async {


            if(callBackend) {
                var memberData = await BackendMethods.joinGroupChat(FirebaseFunctions?.currentUID, value.data["groupChatID"]);
                memberID = memberData["sid"];
                userData["memberID"] = memberID;
            }

            FirebaseFunctions.currentUserData["memberID"] = memberID;
            roomData["host"] = value.data["host"];
            roomData["host UID"] = value.data["host UID"];
            roomData["Final Location"] = value.data["Final Location"];
            roomData["Final Location Address"] = value.data["Final Location Address"];
            roomData["Final LatLng"] = value.data["Final LatLng"];
      });
      await Firestore.instance
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .updateData(userData).then((result) {
        return true;
      });
    }).catchError((err) {
      return false;
    });
    return true;
  }

  static deleteRoom(String roomCode) async {
    await Firestore.instance.collection("rooms").document(roomCode).delete();
  }

  static removeCurrentUserFromRoom(String roomCode, int membersLength, {memberID="", groupChatID=""}) async {
    if(BackendMethods.socket != null) {
      BackendMethods.disconnectSocket();
    }
    await BackendMethods.leaveRoom(groupChatID, memberID, membersLength);

    await Firestore.instance
        .collection("users")
        .document(FirebaseFunctions.currentUID)
        .updateData({"roomCode": null}).then((result) async {
      await Firestore.instance
          .collection("rooms")
          .document(roomCode)
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .delete()
          .then((value) {});
      //If there is more than 1 person in the room, we will change the host to the next user in the room
      if (membersLength > 1) {
        await changeHost();
      }
      FirebaseFunctions.roomData = {
        "roomCode": null,
        "host": null,
        "host UID": null,
        "Final Location": null,
        "Final Location Address": null,
        "Final LatLng": null
      };
      FirebaseFunctions.currentUserData["roomCode"] = null;
      FirebaseFunctions.currentUserData["chatToken"] = null;
      FirebaseFunctions.currentUserData["memberID"] = null;
      //If there is only 1 person in the room, we will delete the room
      if (membersLength == 1) {
        await deleteRoom(roomCode);
        return;
      }

  });

  }

  //This function changes the host of the room for when someone leaves the room
  static changeHost() async {
    //If the user isn't the host, we don't need to worry about changing the host
    if (roomData["host"] != currentUserData["userName"]) {
      return;
    }
    await Firestore.instance
        .collection("rooms")
        .document(roomData["roomCode"])
        .collection("users")
        .getDocuments()
        .then((value) {
      var userDocs = value.documents;
      roomData["host"] = userDocs[0].data["userName"];
      roomData["host UID"] = userDocs[0].documentID;
    });
    //Might have to change this line in case a different host shows up for everyone
    await Firestore.instance
        .collection("rooms")
        .document(roomData["roomCode"])
        .updateData({"host": roomData["host"], "host UID": roomData["host UID"]});
  }

  static createFirebaseRoom(String userName) async {
    bool invalidCode = true;
    String roomCode;

    // in the event that the code is already in use
    while (invalidCode) {
      var roomCodeSecureRandom = SecureRandom();
      roomCode = roomCodeSecureRandom.nextString(
          length: 5, charset: 'abcdefghijklmnopqrstuvwxyz');
      await Firestore.instance
          .collection("rooms")
          .document(roomCode)
          .get()
          .then((value) {
        if (!value.exists) {
          invalidCode = false;
        }
      });
    }

    FirebaseFunctions.currentUserData["userName"] = userName;
    FirebaseFunctions.roomData = {"roomCode": roomCode};
    //Setting the host variable for the current user to true
    FirebaseFunctions.roomData["host"] = userName;
    //Adding the host UID to keep track of host to not prevent conflicts in names
    FirebaseFunctions.roomData["host UID"] = currentUID;
    // stores the room to database

    var groupChatData = await BackendMethods.createGroupChat(FirebaseFunctions?.currentUID);
    String groupChatID = groupChatData['groupChat']['sid'];
    String memberID = groupChatData['host']['sid'];

    FirebaseFunctions.roomData["groupChatID"] = groupChatID;

    await Firestore.instance
        .collection("rooms")
        .document(roomCode)
        .setData({"roomCode": roomCode, "host": userName, "host UID": currentUID, "groupChatID": groupChatID}).then((value) async {
      await Firestore.instance
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .updateData({"userName": userName, "roomCode": roomCode, "memberID": memberID}).then(
              (value) async {
        await FirebaseFunctions.addCurrentUserToRoom(roomCode, callBackend: false, memberCode: memberID);
        return roomCode;
      }).catchError((e) {
        print(e.toString());
        return null;
      });
    });
  }

  //Creating a function that will set the final position
  static void setFinalPosition(
      String finalLocName, String finalLocAddress, LatLng finalLatLng) async {
    //In this function, I want to push the finalLocName and finalLocAddress to firebase
    await Firestore.instance
        .collection("rooms")
        .document(FirebaseFunctions.roomData["roomCode"])
        .updateData({
      "Final Location": finalLocName,
      "Final Location Address": finalLocAddress,
      "Final LatLng": GeoPoint(finalLatLng.latitude, finalLatLng.longitude)
    });
    FirebaseFunctions.roomData["Final Location"] = finalLocName;
    FirebaseFunctions.roomData["Final Location Address"] = finalLocAddress;
    FirebaseFunctions.roomData["Final LatLng"]= GeoPoint(finalLatLng.latitude, finalLatLng.longitude);
  }
}

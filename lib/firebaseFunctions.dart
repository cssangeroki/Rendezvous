import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:secure_random/secure_random.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFunctions {

  static String currentUID;
  static Map<String, dynamic> currentUserData = {"roomCode" : null, "userName":null};
  static Map<String, dynamic> roomData = {"roomCode":null};

  static refreshFirebaseRoomData() async {
      // StreamSubscription<QuerySnapshot> realtimeListener;
      // realtimeListener = Firestore.instance.collection("rooms").document(currentUserData["roomData"]).collection("users").where(true).snapshots().listen((event) {
      //    realtimeListener.cancel(); 
      // });
      if(FirebaseFunctions.currentUserData["roomCode"] != null) {
          await Firestore.instance.collection("rooms").document(currentUserData["roomCode"]).get().then((snapshot) {
              FirebaseFunctions.roomData = snapshot.data;
          });
      }
  }

  static refreshFirebaseUserData() async {
      await Firestore.instance.collection("users").document(FirebaseFunctions?.currentUID).get().then((snapshot) {
          if(snapshot.exists) {
            FirebaseFunctions.currentUserData = snapshot.data;
          } else {
            Firestore.instance.collection("users").document(FirebaseFunctions?.currentUID).setData({"userName":null, "userID":FirebaseFunctions?.currentUID}).then((value) {
                FirebaseFunctions.currentUserData = {"userName":null, "userID":FirebaseFunctions?.currentUID};
            });
          }
      });
  }

  static addCurrentUserToRoom(String roomCode) async {
      /// might want to check if room exists here?
      await Firestore.instance.collection("rooms").document(roomCode)
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .setData({"userID":FirebaseFunctions?.currentUID}).then((value) {
                FirebaseFunctions.currentUserData["roomCode"] = roomCode;
                Firestore.instance.collection("users").document(FirebaseFunctions?.currentUID).updateData({"roomCode":roomCode}).then((result) {
                });
          });
  }


  static removeCurrentUserFromRoom(String roomCode) async {
    Firestore.instance.collection("users").document(FirebaseFunctions.currentUID).updateData({"roomCode":null}).then((result) {
        Firestore.instance.collection("rooms").document(roomCode).collection("users").document(FirebaseFunctions?.currentUID).delete().then((value) {
            FirebaseFunctions.roomData = {"roomCode":null};
            FirebaseFunctions.currentUserData = {"roomCode" : null};
            
        });
    });
  }

  static createFirebaseRoom(String userName) async {

    bool invalidCode = true;
    String roomCode;

    // in the event that the code is already in use
    while(invalidCode) {
        var roomCodeSecureRandom = SecureRandom();
        roomCode = roomCodeSecureRandom.nextString(
          length: 5, charset: 'abcdefghijklmnopqrstuvwxyz');
        await Firestore.instance.collection("rooms").document(roomCode).get().then((value) {
              if(!value.exists) {
                invalidCode = false;
              }
        });
    }

    FirebaseFunctions.roomData = {"roomCode":roomCode};
    // stores the room to database
    Firestore.instance.collection("rooms").document(roomCode).setData({"roomCode":roomCode}).then((value) {
          Firestore.instance.collection("users").document(FirebaseFunctions?.currentUID).updateData({"userName": userName, "roomCode":roomCode}).then((value) {
              FirebaseFunctions.addCurrentUserToRoom(roomCode);
          }).catchError((e){
                print(e.toString());
                return null;
          });
    });
  }
}
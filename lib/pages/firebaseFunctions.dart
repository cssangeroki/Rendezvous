import 'package:firebase_auth/firebase_auth.dart';
import 'package:secure_random/secure_random.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFunctions {
  static String currentUID;
  static Map<String, dynamic> currentUserData = {
    "roomID": null,
    "userName": null
  };
  static Map<String, dynamic> roomData = {"roomCode": null, "roomID": null};

  static refreshFirebaseRoomData() async {
    if (FirebaseFunctions.currentUserData["roomID"] != null) {
      Firestore.instance
          .collection("rooms")
          .document(currentUserData["roomID"])
          .get()
          .then((snapshot) {
        print("Okay");
        FirebaseFunctions.roomData = snapshot.data;
      });
    }
  }

  static refreshFirebaseUserData() async {
    Firestore.instance
        .collection("users")
        .document(FirebaseFunctions?.currentUID)
        .get()
        .then((snapshot) {
      print(snapshot.exists);
      if (snapshot.exists) {
        FirebaseFunctions.currentUserData = snapshot.data;
      } else {
        Firestore.instance
            .collection("users")
            .add({"userName": null}).then((value) {
          Firestore.instance
              .collection("users")
              .document(value.documentID)
              .updateData({"userID": value.documentID});
        });
      }
    });
  }

  static createFirebaseRoom(String userName) async {
    var roomCodeSecureRandom = SecureRandom();
    String roomCode = roomCodeSecureRandom.nextString(
        length: 5, charset: 'abcdefghijklmnopqrstuvwxyz');

    Firestore.instance.collection("rooms").add({
      "host": FirebaseFunctions?.currentUID,
      "roomCode": roomCode
    }).then((value) {
      String roomID = value.documentID;

      Firestore.instance
          .collection("rooms")
          .document(roomID)
          .updateData({"roomID": roomID});

      Firestore.instance
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .updateData({
        "userName": userName,
        "roomID": roomID,
        "roomCode": roomCode
      }).then((value) {
        return roomCode;
      }).catchError((e) {
        print(e.toString());
        return null;
      });
    });
  }
}

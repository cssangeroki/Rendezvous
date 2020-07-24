import 'package:secure_random/secure_random.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFunctions {
  static String currentUID;
  static Map<String, dynamic> currentUserData = {
    "roomCode": null,
    "userName": null
  };
  static Map<String, dynamic> roomData = {"roomCode": null};

  static refreshFirebaseRoomData() async {
    if (FirebaseFunctions.currentUserData["roomCode"] != null) {
      await Firestore.instance
          .collection("rooms")
          .document(currentUserData["roomCode"])
          .get()
          .then((snapshot) {
        FirebaseFunctions.roomData = snapshot.data;
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

  static addCurrentUserToRoom(String roomCode) async {
    // might want to check if room exists here?
    bool isValid = await FirebaseFunctions.checkExist(roomCode);
    if (!isValid) {
      return isValid;
    }

    await Firestore.instance
        .collection("rooms")
        .document(roomCode)
        .collection("users")
        .document(FirebaseFunctions?.currentUID)
        .setData({
      "userID": FirebaseFunctions?.currentUID,
      "userName": FirebaseFunctions.currentUserData["userName"]
    }).then((value) {
      FirebaseFunctions.currentUserData["roomCode"] = roomCode;
      Firestore.instance
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .updateData({"roomCode": roomCode}).then((result) {
        return true;
      });
    }).catchError((err) {
      return false;
    });

    return true;
  }

  static removeCurrentUserFromRoom(String roomCode) async {
    Firestore.instance
        .collection("users")
        .document(FirebaseFunctions.currentUID)
        .updateData({"roomCode": null}).then((result) {
      Firestore.instance
          .collection("rooms")
          .document(roomCode)
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .delete()
          .then((value) {
        FirebaseFunctions.roomData = {"roomCode": null};
        FirebaseFunctions.currentUserData = {"roomCode": null};
      });
    });
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
    // stores the room to database
    await Firestore.instance
        .collection("rooms")
        .document(roomCode)
        .setData({"roomCode": roomCode}).then((value) async {
      await Firestore.instance
          .collection("users")
          .document(FirebaseFunctions?.currentUID)
          .updateData({"userName": userName, "roomCode": roomCode}).then(
              (value) async {
        await FirebaseFunctions.addCurrentUserToRoom(roomCode);
        return roomCode;
      }).catchError((e) {
        print(e.toString());
        return null;
      });
    });
  }
}

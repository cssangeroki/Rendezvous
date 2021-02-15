//This page will be used to display message notifications in the background
//com.example.flutter_complete_guide

import 'package:Rendezvous/pages/mapRenderPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
//import 'package:async/async.dart';
//import 'dart:io';

//Needed for notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
  print("received background message");
  if (message.data != null) {
    // Handle data message
    final dynamic data = message.data;
    print(data.toString());
  }

  if (message.notification != null) {
    // Handle notification message
    final RemoteNotification notification = message.notification;
    print(notification.toString());
    //showNotification(notification.body, 0);
  }

  // Or do other work.
}

class Notifications{
  static final AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('rendezvous_icon');
  static IOSInitializationSettings initializationSettingsIOS;
  static final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS);
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
      'your channel id', 'your channel name', 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      channelShowBadge: true,
  );
  static const IOSNotificationDetails iosPlatformChannelSpecifics = IOSNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, subtitle: "New Messages");
  static const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosPlatformChannelSpecifics);
  bool result = false;

  FlutterLocalNotificationsPlugin notify;

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  //Constructor
  Notifications(){
    print("Entered notifications constructor");
    this.initializeNotificationSettings();
    this.initializeFirebaseMessaging();
  }

  void initializeNotificationSettings() async {
    initializationSettingsIOS = IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);
    result = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    notify = new FlutterLocalNotificationsPlugin();
    notify.initialize(initializationSettings);
  }

  void initializeFirebaseMessaging() async {
    print("Entered initializeFirebaseMessaging");

    //await Firebase.initializeApp();

    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
          print("Received some message");
           try {
             if (message != null) {
               print("received Message");
               showNotification(message.toString(), 0);
             }
           }catch(e){
             print("Error receiving message");
             print(e);
           }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Entered onMessage()");
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;

      if (notification != null && android != null) {
        showNotification(notification.body, 0);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      selectNotification("new notification");
    });
  }

  //This function will be used to show the notification
  Future<void> showNotification(String message, int id) async{
    if (message == null) return;
    await notify.show(id, 'Rendezvous',
        message,
        platformChannelSpecifics);
    return;
  }


  Future<void> selectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
    BuildContext context;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => MapRender()),
    );
  }

  void displayNotification() async{
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', 'plain body', platformChannelSpecifics,
        payload: 'item x');
  }


  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    BuildContext context;
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapRender(),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
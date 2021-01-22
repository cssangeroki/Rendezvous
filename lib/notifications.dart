//This page will be used to display message notifications in the background

import 'package:Rendezvous/pages/mapRenderPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
//import 'package:async/async.dart';
//import 'dart:io';

//Needed for notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
      showWhen: false);
  static const IOSNotificationDetails iosPlatformChannelSpecifics = IOSNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, subtitle: "New Messages");
  static const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosPlatformChannelSpecifics);
  bool result = false;

  FlutterLocalNotificationsPlugin notify;
  Notifications(){
    this.initializeNotificationSettings();
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

  Future selectNotification(String payload) async {
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

  //This function will be used to show the notification
  Future showNotification(String message) async{
    await notify.show(0, 'Rendezvous',
        message,
        platformChannelSpecifics, payload: 'Default_Sound');
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
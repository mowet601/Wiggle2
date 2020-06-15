import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:Wiggle2/games/smashbros/smash_engine/screen_util.dart';
import 'package:Wiggle2/screens/anonymous/anonprofile.dart';
import 'package:Wiggle2/screens/anonymous/anonymousChatScreen.dart';
import 'package:Wiggle2/screens/anonymous/anonymousGames.dart';
import 'package:Wiggle2/screens/home/gameslist.dart';
import 'package:Wiggle2/screens/home/notificationsPage.dart';
import 'package:Wiggle2/screens/home/profile.dart';
import 'package:Wiggle2/screens/home/chatScreen.dart';
import 'package:Wiggle2/screens/authenticate/intro/introPage1.dart';
import 'package:Wiggle2/shared/constants.dart';
import 'package:Wiggle2/shared/loading.dart';
import '../../models/user.dart';
import '../../models/wiggle.dart';
import 'package:provider/provider.dart';
import 'package:Wiggle2/services/database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'dart:io';
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static bool anonymous = false;

  int _currentIndex = 1;

  final GlobalKey<ScaffoldState> _scaffoldkey = GlobalKey<ScaffoldState>();
  final tabs = [
    Gameslist(),
    ChatScreen(),
    NotificationPage(),
    Myprofile(),
  ];
  final anonymoustabs = [
    AnonymousGames(),
    AnonymousChatScreen(),
    NotificationPage(),
    Myanonprofile(),
  ];

  final Firestore _db = Firestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging();

  _saveDeviceToken() async {
      String fcmToken = await _fcm.getToken();
      
        if(Platform.operatingSystem == 'android'){
        await Firestore.instance
            .collection('users')
            .document(Constants.myEmail)
            .collection('tokens')
            .document(Constants.myEmail).setData({
          'token': fcmToken,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': Platform.operatingSystem
        });
        } else if(Platform.operatingSystem == 'ios'){
          print('hehe ios'+fcmToken);
          //becuase tokens is only used for push notification, it cant be used for 
          //ios, hence theres always error with this, can be seen when u close app without loggin out,
          //and then going back to the app again
        }
    }

  createAlertDialog() {
    final user = Provider.of<User>(context);
    final wiggles = Provider.of<List<Wiggle>>(context) ?? [];
    return showDialog(
        context: context,
        builder: (context) {
          return StreamBuilder<UserData>(
              stream: DatabaseService(uid: user.uid).userData,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  UserData userData = snapshot.data;
                  if (userData != null) {
                    return AlertDialog(
                      title: Text('Meet a Friend'),
                      content: const Text('Who will you meet today?'),
                      actions: <Widget>[
                        FlatButton(
                          child: Text('Leggoooo'),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => IntroPage1(
                                    userData: userData, wiggles: wiggles),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                } else {
                  Loading();
                }
              });
        });
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  AndroidInitializationSettings androidInitializationSettings;
  IOSInitializationSettings iosInitializationSettings;
  InitializationSettings initializationSettings;

  void initializing() async {
    androidInitializationSettings =
        AndroidInitializationSettings('mipmap/ic_launcher');
    iosInitializationSettings = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    initializationSettings = InitializationSettings(
        androidInitializationSettings, iosInitializationSettings);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  void _showNotifications() async {
    await notification();
  }

  void _showNotificationsAfterSecond() async {
    await notificationAfterSec();
  }

  Future<void> notification() async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'Channel ID', 'Channel title', 'channel body',
            priority: Priority.High,
            importance: Importance.Max,
            ticker: 'test');

    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();

    NotificationDetails notificationDetails =
        NotificationDetails(androidNotificationDetails, iosNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
        0, 'Hello there', 'please subscribe my channel', notificationDetails);
    createAlertDialog();
  }

  Future<void> notificationAfterSec() async {
    // var timeDelayed = DateTime.now().add(Duration(seconds: 5));
    var time = new Time(21, 30, 0);
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
            'second channel ID', 'second Channel title', 'second channel body',
            priority: Priority.High,
            importance: Importance.Max,
            ticker: 'test');

    IOSNotificationDetails iosNotificationDetails = IOSNotificationDetails();

    NotificationDetails notificationDetails =
        NotificationDetails(androidNotificationDetails, iosNotificationDetails);
    // await flutterLocalNotificationsPlugin.schedule(1, 'Hello there',
    //     'please subscribe my channel', timeDelayed, notificationDetails);
    await flutterLocalNotificationsPlugin.showDailyAtTime(
        1, "Hello Mag", "yozza", time, notificationDetails);
  }

  Future onSelectNotification(String payLoad) {
    if (payLoad != null) {
      print(payLoad);
      createAlertDialog();
    }
    // we can set navigator to navigate another screen
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(body),
      actions: <Widget>[
        CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              print("");
            },
            child: Text("Okay")),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _saveDeviceToken();
    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        showSnackBar() {
          final snackBar = SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(message['notification']['body']),
            action: SnackBarAction(
              label: message['notification']['body'],
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(),
                ),
              ),
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          );

          _scaffoldkey.currentState.showSnackBar(snackBar);
        }

        showSnackBar();
        print('onMessage: $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('onResume: $message');
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Gameslist()));
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('onLaunch: $message');
      },
    );
    _fcm.requestNotificationPermissions(const IosNotificationSettings(sound: true,badge:true,alert:true));
    initializing();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    ScreenUtil.setScreenOrientation('portrait');
    //this StreamProvider provides the list of user for WiggleList();
    return anonymous
        ? Scaffold(
            key: _scaffoldkey,
            body: anonymoustabs[_currentIndex],
            //floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
            floatingActionButton: SpeedDial(
              backgroundColor: Colors.grey,
              animatedIcon: AnimatedIcons.menu_close,
              overlayOpacity: 0,
              children: [
                SpeedDialChild(
                  child: Icon(Icons.find_in_page),
                  backgroundColor: Colors.grey,
                  elevation: 10.0,
                  onTap: _showNotificationsAfterSecond,
                ),
                SpeedDialChild(
                  child: Icon(Icons.portrait),
                  backgroundColor: Colors.blueGrey,
                  elevation: 10.0,
                  onTap: () {
                    DatabaseService(uid: user.uid).updateAnonymous(false);
                    setState(() {
                      anonymous = false;
                    });
                  },
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.games),
                  title: Text('Games'),
                  backgroundColor: Colors.grey,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  title: Text('Chats'),
                  backgroundColor: Colors.grey,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.new_releases),
                  title: Text('Notification'),
                  backgroundColor: Colors.grey,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle),
                  title: Text('Unknown Profile'),
                  backgroundColor: Colors.grey,
                ),
              ],
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: Colors.black,
            ),
          )
        : Scaffold(
            key: _scaffoldkey,
            body: tabs[_currentIndex],
            floatingActionButton: SpeedDial(
              animatedIcon: AnimatedIcons.menu_close,
              backgroundColor: Colors.blueGrey,
              overlayOpacity: 0,
              children: [
                SpeedDialChild(
                  child: Icon(Icons.find_in_page),
                  backgroundColor: Colors.blueGrey,
                  elevation: 10.0,
                  onTap: _showNotifications,
                ),
                SpeedDialChild(
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: Image.asset('assets/images/ghost.png',
                          fit: BoxFit.fill),
                    ),
                  ),
                  backgroundColor: Colors.grey,
                  elevation: 10.0,
                  onTap: () {
                    DatabaseService(uid: user.uid).updateAnonymous(true);
                    setState(() {
                      anonymous = true;
                    });
                  },
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.games),
                  title: Text('Games'),
                  backgroundColor: Colors.blueGrey,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  title: Text('Chats'),
                  backgroundColor: Colors.blueGrey,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.new_releases),
                  title: Text('Notification'),
                  backgroundColor: Colors.blueGrey,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.portrait),
                  title: Text('Profile'),
                  backgroundColor: Colors.blueGrey,
                ),
              ],
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: Colors.black,
            ),
          );
  }
}



import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task1/App%20screen/auth_user.dart';
import 'App screen/Add_company.dart';
import 'App screen/Book_Create.dart';
import 'App screen/Homescreen.dart';
import 'App screen/Login.dart';
import 'App screen/Register_page.dart';
import 'App screen/company_auth.dart';
import 'App screen/forget_password.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('backgroung');
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('notificationTitle', message.notification?.title ?? "No Title");
  await prefs.setString('notificationBody', message.notification?.body ?? "No Body");
  print('background ended');
}

void main() async {

  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FlutterNativeSplash.remove();
  runApp(const MyApp());

}




class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo', theme: ThemeData(primaryColor: Colors.white,),
      home:  Auth_User(),
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/home': (context) =>  HomeScreen(),
        '/reg': (context) =>  RegisterScreen(),
        '/forgot_pass': (context) =>  forget_pass(),
        '/add_company': (context) =>  Add_Company(),
        // '/demo': (context) =>  demo_db(),
        '/bookcreate': (context) =>  Book_create(),
        '/main_home': (context) => main_interface(),
        '/auth_company': (context) => CompanyAuth(),
        '/user_auth': (context) => Auth_User(),
        // '/view_report': (context) => View_Report(),
        // '/': (context) =>  Book_create(),

      },
    );
  }
}


// Expanded(
// child: TabBarView(children: [
// Container(color: Colors.blueGrey[100], child: Line_chart(lineSpots, minY, midY, maxY, uniqueYValues)),
// Container(color: Colors.blueGrey[100], child: Bar_chart(barGroups, minY, maxY)),
// Container(color: Colors.blueGrey[100], child: Pie_chart(totalInPositive.toDouble(), totalInNegative.toDouble())),
// ]),
// ),
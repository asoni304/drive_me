import 'package:drive_me/screens/login_screen.dart';
import 'package:drive_me/screens/register_screen.dart';
import 'package:drive_me/screens/search_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data_handler/app_data.dart';
import 'screens/main_screen.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
DatabaseReference usersRef = FirebaseDatabase.instance.ref().child('users');

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context)=>AppData(),
      child: MaterialApp(
   debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Brand Bold',
          primarySwatch: Colors.green,
        ),
        initialRoute: LoginScreen.idScreen,
        routes: {
          RegisterScreen.idScreen:(context)=>RegisterScreen(),
          MainScreen.idScreen:(context)=>MainScreen(),
          LoginScreen.idScreen:(context)=>LoginScreen(),
          SearchScreen.idScreen:(context)=>SearchScreen(),
        },
      ),
    );
  }
}


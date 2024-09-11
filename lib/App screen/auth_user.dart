import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task1/App%20screen/Login.dart';

import 'company_auth.dart';

class Auth_User extends StatelessWidget {
  const Auth_User({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder:(context,snapshot){
            if(snapshot.hasData){
              return CompanyAuth();
            }
            // else if(snapshot.hasError){
            //   print('errrrrrrrrrrrrrrrrror: $snapshot.hashCode');
            //   return RegisterScreen();
            // }
            else{
              return LoginScreen();
            }
          },
      ),
    );
  }
}

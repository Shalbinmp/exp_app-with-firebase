import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media_sign_in_buttons/social_media_sign_in_buttons.dart';
// import 'package:google_sign_in/google_sign_in.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {


  final CollectionReference user_details = FirebaseFirestore.instance.collection('Users');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  var items = [
    '+91',
    '+101',
    'Item 3',
    'Item 4',
    'Item 5',
  ];
  String dropdownvalue = '+91';
  var size;
  var height;
  var width;
  TextEditingController email =TextEditingController();
  TextEditingController phone =TextEditingController();
  TextEditingController password =TextEditingController();
  late bool _passtoggle;
  String? uname_check;
  String? phone_check;
  String? pass_check;
  var _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
      _passtoggle=true;
    get_login_data();
  }


  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return  Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(right: 10,left: 10),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: height * 0.06,),
                  Text('Welcome!',style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold)),
                  SizedBox(height: height * 0.01,),
                  Text('Login to auto backup your data securely'),
                  SizedBox(height: height * 0.05,),
                  TextFormField(
                    controller: email,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter your Email',
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Enter your Email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.022,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: width*0.25,
                        height: height*0.08,
                        child:
                        InputDecorator(
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton(
                              isExpanded: true,
                              // Initial Value
                              value: dropdownvalue,
                              // Down Arrow Icon
                              icon: const Icon(Icons.keyboard_arrow_down),
                              // Array list of items
                              items: items.map((String items) {
                                return DropdownMenuItem(
                                  value: items,
                                  child: Text(items),
                                );
                              }).toList(),
                              // After selecting the desired option,it will
                              // change button value to selected value
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownvalue = newValue!;
                                });
                              },
                            ),
                          ),
                        ),

                      ),
                      SizedBox(
                        width: width*0.05,
                        height: height*0.08,
                      ),
                      Expanded(
                        // width: width*0.65,
                        // height: height*0.075,
                        child: TextFormField(
                          controller: phone,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Phone Number',
                          ),
                          validator: (value){
                            if(value == null || value.isEmpty){
                              return 'Please Enter Your Number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.022,),
                  TextFormField(
                    obscureText: _passtoggle,
                    controller: password,
                    decoration:  InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter your Password',
                        suffixIcon: IconButton(onPressed: (){
                          print('shalbin');
                          if(_passtoggle==false){
                            setState(() {
                              _passtoggle=true;
                            });
                          }
                          else{
                            setState(() {
                              _passtoggle=false;
                            });
                          }
                        }, icon: Icon(Icons.remove_red_eye_rounded))
                    ),
                    validator:(value){
                      if(value == null || value.isEmpty){
                        return 'Please Enter your Password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.022,),
                  SizedBox(
                    height: height * 0.075,
                      width: width,
                      child: ElevatedButton(onPressed: () async {
                        if(_formKey.currentState!.validate()) {
                          try {
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                email: email.text,
                                password: password.text
                            );
                            Navigator.pushNamed(context, '/user_auth');
                          } on FirebaseAuthException catch (e) {
                            print('in catch');
                            if (e.code == 'user-not-found') {
                              print('No user found for that email.');

                              var snackBar = SnackBar(
                                duration: Duration(milliseconds: 1000),
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                content: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(
                                              'No user found for that email.',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    )
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  snackBar);
                            }
                            else if (e.code == 'wrong-password') {
                              print('Wrong password provided for that user.');

                              var snackBar = SnackBar(
                                duration: Duration(milliseconds: 1000),
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                content: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Text(
                                              'Wrong password provided for that user.',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    )
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  snackBar);
                            }
                            else {
                              print('An unknown error occurred.');
                              var snackBar = SnackBar(
                                duration: Duration(milliseconds: 1000),
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                content: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text(
                                            'Email or Password is Wrong.',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                  snackBar);
                            }
                          }
                        }
                      }, child: Text('LOGIN',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4), // <-- Radius
                            ),
                          ),
                      )),
                  SizedBox(height: height * 0.022,),
                  // Text.rich(
                  //   TextSpan(
                  //       text: 'By Creating an account, you agree to our ',
                  //       style: TextStyle(color: Colors.grey[800]),
                  //       children: [
                  //         TextSpan(
                  //             text: 'Term of Use',
                  //             style: TextStyle(
                  //               decoration: TextDecoration.underline,
                  //               color: Colors.grey[800],
                  //             )
                  //         ),
                  //         TextSpan(text: ' & '),
                  //         TextSpan(
                  //             text: '\nPrivacy Policy',
                  //             style: TextStyle(
                  //               color: Colors.grey[800],
                  //               decoration: TextDecoration.underline,
                  //             )
                  //         ),
                  //       ]
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () { print("I was tapped!");
                          Navigator.pushNamed(context, '/reg');},
                          child: Text("Register Now",style: TextStyle(fontSize: 15),),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/forgot_pass');
                          },
                          child: Text("Forgot Password?",style: TextStyle(fontSize: 15),),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * 0.05,),
                  Row(
                      children: [
                        SizedBox(width: 10,),
                        Expanded(
                            child: Divider(color: Colors.blueGrey[100],)
                        ),
                        SizedBox(width: 10,),
                        Text('Or you can Sign in with',style: TextStyle(color: Colors.black45,fontWeight: FontWeight.bold),),
                        SizedBox(width: 10,),
                        Expanded(
                            child: Divider(color: Colors.blueGrey[100],)
                        ),
                        SizedBox(width: 10,),
                      ]
                  ),
                  SizedBox(height: height * 0.05,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GoogleIconMiniButton(
                          iconWidth: 50,
                          iconHeight: 50,
                          style: ButtonStyle(
                            side: MaterialStatePropertyAll(
                              BorderSide(
                                color: Colors.white,
                                width: 0,
                              ),
                            ),
                            minimumSize: MaterialStatePropertyAll(Size(0, 0)),
                            backgroundColor: MaterialStatePropertyAll(Colors.white),
                            padding: MaterialStatePropertyAll(EdgeInsets.all(0)),
                            shape: MaterialStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            fixedSize: MaterialStatePropertyAll(Size(80, 80)),
                          ),
                          onPressed: () async   {
                            try{
                              // GoogleAuthProvider _googleauthprovider = GoogleAuthProvider();
                              // UserCredential userCredential = await _auth.signInWithProvider(_googleauthprovider);
                              // await userCredential.user!.sendEmailVerification();
                              // Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

                              User? currUser = SignWithGoogle().user;

                              final data = {  'uname': currUser!.email,'photo':currUser.photoURL,};
                              user_details.doc(currUser!.uid).set(data);

                            }
                            catch(e){
                              print(e);
                            }
                          },
                        ),

                        FacebookIconMiniButton(
                          iconWidth: 50,
                          iconHeight: 50,
                          style:ButtonStyle(
                            side: MaterialStatePropertyAll(
                              BorderSide(
                                color: Colors.white,
                                width: 0,
                              ),
                            ),
                            minimumSize: MaterialStatePropertyAll(Size(0, 0)),
                            backgroundColor: MaterialStatePropertyAll(Colors.white),
                            padding: MaterialStatePropertyAll(EdgeInsets.all(0)),
                            shape: MaterialStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                            ),
                            fixedSize: MaterialStatePropertyAll(Size(80, 80)),
                          ),
                          onPressed: (){
                            try{
                              // FacebookAuthProvider _googleauthprovider = FacebookAuthProvider();
                              // _auth.signInWithProvider(_googleauthprovider);
                              // Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                              // SignWithFacebook();
                            }
                            catch(e){

                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

//   SignWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//
//       final GoogleSignInAuthentication? googleAuth = await googleUser
//           ?.authentication;
//
//       final credential = GoogleAuthProvider.credential(
//           accessToken: googleAuth?.accessToken,
//           idToken: googleAuth?.idToken
//       );
//       // User? currUser = credential.currentUser;
//       // final data = {  'uname': googleUser!.email,'photo': googleUser.photoUrl,};
//       // user_details.doc(currUser!.uid).set(data);
//       return await FirebaseAuth.instance.signInWithCredential(credential);
//
//     }
//     catch(e){
//       print(e);
//     }
// }
  SignWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Check if googleUser is null
      if (googleUser == null) {
        print("Sign in aborted by user");
        return;
      }

      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;

      // Check if googleAuth is null
      if (googleAuth == null) {
        print("Google authentication failed");
        return;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // User? currUser = _auth.currentUser;
      //
      // // Check if currUser is null
      // if (currUser == null) {
      //   print("No user currently signed in");
      //   return;
      // }
      //
      // final data = {
      //   'uname': googleUser.email,
      //   'photo': googleUser.photoUrl,
      // };
      //
      // await user_details.doc(currUser.uid).set(data);

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print(e);
    }
  }


  // SignWithFacebook() async {
  //   final FacebookSignAccount? facebookUser = await FacebookSignIn().signIn();
  //
  //   final FacebookSignInAuthentication? facebookAuth = await facebookUser?.authentication;
  //
  //   final credential = FacebookAuthProvider.credential(
  //       accessToken: facebookAuth?.accessToken,
  //       idToken: facebookAuth?.idToken
  //   );

  //   return await FirebaseAuth.instance.signInWithCredential(credential);
  // }


  get_login_data() async{
    final SharedPreferences prefs = await SharedPreferences.getInstance();
     uname_check = prefs.getString('uname');
     phone_check = prefs.getString('phone');
     pass_check = prefs.getString('pass');
     print('sdfffffff $uname_check');

  }
}

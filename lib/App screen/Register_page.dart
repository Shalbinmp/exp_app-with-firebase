
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
  TextEditingController cpassword =TextEditingController();
  late bool _pass2toggle;
  late bool _passtoggle;
  var _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
      _pass2toggle = true;
      _passtoggle = true;

  }



  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return  Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios)),),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: height * 0.050,),
                Text('Register Your Acc',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
                SizedBox(height: height * 0.05,),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter your Email',
                  ),
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter Your Email';
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
                      height: height*0.08,),
                    Expanded(

                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        controller: phone,
                        decoration:  InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Phone Number',
                        ),
                        validator: (value){
                          if(value == null || value.isEmpty){
                            return 'Please Enter Your Phone Number';
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
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter Your Password';
                    }
                    return null;
                  },
                ),

                SizedBox(height: height * 0.022,),
                TextFormField(
                  obscureText: _pass2toggle,
                  controller: cpassword,
                  decoration:  InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Confirm your Password',
                      suffixIcon: IconButton(onPressed: (){
                        print('shalbin');
                        if(_pass2toggle==false){
                          setState(() {
                            _pass2toggle=true;
                          });
                        }
                        else{
                          setState(() {
                            _pass2toggle=false;
                          });
                        }
                      }, icon: Icon(Icons.remove_red_eye_rounded))
                  ),
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter Your Confirm Password';
                    }
                    else if(value != password.text.trim()){
                      return 'same your pass and confirm pass';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.022,),
                SizedBox(
                    height: height * 0.075,
                    width: width,
                    child: ElevatedButton(onPressed: () async{
                      if(_formKey.currentState!.validate()){
                      //   print('username: $uname  \nphone: $phonenum   \npassword: $pass   \nC password: $cpass');
                      //   Reg_acc();
                        if(password.text == cpassword.text){
                        try {
                           await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: email.text,
                            password: password.text,
                          );
                           add_user(email.text,password.text,int.parse(phone.text));
                           Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'weak-password') {
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
                                            'The password provided is too weak.',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  )
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            print('The password provided is too weak.');
                          } else if (e.code == 'email-already-in-use') {

                            var snackBar = SnackBar(
                              duration:  Duration(milliseconds: 1000),
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              content:Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text('The account already exists for that email.', style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  )
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);

                            print('The account already exists for that email.');
                          }
                        } catch (e) {
                          print(e);
                        }
                        }else{
                          var snackBar = SnackBar(
                            duration:  Duration(milliseconds: 1000),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            content:Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8.0),
                                      child: Text('Password is Missmatched', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                )
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      }
                      else{

                        var snackBar = SnackBar(
                          duration:  Duration(milliseconds: 1000),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          content:Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text('one of the field is Empty', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              )
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    }, child: Text('REGISTER',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4), // <-- Radius
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );

  }
  add_user(String uname,String pass,int phone){
    User? currUser = _auth.currentUser;
    final data = {  'uname': uname,'phone': phone,'password': pass,};
    user_details.doc(currUser!.uid).set(data);
  }



  Future Reg_acc() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('uname', email.text);
    await prefs.setString('phone', phone.text);
    await prefs.setString('pass', password.text);
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class forget_pass extends StatefulWidget {
  const forget_pass({super.key});

  @override
  State<forget_pass> createState() => _forget_passState();
}

class _forget_passState extends State<forget_pass> {
  TextEditingController email =TextEditingController();
  var size;
  var height;
  var width;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios)),
      ),
      body: Padding(
        padding: const EdgeInsets.only(right: 10,left: 10),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: height * 0.2,),
              Text('We send a link to your Email for forget your Pass'),
              SizedBox(height: height * 0.02,),
              TextFormField(
                 controller: email,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter your Email',
                ),
              ),
              SizedBox(height: height * 0.022,),

              SizedBox(
                  height: height * 0.075,
                  width: width,
                  child: ElevatedButton(onPressed: () async {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
                    }, child: Text('SEND LINK',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
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
    );
  }
}

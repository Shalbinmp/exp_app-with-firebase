import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final Future<void> Function() onBiometricAuth; // Use a Future<void> callback for biometric auth

  const LockScreen({required this.onUnlock, required this.onBiometricAuth, Key? key}) : super(key: key);

  @override
  _LockScreenState createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _correctPin ; // Replace with your desired PIN
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(fontSize: 20, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      border: Border.all(color: Color.fromRGBO(234, 239, 243, 1)),
      borderRadius: BorderRadius.circular(20),
    ),
  );

  final focusedPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(fontSize: 20, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      border: Border.all(color: Color.fromRGBO(114, 178, 238, 1)),
      borderRadius: BorderRadius.circular(8),
    ),
  );


  final submittedPinTheme =
  PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(fontSize: 20, color: Color.fromRGBO(30, 60, 87, 1), fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      color: Color.fromRGBO(234, 239, 243, 1),
      border: Border.all(color: Color.fromRGBO(114, 178, 238, 1)),
      borderRadius: BorderRadius.circular(8),
    ),
  );


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadPin().then((value) {
      print('get pass');
    });

  }

  Future<void> _loadPin() async {
    final doc = await userDetails.doc(_auth.currentUser!.uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      setState(() {
        _correctPin = data['pin'];
      });
    }
  }

  void _checkPin(pin) {
    print(_correctPin);
    if (pin == _correctPin) {
      widget.onUnlock();
    } else {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Incorrect PIN')),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter PIN or use biometric authentication',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 16),
              Form(
                key: formKey,
                  child: Column(
                children: [
                  Pinput(
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    errorBuilder: (errorText,pin){
                      return Padding(padding: EdgeInsets.symmetric(
                        vertical:10
                      ),
                        child: Center(child: Text(errorText ?? '',style: TextStyle(color: Colors.red),),),
                      );
                    },
                    validator: (s) {
                      return s == _correctPin ? null : 'Pin is incorrect';
                    },
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    showCursor: true,
                    onCompleted: (pin) {
                      _checkPin(pin);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.fingerprint, size: 40),
                    onPressed: () => widget.onBiometricAuth(),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (){
                      formKey.currentState!.validate();
                    },
                    child: Text('Unlock with PIN'),
                  ),
                ],
              )),
              // TextField(
              //   controller: _pinController,
              //   keyboardType: TextInputType.number,
              //   obscureText: true,
              //   decoration: InputDecoration(labelText: 'Enter PIN'),
              // ),

              SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}

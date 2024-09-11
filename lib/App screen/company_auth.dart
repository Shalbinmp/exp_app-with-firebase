import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:task1/App%20screen/Add_company.dart';
import 'package:task1/App%20screen/Homescreen.dart';

import 'lock_screen.dart'; // Import the lock screen

class CompanyAuth extends StatefulWidget {
  const CompanyAuth({super.key});

  @override
  _CompanyAuthState createState() => _CompanyAuthState();
}

class _CompanyAuthState extends State<CompanyAuth> {
  bool _isLocked = true; // Initially set to true to show lock screen


  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');

  @override
  void initState() {
    super.initState();

    _checkPinSet();

  }

  Future<void> _checkPinSet() async {
    final doc = await userDetails.doc(_auth.currentUser!.uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || !data.containsKey('pin')) {
      if (mounted) {
        bool? pinSet = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (context) => SetPinScreen()),
        );
        if (pinSet == true) {
          _onPinSet();
        }
      }
    }
  }

  void _onPinSet() {
    if (mounted) {
      setState(() {
        _isLocked = false; // Ensure the screen is locked after setting the PIN
      });
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock',
        options: AuthenticationOptions(
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print(e);
    }

    if (authenticated) {
      _unlock();
    }
  }

  void _unlock() {
    if (mounted) {
      setState(() {
        _isLocked = false; // Unlock and proceed to main interface
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If locked, show the lock screen
    if (_isLocked) {
      return LockScreen(
        onUnlock: _unlock,
        onBiometricAuth: _authenticate,
      );
    }

    return Scaffold(
      body: StreamBuilder(
        stream: userDetails.doc(_auth.currentUser!.uid).collection('company_details').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred, please try again later.'));
          } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return main_interface();
          } else {
            return Add_Company();
          }
        },
      ),
    );
  }
}

class SetPinScreen extends StatefulWidget {
  @override
  _SetPinScreenState createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  late bool _passtoggle;
  final TextEditingController _pinController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference userDetails =
  FirebaseFirestore.instance.collection('Users');

  Future<void> _setPin() async {
    final pin = _pinController.text;
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PIN must be at least 4 digits long')),
      );
      return;
    }
    await userDetails
        .doc(_auth.currentUser!.uid)
        .set({'pin': pin}, SetOptions(merge: true));
    if (mounted) {
      Navigator.pop(context, true); // Return true to indicate the PIN was set
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _passtoggle=true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
          title: Text('Set PIN')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                maxLength: 4,
                controller: _pinController,
                keyboardType: TextInputType.number,
            obscureText: _passtoggle,
            decoration:  InputDecoration(
              // border: OutlineInputBorder(),
              labelText: 'Set PIN',
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

                // obscureText: true,
                // decoration: InputDecoration(labelText: ),
              ),),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _setPin,
                child: Text('Set PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

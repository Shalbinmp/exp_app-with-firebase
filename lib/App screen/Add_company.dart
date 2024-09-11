import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Add_Company extends StatefulWidget {
  const Add_Company({super.key});

  @override
  State<Add_Company> createState() => _Add_CompanyState();
}

class _Add_CompanyState extends State<Add_Company> {
  final CollectionReference user_details = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var size;
  var height;
  var width;
  TextEditingController company_name = TextEditingController();
  TextEditingController website = TextEditingController();
  TextEditingController contact = TextEditingController();
  TextEditingController describe = TextEditingController();
  TextEditingController currencyController = TextEditingController();
  String CountrySelect = 'Select your country';
  String? currencyCode;
  List<String> supportedCurrencies = [];
  var _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _determinePosition().then((value) => print(value));
    _getSupportedCode();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Add Company'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: height * 0.025, width: double.infinity,),
                  TextFormField(
                    controller: company_name,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Company Name',
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Enter Your Company Name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.015, width: double.infinity,),
                  TextFormField(
                    controller: website,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Website of Company',
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Enter Your Website Url';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.015, width: double.infinity,),
                  TextFormField(
                    controller: contact,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Contact Number',
                      hintText: 'Company Contact Information',
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Enter Your Company Contact Number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.015, width: double.infinity,),
                  TextFormField(
                    maxLines: 5,
                    controller: describe,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Company Information',
                    ),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        return 'Please Enter Your Company About';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.015, width: double.infinity,),
                  GestureDetector(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                          useSafeArea: true,
                        onSelect: (Country country) {
                          setState(() {
                            CountrySelect = country.displayNameNoCountryCode;
                            currencyCode = country.countryCode;
                          });
                          updateCurrency();
                        },
                      );
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: CountrySelect,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.015, width: double.infinity,),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Currency',
                    ),
                    value: supportedCurrencies.contains(currencyCode) ? currencyCode : null,
                    items: supportedCurrencies.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        currencyCode = newValue!;
                        currencyController.text = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        add_company(company_name.text, website.text, contact.text, describe.text);
                        Navigator.popAndPushNamed(context, '/add_company');
                      }
                    },
                    child: Text('SAVE & ADD NEW', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: BorderSide(color: Colors.deepPurple),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 20,),
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        add_company(company_name.text, website.text, contact.text, describe.text);
                        Navigator.popAndPushNamed(context, '/user_auth');
                      }
                    },
                    child: Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: BorderSide(color: Colors.deepPurple),
                      ),
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void updateCurrency() {
    final Map<String, String> countryCurrencyMap = {
      'US': 'USD',
      'GB': 'GBP',
      'EU': 'EUR',
      'JP': 'JPY',
      'IN': 'INR',
    };
    currencyCode = countryCurrencyMap[currencyCode ?? 'US'] ?? 'USD';
    final format = NumberFormat.simpleCurrency(name: currencyCode);
    currencyController.text = format.currencySymbol;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    List<Placemark> newPlace = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (newPlace.isNotEmpty) {
      setState(() {
        CountrySelect = newPlace.first.country ?? 'Select your country';
        currencyCode = newPlace.first.isoCountryCode ?? 'US';
      });
      updateCurrency();
    }
    return position;
  }

  Future<void> _getSupportedCode() async {
    var response = await http.get(Uri.parse('https://v6.exchangerate-api.com/v6/98b0a93a65e8cf76ff152cab/codes'));
    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      setState(() {
        supportedCurrencies = (result['supported_codes'] as List).map((code) => code[0] as String).toList();
      });
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
  }

  add_company(c_name, website, contact, dec) async {
    User? currUser = _auth.currentUser;
    final data = {
      'company_name': c_name,
      'website': website,
      'contact': contact,
      'dec': dec,
      'country': CountrySelect,
      'currency': currencyCode,
    };
    user_details.doc(currUser!.uid).collection('company_details').add(data);
  }
}

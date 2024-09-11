import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = _firebaseAuth.currentUser!.uid;
  }

  Future<String> getCompanyId() async {
    var pref = await SharedPreferences.getInstance();
    var docId = pref.getString('docid_company');
    if (docId == null) {
      throw Exception('Company ID not found in SharedPreferences');
    }
    return docId;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        await _uploadImage(imageFile);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('user_photos').child('$userId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      await userDetails.doc(userId).update({'photo': url});
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   title: Text('Profile'),
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back),
      //     onPressed: () {
      //       Navigator.of(context).pop();
      //     },
      //   ),
      // ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: FutureBuilder<String>(
            future: getCompanyId(),
            builder: (context, companyIdSnapshot) {
              if (companyIdSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (companyIdSnapshot.hasError) {
                return Center(child: Text('Error: ${companyIdSnapshot.error}'));
              } else if (companyIdSnapshot.hasData) {
                String selectedCompanyId = companyIdSnapshot.data!;
                return StreamBuilder<DocumentSnapshot>(
                  stream: userDetails.doc(userId).snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasError) {
                      return Center(child: Text('Error: ${userSnapshot.error}'));
                    } else if (userSnapshot.hasData && userSnapshot.data != null) {
                      var userDocument = userSnapshot.data!;
                      String? photoUrl;
                      if (userDocument.exists) {
                        var data = userDocument.data() as Map<String, dynamic>;
                        if (data.containsKey('photo')) {
                          photoUrl = data['photo'] as String?;
                        }
                      }
                      return StreamBuilder<DocumentSnapshot>(
                        stream: userDetails.doc(userId).collection('company_details').doc(selectedCompanyId).snapshots(),
                        builder: (context, companySnapshot) {
                          if (companySnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (companySnapshot.hasError) {
                            return Center(child: Text('Error: ${companySnapshot.error}'));
                          } else if (companySnapshot.hasData && companySnapshot.data != null) {
                            var companyDocument = companySnapshot.data!;
                            return Container(
                              color: Colors.white,
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 80,
                                    backgroundImage: photoUrl != null
                                        ? NetworkImage(photoUrl)
                                        : AssetImage('assets/img/default_user.jpeg') as ImageProvider,
                                    child: Align(
                                      alignment: Alignment.bottomRight,
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.green,
                                          radius: 18,
                                          child: Icon(Icons.image, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 25),
                                  buildRow(
                                      context,
                                      Icons.person,
                                      'Email',
                                      '${userDocument['uname'] ?? 'No name available'}',
                                      false,
                                      selectedCompanyId
                                  ),
                                  SizedBox(height: 16),
                                  // SizedBox(height: 16),
                                  buildRow(
                                      context,
                                      Icons.phone,
                                      'Phone',
                                      '${companyDocument['contact'] ?? 'No contact available'}',
                                      true,
                                      selectedCompanyId
                                  ),
                                  SizedBox(height: 16),
                                  buildRow(
                                      context,
                                      Icons.web,
                                      'Website',
                                      '${companyDocument['website'] ?? 'No website available'}',
                                      true,
                                      selectedCompanyId
                                  ),
                                  SizedBox(height: 16),
                                  buildRow(
                                      context,
                                      Icons.warehouse_rounded,
                                      'Company Name',
                                      '${companyDocument['company_name'] ?? 'No name available'}',
                                      true,
                                      selectedCompanyId
                                  ),
                                  SizedBox(height: 16),
                                  buildRow(
                                      context,
                                      Icons.description,
                                      'About',
                                      '${companyDocument['dec'] ?? 'No name available'}',
                                      true,
                                      selectedCompanyId
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return Center(child: Text('No company data available'));
                          }
                        },
                      );
                    } else {
                      return Center(child: Text('No user data available'));
                    }
                  },
                );
              } else {
                return Center(child: Text('No Company ID found'));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildRow(BuildContext context, IconData icon, String title, String value, bool editable, String selectedCompanyId) {
    var docId;
    switch(title){
      case 'Phone':
        docId = 'contact';
      case 'Website':
        docId = 'website';
      case 'About':
        docId = 'dec';
      case 'Company Name':
        docId = 'company_name';
    }
    print(value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.black, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
          if (editable)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.green),
              onPressed: () => _editProfile(docId, value, selectedCompanyId),
            ),
        ],
      ),
    );
  }

  void _editProfile(String fieldType, String initialValue, String documentId) {
    _showEditDialog(context, fieldType, initialValue, documentId);
  }

  void _showEditDialog(BuildContext context, String fieldType, String initialValue, String documentId) {
    final TextEditingController _controller = TextEditingController(text: initialValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Edit Profile Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              labelText: 'Enter new $fieldType',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                String newValue = _controller.text.trim();
                if (newValue.isNotEmpty) {
                  // Update the Firestore document
                  await FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .collection('company_details')
                      .doc(documentId)
                      .update({
                    '$fieldType': newValue, // Use fieldType to determine the field to update
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

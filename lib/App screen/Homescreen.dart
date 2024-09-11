
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task1/App%20screen/profile_page.dart';
import 'package:task1/App%20screen/shared_data.dart';
import 'package:task1/App%20screen/userlist.dart';
import 'package:task1/App%20screen/view_shared_request.dart';

import 'Cashmove_Screen.dart';
import 'notification_icon.dart';
import 'notifications/Message_services.dart';


class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>  with WidgetsBindingObserver {

  MessageServices nofification = MessageServices();

  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  // bool _authenticated = false;
  bool showNotificationWidget = false;
  String notificationTitle = "";
  String notificationBody = "";



  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId;
  List<Map<String, dynamic>> companyDetailsList = [];
  List<String> companyDocIds = [];
  List<String> companyNamesList = [];
   String? selectedCompany;
   String? selectedCompanyId;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool isGridView = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    nofification.requestNotificationPermission();
    nofification.initialize(onMessageReceived);
    userId = _firebaseAuth.currentUser!.uid;
    getSelectedCompanyIdFromPref().then((_) {
      fetchCompanyDetails();
    });
    loadNotificationDetails();
  }

  void onMessageReceived(RemoteMessage message) {
    setState(() {
      showNotificationWidget = true;
      notificationTitle = message.notification?.title ?? "No Title";
      notificationBody = message.notification?.body ?? "No Body";
    });
  }

  Future<void> loadNotificationDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? title = prefs.getString('notificationTitle');
    String? body = prefs.getString('notificationBody');

    if (title != null && body != null) {
      setState(() {
        showNotificationWidget = true;
        notificationTitle = title;
        notificationBody = body;
      });
    }
  }


  void clearSavedNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('notificationTitle');
    await prefs.remove('notificationBody');
  }



  @override
  void dispose() {
    super.dispose();
  }







  Future<void> getSelectedCompanyIdFromPref() async {
    var prefs = await SharedPreferences.getInstance();
    String? storedCompanyId = prefs.getString('docid_company');
    if (storedCompanyId != null) {
      setState(() {
        selectedCompanyId = storedCompanyId;
      });
    }
  }


  Future<void> fetchCompanyDetails() async {
    try {
      final snapshot = await _firestore
          .collection('Users')
          .doc(userId)
          .collection('company_details')
          .get();



      List<String> tempCompanyNamesList = [];
      List<String> tempCompanyDocIds = [];
      List<Map<String, dynamic>> tempCompanyDetailsList = [];

      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('company_name')) {
          tempCompanyNamesList.add(doc['company_name'] as String);
          tempCompanyDocIds.add(doc.id);
          tempCompanyDetailsList.add(doc.data());
        }
      }

      if (mounted) {
        setState(() {
          companyNamesList = tempCompanyNamesList;
          companyDocIds = tempCompanyDocIds;
          companyDetailsList = tempCompanyDetailsList;

          if (selectedCompanyId == null && companyNamesList.isNotEmpty) {
            selectedCompanyId = companyDocIds[0];
            selectedCompany = companyNamesList[0];
            addCompanyIdToPref(selectedCompanyId!);
          } else if (selectedCompanyId != null) {
            int index = companyDocIds.indexOf(selectedCompanyId!);
            if (index != -1) {
              selectedCompany = companyNamesList[index];
            } else {
              selectedCompanyId = companyDocIds[0];
              selectedCompany = companyNamesList[0];
              addCompanyIdToPref(selectedCompanyId!);
            }
          }
        });
      }
    } catch (e) {
      print('Error fetching company details: $e');
    }
  }



  void addCompanyIdToPref(String companyId) async {
    print('Saving companyId: $companyId');
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('docid_company', companyId);
  }




  void _showUserList(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Share Access'),
          content: Container(
            width: double.maxFinite,
            child: UserList(currentUserId: userId, companyId: selectedCompanyId!),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.table_chart,color: Colors.grey,), // Icon for the app bar
            SizedBox(width: 8),
            // Text('MI'),
            SizedBox(
              width: width * 0.3,
              child: DropdownButtonFormField(
                decoration: InputDecoration.collapsed(
                    hintText: 'Tap to switch business',
                ),
                isExpanded: true,
                hint: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Tap to switch business",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // Initial Value
                value: selectedCompany,

                // Down Arrow Icon
                icon: const Icon(Icons.keyboard_arrow_down),

                // Array list of items
                items: companyNamesList.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCompany = newValue!;
                    int selectedIndex = companyNamesList.indexOf(selectedCompany!);
                    selectedCompanyId = companyDocIds[selectedIndex];
                    // Call addCompanyIdToPref to store the selected company ID
                    addCompanyIdToPref(selectedCompanyId!);
                  });
                },
              ),
            ),
            GestureDetector(
              onTap: (){Navigator.pushNamed(context, '/add_company');},
              child: Icon(Icons.add,),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.person_add,color: Colors.blue[800],),
              onPressed: () {_showUserList(context);},
            ),
            SizedBox(width: 5,),
            // IconButton(
            //   icon: Icon(Icons.notifications),
            //   onPressed: () {
            //     Navigator.of(context).push(MaterialPageRoute(
            //       builder: (context) => DataSharingRequestList(userId: userId),
            //     ));
            //   },
            // ),
            NotificationIcon( userId: userId,),
            SizedBox(width: 5,),
            IconButton(
              icon: Icon(Icons.logout,color: Colors.black54,),
              onPressed: () async {
                FirebaseAuth.instance.signOut();
                // var prefs = await SharedPreferences.getInstance();
                // prefs.remove('docid_company');
              },
            ),
          ],
        ),
      ),
      body:ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Visibility(
            visible: showNotificationWidget,
            child: Column(
              children: [
            Container(
            decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 3,
            blurRadius: 9,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue,
            Colors.blueAccent,
            Colors.lightBlue,
          ],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding for responsiveness
      height: height * 0.10,
      child: Stack(
        children: [
          // Main content of the container
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
              children: [
                // Notification icon with padding
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: CircleAvatar(
                    child: Icon(Icons.notifications_active, color: Colors.yellow[600]),
                    backgroundColor: Colors.white,
                  ),
                ),
                SizedBox(width: width*0.05,height: double.infinity,),
                // Text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text.rich(
                      TextSpan(
                        text: '$notificationTitle\n',
                        style: TextStyle(
                          fontSize: 16, // Adjusted font size for better readability
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: '$notificationBody\n',
                            style: TextStyle(
                              fontSize: 12, // Adjusted font size for better readability
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis, // Handle text overflow
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Positioned close icon
          Positioned(
            top: -12, // Adjusted for better visibility
            right: -15, // Adjusted for better visibility
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  showNotificationWidget = false;
                });
                clearSavedNotification();
              },
            ),
          ),
        ],
      ),
    ),
    SizedBox(height: height * 0.04),
              ],
            ),
          ),

          Row(
            children: [
              Text(
                'Your Books',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Spacer(),
              if (_isSearching)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18.0),
                    child: TextField(
                      onChanged: (txt){
                        setState(() {
                        });
                      },
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              if (!_isSearching)
                Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: IconButton(
                    icon: Icon(isGridView ?Icons.list:Icons.grid_view_rounded, color: Colors.blue[800]),
                    onPressed: () {
                      setState(() {
                        isGridView = !isGridView;
                      });
                      // Handle menu icon click if needed
                    },
                  ),
                ),
              IconButton(
                icon: Icon(Icons.search, color: Colors.blue[800]),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    _searchController.clear();
                  });
                },
              ),
            ],
          ),
          if(isGridView)
            GridViewBook()
          else
            ListViewBook(),
          SizedBox(height: 20),
          Text('Shared Books', style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),),
          ViewShareBooks(),
          SizedBox(height: height * 0.03),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey.shade300)
            ),
            child: Padding(
              padding:  EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,),textAlign: TextAlign.left,),
                        Text('Click to quickly add books for',style :TextStyle(color: Colors.grey)),
                  ],),
                    Spacer(),
                    CircleAvatar(child: Icon(Icons.my_library_books_outlined,color: Colors.blue[600],),),
                  ],),
                  SizedBox(height: height * 0.03,),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: Colors.blue)
                                )
                            )
                        ),
                        onPressed: () async {
                          _showCreateDialog(context,'Month Expense','May Expenses','tags');
                          // AddBook('May Expenses','expense transactions');
                        },
                        child: Text('May Expenses'),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: Colors.blue)
                                )
                            )
                        ),
                        onPressed: () {
                          _showCreateDialog(context,'Payable Transactions','Payable Book','tags');
                          // AddBook('Payable Book','payable transactions');
                        },
                        child: Text('Payable Book'),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                    side: BorderSide(color: Colors.blue)
                                )
                            )
                        ),
                        onPressed: () {
                          _showCreateDialog(context,'Client Record','client transactions','tags');
                          // AddBook('Client Record','client transactions');
                        },
                        child: Text('Client Record'),
                      ),
                      ElevatedButton(
                      style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              side: BorderSide(color: Colors.blue)
                          )
                      )
                      ),
                        onPressed: () {
                          _showCreateDialog(context,'project transactions','Project Book','tags');
                          // AddBook('Project Book','project transactions');
                        },
                        child: Text('Project Book'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Text(currentUser()),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/bookcreate');
        },
        label: const Text('ADD NEW BOOK',style: TextStyle(color: Colors.white),),
        icon: const Icon(Icons.add,color: Colors.white,),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget ListViewBook() {
    return StreamBuilder(
      stream: userDetails
          .doc(_firebaseAuth.currentUser!.uid)
          .collection('company_details')
          .doc('$selectedCompanyId')
          .collection('Books')
          .where('book_name', isGreaterThanOrEqualTo: _searchController.text)
          .where('book_name', isLessThanOrEqualTo: _searchController.text + '\uf8ff') // This ensures the query is case-insensitive and includes all matching books.
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          return SingleChildScrollView(
            physics: ScrollPhysics(),
            child: Column(
              children: <Widget>[
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var document = snapshot.data!.docs[index];
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap:(){
                                      print(document.id);
                                      Navigator.push(context,
                                        MaterialPageRoute(
                                          builder: (context) => Csh_Move_Screen(book_sel_doc:document.id, Bookname: snapshot.data!.docs[index].get('book_name'), editable: true, CurrentUserId: userId, UserType: 'currentuser', selectedcompany: selectedCompanyId,),
                                        ),);
                                    },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.book, color: Colors.blue[800]),
                                  ),
                                  title: Text(snapshot.data!.docs[index].get('book_name') ?? '',
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    'Updated on '+snapshot.data!.docs[index].get('date') ?? '',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  trailing: StreamBuilder(
                                    stream: document.reference.collection('cash_transactions').snapshots(),
                                    builder: (context, AsyncSnapshot<QuerySnapshot> cashSnapshot) {
                                      if (cashSnapshot.hasData) {
                                        int totalInPositive = 0;
                                        int totalInNegative = 0;

                                        cashSnapshot.data!.docs.forEach((doc) {
                                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                          int amount = int.parse(data['amount']);
                                          String condition = data['condition'];

                                          if (condition == 'Credit') {
                                            totalInPositive += amount;
                                          } else {
                                            totalInNegative += amount;
                                          }
                                        });

                                        int netBalance = totalInPositive - totalInNegative.abs();
                                        return Text(netBalance.toString(),
                                            style: TextStyle(color: netBalance >= 0?Colors.green:Colors.red, fontSize: 15, fontWeight: FontWeight.bold));
                                      } else {
                                        return CircularProgressIndicator();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                            // GestureDetector(
                            //     onTap: (){
                            //
                            // },
                            //     child: Icon(Icons.more_vert_outlined, color: Colors.grey)
                            // ),
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert_outlined, color: Colors.grey),
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem<String>(
                                    value: 'Edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'Delete',
                                    child: Text('Delete'),
                                  ),
                                ];
                              },
                              onSelected: (String selectedOption) {
                                if (selectedOption == 'Edit') {
                                  _showEditDialog(context,snapshot.data!.docs[index].get('book_name'),snapshot.data!.docs[index].get('tag'),document.id);
                                  // Handle edit action
                                } else if (selectedOption == 'Delete') {
                                  userDetails.doc(userId).collection('company_details').doc(selectedCompanyId).collection('Books').doc(document.id).delete();
                                  // Handle delete action
                                }
                              },
                            ),

                          ],
                        ),
                        Divider(
                          color: Colors.blueGrey[100],
                          height: 1,
                          thickness: 1,
                          indent: 56,
                          endIndent: 16,
                        ),
                      ],
                    );
                  },
                )
              ],
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }



  Widget GridViewBook() {
    return StreamBuilder(
      stream: userDetails
          .doc(_firebaseAuth.currentUser!.uid)
          .collection('company_details')
          .doc('$selectedCompanyId')
          .collection('Books')
          .where('book_name', isGreaterThanOrEqualTo: _searchController.text)
          .where('book_name', isLessThanOrEqualTo: _searchController.text + '\uf8ff')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasData) {
          return SingleChildScrollView(
            child: Column(
              children: [
                GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var document = snapshot.data!.docs[index];
                    return GestureDetector(
                      onTap: () {
                        print(document.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Csh_Move_Screen(
                              book_sel_doc: document.id,
                              Bookname: snapshot.data!.docs[index].get('book_name'),
                              editable: true,
                              CurrentUserId: userId,
                              UserType: 'currentuser',
                              selectedcompany: selectedCompanyId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              child: Icon(Icons.book, color: Colors.blue[800]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              snapshot.data!.docs[index].get('book_name') ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Updated on ' + snapshot.data!.docs[index].get('date') ?? '',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            StreamBuilder(
                              stream: document.reference.collection('cash_transactions').snapshots(),
                              builder: (context, AsyncSnapshot<QuerySnapshot> cashSnapshot) {
                                if (cashSnapshot.hasData) {
                                  int totalInPositive = 0;
                                  int totalInNegative = 0;

                                  cashSnapshot.data!.docs.forEach((doc) {
                                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                    int amount = int.parse(data['amount']);
                                    String condition = data['condition'];

                                    if (condition == 'Credit') {
                                      totalInPositive += amount;
                                    } else {
                                      totalInNegative += amount;
                                    }
                                  });

                                  int netBalance = totalInPositive - totalInNegative.abs();
                                  return Text(
                                    netBalance.toString(),
                                    style: TextStyle(
                                      color: netBalance >= 0 ? Colors.green : Colors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                } else {
                                  return CircularProgressIndicator();
                                }
                              },
                            ),
                            // PopupMenuButton<String>(
                            //   icon: Icon(Icons.more_vert_outlined, color: Colors.grey),
                            //   itemBuilder: (BuildContext context) {
                            //     return [
                            //       PopupMenuItem<String>(
                            //         value: 'Edit',
                            //         child: Text('Edit'),
                            //       ),
                            //       PopupMenuItem<String>(
                            //         value: 'Delete',
                            //         child: Text('Delete'),
                            //       ),
                            //     ];
                            //   },
                            //   onSelected: (String selectedOption) {
                            //     if (selectedOption == 'Edit') {
                            //       _showEditDialog(
                            //         context,
                            //         snapshot.data!.docs[index].get('book_name'),
                            //         snapshot.data!.docs[index].get('tag'),
                            //         document.id,
                            //       );
                            //     } else if (selectedOption == 'Delete') {
                            //       userDetails
                            //           .doc(userId)
                            //           .collection('company_details')
                            //           .doc(selectedCompanyId)
                            //           .collection('Books')
                            //           .doc(document.id)
                            //           .delete();
                            //     }
                            //   },
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }




  //
  Widget ViewShareBooks() {
     return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('SharedData')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No shared data available'));
        }

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ViewSharedBooks(),
            ),
          ),
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Container(
              height: 100,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.book,
                    size: 40,
                    color: Colors.blue,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Shared Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to view shared books',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 20,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }





  Future<void> AddBook(String bookname, String tags) async {
    var now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    print(formattedDate);
    final data = {'book_name': bookname, 'tag': tags, 'date': formattedDate};
    var doc_ref = await userDetails.doc(userId).collection('company_details').doc(selectedCompanyId).collection('Books').add(data);
    // book_sel_doc = doc_ref.id;
  }



  void _showCreateDialog(BuildContext context, String fieldType, String initialValue, String tags) {
    final TextEditingController _controller = TextEditingController(text: initialValue);
    final TextEditingController _controller2 = TextEditingController(text: tags);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        var size = MediaQuery.of(context).size;
        var height = size.height;
        var width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Create Book Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            height: height * 0.25,
            width: width * 0.8,
            child: Column(
              children: [
                TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: 'Book Name',
                  ),
                ),
                SizedBox(height: height * 0.02),
                TextFormField(
                  controller: _controller2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: 'Tag',
                  ),
                ),
              ],
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
                AddBook(_controller.text, _controller2.text);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }



  void _showEditDialog(BuildContext context, String bookname, String tags, String docid) {
    final TextEditingController _controller = TextEditingController(text: bookname);
    final TextEditingController _controller2 = TextEditingController(text: tags);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        var size = MediaQuery.of(context).size;
        var height = size.height;
        var width = size.width;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Edit Book Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Container(
            height: height * 0.25,
            width: width * 0.8,
            child: Column(
              children: [
                TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: 'Book Name',
                  ),
                ),
                SizedBox(height: height * 0.02),
                TextFormField(
                  controller: _controller2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelText: 'Tag',
                  ),
                ),
              ],
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
                String newBookName = _controller.text;
                String newTags = _controller2.text;
                var now = DateTime.now();
                String formattedDate = DateFormat('yyyy-MM-dd').format(now);

                final data = {
                  'book_name': newBookName,
                  'tag': newTags,
                  'date': formattedDate,
                };

                await userDetails
                    .doc(userId)
                    .collection('company_details')
                    .doc(selectedCompanyId)
                    .collection('Books')
                    .doc(docid)
                    .update(data);

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





class main_interface extends StatefulWidget {
  const main_interface({super.key});

  @override
  State<main_interface> createState() => _main_interfaceState();
}

class _main_interfaceState extends State<main_interface> {
  int myIndex = 0;
  List<StatefulWidget> list_nav =[HomeScreen(),Profile()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: list_nav[myIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Cashbooks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_3),
            label: 'Profile',
          ),
        ],
        currentIndex: myIndex,
        onTap: (index) {
          setState(() {
            myIndex = index;
            print(myIndex);
            list_nav[myIndex];
            print(list_nav[myIndex]);
          });
        },
      ),
    );
  }



}


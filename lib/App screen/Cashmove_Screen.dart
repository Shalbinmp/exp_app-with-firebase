
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_validator/string_validator.dart';
import 'package:task1/App%20screen/pdf%20generation/functions/pdf_functions.dart';
// import 'package:task1/App%20screen/pdf%20generation/ui/pdf_view.dart';
import 'package:task1/model/model.dart';
import 'package:task1/App%20screen/reporting%20section/ui%20part/view_report.dart';

import 'Add_Cash_Screen.dart';
import 'notifications/local_notification.dart';
import 'one_trans_details.dart';

class Csh_Move_Screen extends StatefulWidget {

  final String book_sel_doc;
  final String Bookname;
  final bool editable;
  final String UserType;
  final String CurrentUserId;
  final selectedcompany;
   Csh_Move_Screen({super.key,required this.book_sel_doc, required this.Bookname,required this.editable,required this.CurrentUserId,required this.UserType,required this.selectedcompany});


  @override
  State<Csh_Move_Screen> createState() => _Csh_Move_ScreenState();
}

class _Csh_Move_ScreenState extends State<Csh_Move_Screen> {
  late Modal modal;

  // late PDFDocument pdfDoc;
  //
  // void openPdfViewer() {
  //   final pdfViewer = PDFViewer(document: pdfDoc);
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => pdf_view()),
  //   );
  // }

  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PdfUtils pdf_function = PdfUtils();

  var size;
  var height;
  var width;
  late String userId;
    String? selectedCompanyId;
   String? searchvalue;
   String? select_date = 'Select Date';
   String? entry_type = 'Entry Type';
  String? selected_cust = 'Select Customer';
  List<dynamic> dateList = [];
  List<dynamic> customerList = [];


  @override
  void initState() {
    print('user :  ${this.widget.CurrentUserId}');
    print('user : company ${this.widget.selectedcompany}');
    // TODO: implement initState
    super.initState();
    userId = _firebaseAuth.currentUser!.uid;
    fetchDate();
    fetchCustomer();
    modal = Modal(bookSelDoc: this.widget.book_sel_doc, currentUserId: this.widget.CurrentUserId, companyId: this.widget.selectedcompany,); // Initialize with your bookSelDoc
    modal.cash_trans_data().then((_) {
      setState(() {});  // Update the UI once the data is loaded
    });
    LocalNotification.init();
  }



  Future<void> fetchDate() async {
    try {
      dateList.add('All');
      final snapshot = await _firestore
          .collection('Users')
          .doc(this.widget.CurrentUserId)
          .collection('company_details')
          .doc(this.widget.selectedcompany)
          .collection('Books')
          .doc(this.widget.book_sel_doc)
          .collection('cash_transactions')
          .get();
      snapshot.docs.forEach((doc) {
        // Assuming your date field is named 'date'
        String timestamp = doc['date']; // Adjust 'date' to your field name
        String date = timestamp.toString();
        if(dateList.contains(date)){

        }
        else {
          dateList.add(date);
        }
      });

      print(dateList);
    }
    catch (e) {
      print(e);
    }
  }

  Future<void> _requestPermissions() async {
    if (await Permission.storage.isDenied) {
      await Permission.storage.request();
    }
    final PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      print('Granted');
      // Notification permissions granted
    } else if (status.isDenied) {
      print('Denied');
      Permission.notification.request();
      // Notification permissions denied
    } else if (status.isPermanentlyDenied) {
      print('Denied for permently');
      // Notification permissions permanently denied, open app settings
      await openAppSettings();
    }

  }





  Future<void> fetchCustomer() async {
    try {
      customerList.add('All');
      final snapshot = await _firestore
          .collection('Users')
          .doc(this.widget.CurrentUserId)
          .collection('company_details')
          .doc(this.widget.selectedcompany)
          .collection('Books')
          .doc(this.widget.book_sel_doc)
          .collection('cash_transactions')
          .get();
      snapshot.docs.forEach((doc) {
        // Assuming your date field is named 'date'
        String timestamp = doc['customer']; // Adjust 'date' to your field name
        String cust = timestamp.toString();
        if(customerList.contains(cust)){

        }
        else {
          customerList.add(cust);
        }
      });

      print(customerList);
    }
    catch (e) {
      print(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return  Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,leading:  GestureDetector(onTap:(){Navigator.pop(context);},child: Icon(Icons.arrow_back_ios)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${this.widget.Bookname}',style: TextStyle(color: Colors.black,fontSize: 18,fontWeight: FontWeight.bold),),
            Text('Add Member,Book Activity etc',style: TextStyle(color: Colors.grey,fontSize: 12),),
          ],
        ),
        actions: [
          // Icon(Icons.person_add_alt_outlined,color: Colors.deepPurple,),
          SizedBox(width: 20,),
          GestureDetector(
            onTap: () async {
              List<Map<String, dynamic>> data = await modal.fetchData();
              final pdf = await PdfUtils.generatePDF(data);
              await _requestPermissions();
              await pdf_function.savePdfFile('balnce history', pdf);
              // pdfDoc = await PDFDocument.fromFile(pdf);
              // openPdfViewer();

              // Navigator.of(context).push(MaterialPageRoute(builder: (context) => pdf_view()));
              },
              child: Icon(Icons.picture_as_pdf_outlined,color: Colors.deepPurple,)
          ),
          SizedBox(width: 20,),
          // Icon(Icons.more_vert_outlined,color: Colors.deepPurple,),
          // SizedBox(width: 10,),
        ],
      ),
      body:  SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: TextField(
                  onChanged: (change){
                    setState(() {
                      searchvalue = change;
                    });
                    print(searchvalue);
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                      prefixIconColor: Colors.blue,
                      hintText: 'Search By Remarks or Amount',
                      hintStyle: TextStyle(fontSize: 18,color: Colors.grey
                      ),
                  ),
                ),
              ),
              Container(
                // adding margin
                // margin: const EdgeInsets.all(15.0),
                // adding padding
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  // adding borders around the widget
                  border: Border.all(
                    color: Colors.transparent,
                    // width: 5.0,
                  ),
                ),

                child: SingleChildScrollView(
                  //for horizontal scrolling
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15,top: 10),
                    child: Row(
                      children: [
                        Chip(label: Icon(Icons.filter),shape:RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),),
                      SizedBox(width: 10,),
                        PopupMenuButton<String>(
                          child: Chip(label: Row(children: [Icon(Icons.calendar_month),Text(select_date=='All'? 'Select Date':select_date!),Icon(Icons.arrow_drop_down)],),shape:RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),side: BorderSide(color: ['All','Select Date'].contains(select_date)? Colors.black:Colors.lightBlueAccent)),
                          // icon: Icon(Icons.arrow_drop_down),
                          itemBuilder: (BuildContext context) {
                            return dateList.map((date) {
                              return PopupMenuItem<String>(
                                value: date,
                                child: Text(date),
                              );
                            }).toList();
                          },
                          onSelected: (String selectedDate) {
                            // Handle the selected date here
                            setState(() {
                              select_date = selectedDate;
                            });
                            print('Selected date: $selectedDate');
                          },),

                        SizedBox(width: 10,),
                        PopupMenuButton<String>(
                          child: Chip(label: Row(children: [Text(entry_type=='All'? 'Entry Type':entry_type!),Icon(Icons.arrow_drop_down)],),shape:RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),side: BorderSide(color: ['All','Entry Type'].contains(entry_type)? Colors.black:Colors.lightBlueAccent)),
                          // icon: Icon(Icons.arrow_drop_down),
                          itemBuilder: (BuildContext context) {
                            return ['All','Credit','Debit'].map((date) {
                              return PopupMenuItem<String>(
                                value: date,
                                child: Text(date),
                              );
                            }).toList();
                          },
                          onSelected: (String selectedtype) {
                            // Handle the selected date here
                            setState(() {
                              entry_type = selectedtype;
                            });
                            print('Selected date: $selectedtype');
                          },),

                        SizedBox(width: 10,),
                        PopupMenuButton<String>(
                          child: Chip(label: Row(children: [Text(selected_cust=='All'? 'Select Customer':selected_cust!),Icon(Icons.arrow_drop_down)],),shape:RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30)),side: BorderSide(color: ['All','Select Customer'].contains(selected_cust)? Colors.black:Colors.lightBlueAccent))),
                          // icon: Icon(Icons.arrow_drop_down),
                          itemBuilder: (BuildContext context) {
                            return customerList.map((date) {
                              return PopupMenuItem<String>(
                                value: date,
                                child: Text(date),
                              );
                            }).toList();
                          },
                          onSelected: (String selectedcust) {
                            // Handle the selected date here
                            setState(() {
                              selected_cust = selectedcust;
                            });
                            print('Selected date: $selectedcust');
                          },),
                      // Chip(label: Row(children: [Text('Select Date'),Icon(Icons.arrow_drop_down)],),shape:RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),),
                        SizedBox(width: 10,),
                      ],
                    ),
                  )
                ),
              ),
              SizedBox(height: 10,),
              Net_balance_section(),
              SizedBox(height: height * 0.025,),
              Row(
                  children: <Widget>[
                    SizedBox(width: 10,),
                    Expanded(
                        child: Divider(color: Colors.blueGrey[100],)
                    ),
                    SizedBox(width: 10,),
                    Text('Show All entries',style: TextStyle(color: Colors.grey,fontWeight: FontWeight.bold),),
                    SizedBox(width: 10,),
                    Expanded(
                        child: Divider(color: Colors.blueGrey[100],)
                    ),
                    SizedBox(width: 10,),
                  ]
              ),
              SizedBox(height: height * 0.005,),
              Tranction_section(),

            ],
          ),
        ),
      ),
      bottomNavigationBar: this.widget.editable? BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(onPressed: (){
                    Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => AddCash(book_sel_doc: this.widget.book_sel_doc, condition: 'Credit', CurrentUserId: this.widget.CurrentUserId, companyId: this.widget.selectedcompany,),
                      ),);
                  }, child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon(Icons.add,color: Colors.white,),
                      Text('+',style: TextStyle(color: Colors.white),),
                      SizedBox(width: 5,),
                      Text('CASH IN',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
                    ],
                  ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          side: BorderSide(color: Colors.green)
                      ),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.08,),
                Expanded(
                  child: ElevatedButton(onPressed: (){
                    Navigator.push(context,
                    MaterialPageRoute(
                    builder: (context) => AddCash(book_sel_doc: this.widget.book_sel_doc, condition: 'Debit', CurrentUserId: this.widget.CurrentUserId, companyId: this.widget.selectedcompany,),
                  ),);
                  }, child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('-',style: TextStyle(color: Colors.white),),
                      SizedBox(width: 5,),
                      Text('CASH OUT',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                    ],
                  ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          side: BorderSide(color: Colors.red)
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ): null,
    );
  }


  Widget Net_balance_section() {
    return StreamBuilder(
        stream:
            this.widget.UserType == 'currentuser'?
        userDetails
        .doc(_firebaseAuth.currentUser!.uid)
        .collection('company_details')
        .doc(this.widget.selectedcompany)
        .collection('Books')
        .doc(this.widget.book_sel_doc)
        .collection('cash_transactions')
        .snapshots():
            userDetails
                .doc(this.widget.CurrentUserId)
                .collection('company_details')
                .doc(this.widget.selectedcompany)
                .collection('Books')
                .doc(this.widget.book_sel_doc)
                .collection('cash_transactions')
                .snapshots()
        ,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if(snapshot.hasData){
            // print('no of data:${snapshot.data.}');
              int totalInPositive = 0;
              int totalInNegative = 0;
              int balance=0;

              // snapshot.data!.docs.forEach((doc) {
              //   Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              //   int amount = int.parse(data['amount']);
              //   if (amount > 0) {
              //     totalInPositive += amount;
              //   } else {
              //     totalInNegative += amount;
              //   }
              // });

              snapshot.data!.docs.reversed.forEach((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                int amount = int.parse(data['amount']);
                String condition = data['condition'];
                if (condition == 'Credit') {
                  // If condition is credit, add the amount to totalInPositive
                  totalInPositive += amount;
                  balance += amount;
                } else {
                  // If condition is debit, add the amount to totalInNegative
                  totalInNegative += amount;
                  balance -= amount;
                }
                print(balance);
              });

              int netBalance = totalInPositive - totalInNegative.abs();

              return Container(
              margin:EdgeInsets.symmetric(horizontal: 15),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding:EdgeInsets.symmetric(horizontal: 15),
                    height: 50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Net Balance',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                        Text('${NumberFormat("#,###").format(netBalance)}',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                      ],),),
                  Container(
                    height: 100,
                    padding:EdgeInsets.symmetric(horizontal: 15),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Total In(+)',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            Text('${NumberFormat("#,###").format(totalInPositive)}',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.green),),
                          ],),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Total In(-)',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold),),
                            Text('${NumberFormat("#,###").format(totalInNegative)}',style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.red),),
                          ],)
                      ],
                    ),

                  ),
                  GestureDetector(
                    child: Container(
                    height: 50,
                    padding:EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('VIEW REPORT',style: TextStyle(fontSize: 15,fontWeight: FontWeight.bold,color: Colors.deepPurple),),
                        SizedBox(width: 10,),
                        Icon(Icons.arrow_forward_ios,color: Colors.deepPurple,),
                      ],
                    ),
                  ),onTap: (){
                    Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => View_Report(book_sel_doc: this.widget.book_sel_doc, Bookname: this.widget.Bookname, CurrentUserId: this.widget.CurrentUserId, companyId: this.widget.selectedcompany,),
                      ),);
                  },),
                ],
              ),
            );
          }
          else{
            return Center(child: CircularProgressIndicator(),);
          }
        });
  }

  Widget Tranction_section() {

    final baseQuery = this.widget.UserType == 'currentuser'? userDetails
        .doc(_firebaseAuth.currentUser!.uid)
        .collection('company_details')
        .doc(this.widget.selectedcompany)
        .collection('Books')
        .doc(this.widget.book_sel_doc)
        .collection('cash_transactions'):
    userDetails
        .doc(this.widget.CurrentUserId)
        .collection('company_details')
        .doc(this.widget.selectedcompany)
        .collection('Books')
        .doc(this.widget.book_sel_doc)
        .collection('cash_transactions');

    Stream<QuerySnapshot> stream;

    if (searchvalue != null && searchvalue!.isNotEmpty) {
      if (searchvalue!.isNumeric) {
        // Query by amount
        Query query = baseQuery
            .where('amount', isGreaterThanOrEqualTo: searchvalue)
            .where('amount', isLessThan: searchvalue! + '9');
        // Filter by date if selected
        if (select_date != null && select_date!.isNotEmpty && select_date != 'Select Date' && select_date != 'All') {
          query = query.where('date', isEqualTo: select_date);
        }

        if (selected_cust != null && selected_cust!.isNotEmpty && selected_cust != 'Select Customer' && selected_cust != 'All') {
          query = query.where('customer', isEqualTo: selected_cust);
        }

        if (entry_type != null && entry_type!.isNotEmpty && entry_type != 'Entry Type' && entry_type != 'All') {
          query = query.where('condition', isEqualTo: entry_type);
        }

        stream = query.snapshots();
      } else {
        // Query by remarks
        Query query = baseQuery
            .where('remarks', isGreaterThanOrEqualTo: searchvalue)
            .where('remarks', isLessThanOrEqualTo: searchvalue! + '\uf8ff');

        // Filter by date if selected
        if (select_date != null && select_date!.isNotEmpty && select_date != 'Select Date' && select_date != 'All') {
          query = query.where('date', isEqualTo: select_date);
        }

        if (selected_cust != null && selected_cust!.isNotEmpty && selected_cust != 'Select Customer' && selected_cust != 'All') {
          query = query.where('customer', isEqualTo: selected_cust);
        }


        if (entry_type != null && entry_type!.isNotEmpty && entry_type != 'Entry Type' && entry_type != 'All') {
          query = query.where('condition', isEqualTo: entry_type);
        }

        stream = query.snapshots();
      }
    } else {
      // Default query ordered by time
      Query query = baseQuery;

      // Filter by date if selected
      if (select_date != null && select_date!.isNotEmpty && select_date != 'Select Date' && select_date != 'All') {
        query = query.where('date', isEqualTo: select_date);
      }

      if (entry_type != null && entry_type!.isNotEmpty && entry_type != 'Entry Type' && entry_type != 'All') {
        query = query.where('condition', isEqualTo: entry_type);
      }

      if (selected_cust != null && selected_cust!.isNotEmpty && selected_cust != 'Select Customer' && selected_cust != 'All') {
        query = query.where('customer', isEqualTo: selected_cust);
      }


      query = query.orderBy('time');




      stream = query.snapshots();
    }

    return StreamBuilder(
      stream: stream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Placeholder for when data is loading
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No data available")); // Placeholder for empty data
        }

        int balance = 0;
        List<Map<String, dynamic>> transactions = [];

        // Iterate over the transactions to calculate the balance
        for (var doc in snapshot.data!.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          int amount = int.parse(data['amount']);
          String condition = data['condition'];

          // Calculate balance for each transaction
          if (condition == 'Credit') {
            balance += amount;
          } else {
            balance -= amount;
          }

          // Add balance to transaction data
          data['balance'] = balance;
          transactions.add(data);
        }

        return ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> data = transactions[transactions.length - 1 - index]; // Reverse order for display
            return GestureDetector(
              onTap: (){
                print('print id');
                print('${data['id']}');
                print('${this.widget.book_sel_doc}');
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => TransDetail(t_doc_id: data['id'], book_sel_doc: this.widget.book_sel_doc, companyId: this.widget.selectedcompany, CurrentUserId: this.widget.CurrentUserId,), // Pass the ID here
                ));
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 10, left: 15, bottom: 10),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(data['date'] ?? '')).toUpperCase(),
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    height: height * 0.13,
                    color: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        Container(
                          height: height * 0.08,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              data['condition'] != 'Credit'
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.blue[100],
                                    ),
                                    padding: EdgeInsets.only(right: 5, left: 5, top: 2, bottom: 2),
                                    child: Text(data['payment method'] ?? '', style: TextStyle(color: Colors.blue[700])),
                                  ),
                                  Container(
                                    child: Text("${data['customer'] ?? ''} Credit", style: TextStyle(color: Colors.blue[700])),
                                  ),
                                ],
                              )
                                  : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.blue[100],
                                ),
                                padding: EdgeInsets.only(right: 5, left: 5, top: 2, bottom: 2),
                                child: Text(data['payment method'] ?? '', style: TextStyle(color: Colors.blue[700])),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('${NumberFormat('#,###').format(int.parse(data['amount']) ?? 0)}',
                                      style: data['condition'] == 'Credit'
                                          ? TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)
                                          : TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
                                  Text('Balance: ${NumberFormat("#,###").format(data['balance'] ?? '')}', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Divider(),
                              RichText(
                                text: TextSpan(
                                  text: "Entry by You",
                                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                  children: <TextSpan>[
                                    TextSpan(
                                        text: "  at ${data['time'] ?? ''}",
                                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }




}



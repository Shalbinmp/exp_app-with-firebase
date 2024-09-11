import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'Cashmove_Screen.dart';

class Book_create extends StatefulWidget {
  const Book_create({super.key});

  @override
  State<Book_create> createState() => _Book_createState();
}

class _Book_createState extends State<Book_create> {
  final CollectionReference user_details = FirebaseFirestore.instance.collection('Users');

  final FirebaseAuth _auth = FirebaseAuth.instance;


  TextEditingController bookname =TextEditingController();
  TextEditingController customer =TextEditingController();
  TextEditingController remarks =TextEditingController();
  TextEditingController Category =TextEditingController();
  var size;
  var height;
  var width;
  String _value = 'Cash';
  bool _check_val = false;
  late String _date;
  late String _time;
  late String book_sel_doc;
  bool isLoading = false;
  String? selectedCompanyId;
  var _formKey = GlobalKey<FormState>();


  _selectDate() async {
    DateTime dateTime = DateTime.now();
    final DateTime? picked = await
    showDatePicker(context: context,
        initialDate: dateTime,
        initialDatePickerMode: DatePickerMode.day,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101));
    if (picked != null) {
      dateTime = picked;
      //assign the chosen date to the controller
      setState(() {
        _date = DateFormat('yyyy-MM-dd').format(dateTime).toString();
      });
    }
  }

  _selectTime() async {
    TimeOfDay time = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (picked != null) {
      setState(() {
        time = picked;
        // Format and assign the chosen time to a controller or variable
        _time = picked.format(context); // Assuming _time is a String
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _date = DateFormat('yyyy-MM-dd').format(DateTime.now()).toString();
      _time =  '${(TimeOfDay.now().hour % 12 == 0 ? 12 : TimeOfDay.now().hour % 12).toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} ${TimeOfDay.now().hour >= 12 ? 'PM' : 'AM'}';
    });

  }




  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,leading: IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.arrow_back_ios)),
        title: Text('Add Books',style: TextStyle(color: Colors.green,fontSize: 20,fontWeight: FontWeight.bold),),
        actions: [Icon(Icons.settings_outlined,color: Colors.deepPurple,),SizedBox(width: width * 0.04,),],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 15,right: 15,top: 15),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.calendar_month),
                          Text(_date),
                          GestureDetector(child: Icon(Icons.arrow_drop_down),
                            onTap: (){
                            _selectDate();
                            },),
                        ],
                      ),
                    ),
                    // Spacer(),
                    SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.access_time_outlined),
                          Text(_time),
                          GestureDetector(child: Icon(Icons.arrow_drop_down),
                            onTap: (){
                            _selectTime();
                            },),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: height * 0.05,width: double.infinity,),
                TextFormField(
                  style: TextStyle(color: Colors.green),
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Book Name',),
                  controller: bookname,
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter Your Book Name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.025,width: double.infinity,),
                TextFormField(
                  controller: Category,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Category',
                      suffixIcon: Icon(Icons.arrow_drop_down)
                  ),
                  validator:(value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter Category';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.025,width: double.infinity,),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              :Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });
                        await AddBook(bookname.text, Category.text);
                        setState(() {
                          isLoading = false;
                        });
                        Navigator.popAndPushNamed(context, '/bookcreate');
                      }
                    },
                    child:  Text('SAVE & ADD NEW', style: TextStyle(fontWeight: FontWeight.bold),),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        side: BorderSide(color: Colors.deepPurple),
                      ),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.08,),
                SizedBox(
                  width: width * 0.3,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });
                        await AddBook(bookname.text, Category.text);
                        setState(() {
                          isLoading = false;
                        });
                        Navigator.pushReplacement(context,
                          MaterialPageRoute(
                            builder: (context) => Csh_Move_Screen(book_sel_doc:book_sel_doc, Bookname: bookname.text, editable: true, CurrentUserId: _auth.currentUser!.uid.toString(), UserType: 'curentuser', selectedcompany: selectedCompanyId,),
                          ),
                        );
                      }
                    },
                    child:Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
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

  Future<void> AddBook(String bookname, String tags) async {
    final data = {'book_name': bookname, 'tag': tags, 'date': _date};
    User? currUser = _auth.currentUser;
    var pref = await SharedPreferences.getInstance();
    var doc_id = pref.getString('docid_company');
    var doc_ref = await user_details.doc(currUser!.uid).collection('company_details').doc(doc_id).collection('Books').add(data);
    book_sel_doc = doc_ref.id;
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
}
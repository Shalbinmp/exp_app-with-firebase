import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_validator/string_validator.dart';
import 'Cashmove_Screen.dart';



class AddCash extends StatefulWidget {
  final String book_sel_doc;
  final String condition;
  final CurrentUserId;
  final companyId;
  const AddCash({super.key, required this.book_sel_doc, required this.condition,required this.CurrentUserId,required this.companyId});

  @override
  State<AddCash> createState() => _AddCashState();
}

class _AddCashState extends State<AddCash> {
  final CollectionReference user_details = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SpeechToText _speechToText = SpeechToText();

  TextEditingController amount = TextEditingController();
  TextEditingController customer = TextEditingController();
  TextEditingController remarks = TextEditingController();
  TextEditingController Category = TextEditingController();
  List<String> dynamicFields = [];
  Map<String, TextEditingController> dynamicFieldControllers = {};
  var size;
  var height;
  var width;
  String _value = 'Cash';
  bool _check_val = false;
  late String _date;
  late String _time;
  bool _speechEnabled = false;
  String _wordsSpoken = '';
  double _confidenceLevel = 0;
  Color _micColor = Colors.deepPurple;
  String? selectedFileName;
  PlatformFile? selectedFile;
  String? bookname;
  String? fileUrl;
  bool _showMoreChips = false;
  final List<String> additionalChipLabels = ['Bank Transfer', 'Cheque', 'Cryptocurrency'];
  bool _showMore = false;
  String? userId;
  String? selectedCompanyId;
  String? currencyCode;
  List<String> supportedCurrencies = [];
  TextEditingController currencyController = TextEditingController();
  var _formKey = GlobalKey<FormState>();



  @override
  void initState() {
    super.initState();
    _date = DateFormat('yyyy-MM-dd').format(DateTime.now()).toString();
    _time = '${(TimeOfDay.now().hour % 12 == 0 ? 12 : TimeOfDay.now().hour % 12).toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} ${TimeOfDay.now().hour >= 12 ? 'PM' : 'AM'}';
    userId = FirebaseAuth.instance.currentUser!.uid;
    _initSpeech();
    _getSupportedCode();
    getCompanyCurrency();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    // Dispose of all dynamic field controllers
    dynamicFieldControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(onError: _handleError, onStatus: _handleStatus);
    setState(() {});
  }

  void _handleError(SpeechRecognitionError error) {
    print("Speech recognition error: ${error.errorMsg}");
    _stopListening();
  }

  void _handleStatus(String status) {
    print("Speech recognition status: $status");
    if (status == "notListening") {
      _stopListening();
    }
  }


  void _startListening() async {
    await _speechToText.listen(onResult: onSpeechResult);
    setState(() {
      _micColor = Colors.red;
    });
  }

  void onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      _confidenceLevel = result.confidence;
      remarks.text = _wordsSpoken;
    });

    // Check if speech recognition has stopped automatically
    if (result.finalResult) {
      _stopListening();
    }
  }


  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _micColor = Colors.deepPurple;
      // Add this line to reset the recognized words and confidence level
      _wordsSpoken = '';
      _confidenceLevel = 0.0;
    });
  }


  Future<String> AddCashEntry(
      String amt,
      String cust,
      String remark,
      String cat,
      String type,
      bool sms,
      Map<String, String> dynamicFields,String currency) async {

    User? currUser = _auth.currentUser;
    var pref = await SharedPreferences.getInstance();
    var doc_id = pref.getString('docid_company');

    // Ensure dynamicFields is a map of field labels and values
    // dynamicFields should be a Map<String, String> where key is field label and value is field value

    final data = {
      'amount': amt,
      'customer': cust,
      'remarks': remark,
      'category': cat,
      'payment method': type,
      'sms': sms,
      'date': _date,
      'time': _time,
      'condition': widget.condition,
      'additionalFields': dynamicFields,
      'currency': currency,
    };

    try {
      DocumentSnapshot<Map<String, dynamic>> bookDoc = await user_details
          .doc(this.widget.CurrentUserId)
          .collection('company_details')
          .doc(this.widget.companyId)
          .collection('Books')
          .doc(widget.book_sel_doc)
          .get();

      bookname = bookDoc.data()?['book_name'] as String?;
    } catch (e) {
      print(e);
    }

    // Add data to Firestore and wait for the document reference
    DocumentReference<Map<String, dynamic>> transactionDoc = await user_details
        .doc(this.widget.CurrentUserId)
        .collection('company_details')
        .doc(this.widget.companyId)
        .collection('Books')
        .doc(widget.book_sel_doc)
        .collection('cash_transactions')
        .add(data);

    // Update the document with the date
    await user_details
        .doc(this.widget.CurrentUserId)
        .collection('company_details')
        .doc(this.widget.companyId)
        .collection('Books')
        .doc(widget.book_sel_doc)
        .update({'date': _date});

    // Return the document ID
    return transactionDoc.id;
  }


  Future<void> getCompanyCurrency() async {
    try {
      DocumentSnapshot companyDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.CurrentUserId)
          .collection('company_details')
          .doc(widget.companyId)
          .get();

      if (companyDoc.exists) {
        var data = companyDoc.data() as Map<String, dynamic>;
        if (data.containsKey('currency')) {
          setState(() {
            currencyCode = data['currency'] ?? 'USD';
          });
        } else {
          print('Currency field does not exist');
          setState(() {
            currencyCode = 'USD'; // Default value
          });
        }
      } else {
        print('Company document does not exist');
      }
    } catch (e) {
      print('Error fetching company currency: $e');
    }
  }




  Future<void> _selectDate() async {
    DateTime dateTime = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateTime,
      initialDatePickerMode: DatePickerMode.day,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateTime = picked;
      setState(() {
        _date = DateFormat('yyyy-MM-dd').format(dateTime).toString();
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay time = TimeOfDay.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (picked != null) {
      setState(() {
        time = picked;
        _time = picked.format(context);
      });
    }
  }

  void openFile(PlatformFile file) async{
    OpenFile.open(file.path);

    print('filename   ${file.name}');
    print('Bytes    ${file.bytes}');
    print('file size   ${file.size}');
    print('Extention    ${file.extension}');
    print('Path:  ${file.path}');

    final newFile = await saveFilePermanently(file);

    print('From Path : ${file.path!}');
    print('To Path : ${newFile.path}');
  }

  Future<File> saveFilePermanently(PlatformFile file) async{
    final appStorage = await getApplicationDocumentsDirectory();
    final newFile = File('${appStorage.path}/${file.name}');

    return File(file.path!).copy(newFile.path);
  }


  Future<bool> uploadFileForUser(PlatformFile file, String transactionDocId) async {
    try {
      var pref = await SharedPreferences.getInstance();
      var doc_id = pref.getString('docid_company');
      User? currUser = _auth.currentUser;
      print('in start uploadfileforuser');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("No user is currently signed in.");
        return false;
      }
      final storageRef = FirebaseStorage.instance.ref();
      print('Storage ref found');
      final fileName = file.name;
      print('Filename get');
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      print('sec');
      final uploadRef = storageRef.child('${this.widget.CurrentUserId}/uploads/${widget.book_sel_doc}/$transactionDocId/$timestamp-$fileName');

      File localFile = File(file.path!);
      await uploadRef.putFile(localFile);


      fileUrl = await uploadRef.getDownloadURL();
      print(fileUrl);

      // Update the Firestore document with the file URL
      // await user_details
      //     .doc(userId)
      //     .collection('company_details')
      //     .doc(transactionDocId)
      //     .update({'fileUrl': fileUrl});

      await user_details
          .doc(this.widget.CurrentUserId)
          .collection('company_details')
          .doc(this.widget.companyId)
          .collection('Books')
          .doc(widget.book_sel_doc)
      .collection('cash_transactions')
      .doc(transactionDocId)
      .update({'file': fileUrl});


      print("File uploaded successfully to $uploadRef");
      return true;
    } catch (e) {
      print("File upload failed with error: $e");
      return false;
    }
  }





  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: () { Navigator.pop(context); }, icon: Icon(Icons.arrow_back_ios)),
        title: Text('Add Cash In Entry', style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
        // actions: [Icon(Icons.settings_outlined, color: Colors.deepPurple), SizedBox(width: width * 0.04)],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 15,bottom: 15),
          child: Form(
            key:_formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month),
                          Text(_date),
                          GestureDetector(
                            child: Icon(Icons.arrow_drop_down),
                            onTap: () { _selectDate(); },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      child: Row(
                        children: [
                          Icon(Icons.access_time_outlined),
                          Text(_time),
                          GestureDetector(
                            child: Icon(Icons.arrow_drop_down),
                            onTap: () { _selectTime(); },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: height * 0.05, width: double.infinity),
                TextFormField(
                  style: TextStyle(color: Colors.green),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Amount',
                  ),
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter a Amount';
                    }
                    else if(!value.isInt || !value.isFloat){
                      return 'Please Enter a Valid number';
                    }
                    return null;
                  },
                  controller: amount,
                ),
                SizedBox(height: height * 0.025, width: double.infinity),
                TextFormField(
                  controller: customer,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Party(Customer/Supplier)',
                    suffixIcon: Icon(Icons.clear),
                  ),
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Please Enter Customer Name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.015, width: double.infinity),
                Container(
                  decoration: BoxDecoration(
                    border: Border.fromBorderSide(BorderSide(width: 1, color: Colors.grey)),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  height: height * 0.05,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          child: Row(
                            children: [
                              Icon(Icons.copy_all, color: Colors.green),
                              SizedBox(width: 10),
                              Text('Send bill to Test via free SMS', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: _check_val,
                          onChanged: (val) {
                            setState(() {
                              _check_val = val!;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.02, width: double.infinity),
                TextFormField(
                  controller: remarks,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Remarks',
                    hintText: _speechToText.isListening ? 'Listening...' : _speechEnabled ? "Tap the mic to start listening.." : "Speech is not available",
                    suffixIcon: GestureDetector(
                      onTap: () {
                        if (_speechToText.isListening) {
                          _stopListening();
                        } else {
                          _startListening();
                        }
                      },
                      child: Icon(
                        Icons.mic,
                        color: _micColor,
                      ),
                    ),
                  ),
                  validator: (value){
                    if(value == null || value.isEmpty){
                      return 'Enter Any remarks';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.025, width: double.infinity),
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'jpg', 'png'],
                    );
                    if (result == null) return;
                    final file = result.files.first;

                    setState(() {
                      selectedFile = file;
                    });

                    // Perform upload operation asynchronously
                    // bool success = await uploadFileForUser(file);
                    // if (!success) {
                      // Optionally handle the error or revert the selection
                      // setState(() {
                      //   selectedFile = null;
                      // });
                      // Show error message to the user
                    // }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    width: width * 0.6,
                    height: height * 0.05,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.attachment_outlined, color: Colors.deepPurple),
                          Expanded(
                            child: selectedFile == null
                                ? Text(
                              'Attach Image or PDF',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : GestureDetector(
                              onTap: () {
                                // Code to open the file
                                openFile(selectedFile!);
                              },
                              child: Text(
                                selectedFile!.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (selectedFile != null)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final result = await FilePicker.platform.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['pdf', 'jpg', 'png'],
                                    );
                                    if (result == null) return;
                                    final file = result.files.first;
                                    // bool success = await uploadFileForUser(file);
                                    // if (success) {
                                      setState(() {
                                        selectedFile = file;
                                      });
                                      // Optionally open the file
                                      // openFile(file);
                                    // } else {
                                    //   // Optionally handle the error
                                    // }
                                  },
                                  child: Icon(Icons.change_circle, color: Colors.deepPurple),
                                ),
                                SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedFile = null;
                                    });
                                  },
                                  child: Icon(Icons.cancel, color: Colors.red),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025, width: double.infinity),
                TextFormField(
                  controller: Category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Category',
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                ),
                SizedBox(height: height * 0.025, width: double.infinity),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Currency',
                  ),
                  value: currencyCode,
                  items: supportedCurrencies.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      currencyCode = newValue!;
                    });
                  },
                ),
                SizedBox(height: height * 0.025, width: double.infinity),
                Text('Payment Mode', style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold)),
                SizedBox(height: height * 0.02, width: double.infinity),
                Wrap(
                  spacing: 8.0, // Horizontal space between chips
                  runSpacing: 4.0, // Vertical space between chips
                  children: [
                    ChoiceChip(
                      label: Text(
                        'Cash',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _value == 'Cash' ? Colors.white : Colors.black54,
                        ),
                      ),
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.grey[300],
                      showCheckmark: false,
                      selected: _value == 'Cash',
                      onSelected: (select) {
                        setState(() {
                          _value = (select ? 'Cash' : null)!;
                        });
                      },
                      side: BorderSide(color: Colors.transparent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                    ),
                    ChoiceChip(
                      label: Text(
                        'Online',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _value == 'Online' ? Colors.white : Colors.black54,
                        ),
                      ),
                      side: BorderSide(color: Colors.transparent),
                      showCheckmark: false,
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                      selected: _value == 'Online',
                      onSelected: (select) {
                        setState(() {
                          _value = (select ? 'Online' : null)!;
                        });
                      },
                    ),
                    if (_showMore) ...additionalChipLabels.map((label) => ChoiceChip(
                      label: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _value == label ? Colors.white : Colors.black54,
                        ),
                      ),
                      side: BorderSide(color: Colors.transparent),
                      showCheckmark: false,
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
                      selected: _value == label,
                      onSelected: (selected) {
                        setState(() {
                          _value = selected ? label : '';
                        });
                      },
                    )),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showMore = !_showMore;
                        });
                      },
                      child: Row(
                        children: [
                          Text(_showMore ? 'Show Less' : 'Show More', style: TextStyle(color: Colors.deepPurple)),
                          Icon(_showMore ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.purple),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.025),
                GestureDetector(
                  onTap: _showAddFieldDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.fromBorderSide(BorderSide(width: 1, color: Colors.grey)),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    width: width * 0.35,
                    height: height * 0.04,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Add More Fields', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.025, width: double.infinity),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: dynamicFields.map((fieldLabel) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: height * 0.025),
                        TextFormField(
                          controller: dynamicFieldControllers[fieldLabel], // Use the controller
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: fieldLabel,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
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
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          Map<String, String> dynamicFieldsMap = _getDynamicFieldsMap(); // Get the dynamic fields map
                          String transactionDocId = await AddCashEntry(
                          amount.text,
                          customer.text,
                          remarks.text,
                          Category.text,
                          _value,
                          _check_val,
                          dynamicFieldsMap,
                          currencyCode!  // Add this line
                          );
                          bool fileUploaded = true;
                          if (selectedFile != null) {
                            print('selected file');
                            fileUploaded = await uploadFileForUser(selectedFile!, transactionDocId);
                          }
                          if (fileUploaded) {
                            print('Navigating to AddCash...');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddCash(
                                  book_sel_doc: this.widget.book_sel_doc,
                                  condition: this.widget.condition, CurrentUserId: this.widget.CurrentUserId, companyId: this.widget.companyId,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('File upload failed')),
                            );
                          }
                        } catch (e) {
                          print('Error during save & add new: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Save & Add New failed: $e')),
                          );
                        }
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
                SizedBox(width: width * 0.08),
                SizedBox(
                  width: width * 0.3,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          Map<String, String> dynamicFieldsMap = _getDynamicFieldsMap();
                          // Save the cash entry
                          String transactionDocId = await AddCashEntry(
                              amount.text,
                              customer.text,
                              remarks.text,
                              Category.text,
                              _value,
                              _check_val,
                              dynamicFieldsMap,
                              currencyCode!  // Add this line
                          );

                          // Handle file upload
                          bool fileUploaded = true;
                          if (selectedFile != null) {
                            fileUploaded = await uploadFileForUser(selectedFile!, transactionDocId);
                          }

                          // Proceed based on file upload success
                          if (fileUploaded) {
                            // Navigate to the Csh_Move_Screen
                            Navigator.pop(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Csh_Move_Screen(
                                  book_sel_doc: this.widget.book_sel_doc,
                                  Bookname: bookname ?? 'Default Book Name',
                                  editable: true,
                                  CurrentUserId: userId.toString(),
                                  UserType: 'currentuser', selectedcompany:selectedCompanyId,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('File upload failed')),
                            );
                          }
                        } catch (e) {
                          print('Error during save: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Save failed: $e')),
                          );
                        }
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
  Map<String, String> _getDynamicFieldsMap() {
    final Map<String, String> dynamicFieldsMap = {};
    for (String field in dynamicFields) {
      dynamicFieldsMap[field] = dynamicFieldControllers[field]?.text ?? ''; // Use the controller text
    }
    return dynamicFieldsMap;
  }


  void _showAddFieldDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController fieldController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
          'Add New Field',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
          content: TextFormField(
            controller: fieldController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: Text('String')
            ),
          ),
          actions: <Widget>[
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
                String fieldLabel = fieldController.text;
                setState(() {
                  dynamicFields.add(fieldLabel);
                  dynamicFieldControllers[fieldLabel] = TextEditingController(); // Add the controller
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            // TextButton(
            //   child: Text('Add'),
            //   onPressed: () {
            //     String fieldLabel = fieldController.text;
            //     setState(() {
            //       dynamicFields.add(fieldLabel);
            //       dynamicFieldControllers[fieldLabel] = TextEditingController(); // Add the controller
            //     });
            //     Navigator.of(context).pop();
            //   },
            // ),
          ],
        );
      },
    );
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

  Future<void> getSelectedCompanyIdFromPref() async {
    var prefs = await SharedPreferences.getInstance();
    String? storedCompanyId = prefs.getString('docid_company');
    if (storedCompanyId != null) {
      setState(() {
        selectedCompanyId = storedCompanyId;
      });
    }
  }


  // bool _validateInputs() {
  //   if (amount.text.isEmpty || customer.text.isEmpty || remarks.text.isEmpty || Category.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please fill all required fields')),
  //     );
  //     return false;
  //   }
  //   if (double.tryParse(amount.text) == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please enter a valid amount')),
  //     );
  //     return false;
  //   }
  //   if (currencyCode == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please select a currency')),
  //     );
  //     return false;
  //   }
  //   return true;
  // }

}


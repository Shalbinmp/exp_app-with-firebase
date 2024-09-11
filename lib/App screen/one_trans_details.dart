import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TransDetail extends StatefulWidget {
  final String book_sel_doc;
  final String t_doc_id;
  final companyId;
  final CurrentUserId;
  TransDetail({super.key, required this.t_doc_id, required this.book_sel_doc, required this.companyId, required this.CurrentUserId});

  @override
  State<TransDetail> createState() => _TransDetailState();
}

class _TransDetailState extends State<TransDetail> {
  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? selectedCompanyId;
  String? originalSymbol;
  var currencySymbols = {
    'AED': 'د.إ',
    'AFN': 'Af',
    'ALL': 'L',
    'AMD': 'դր.',
    'ANG': 'ƒ',
    'AOA': 'Kz',
    'ARS': '\$',
    'AUD': 'A\$',
    'AWG': 'ƒ',
    'AZN': 'ман',
    'BAM': 'KM',
    'BBD': '\$',
    'BDT': '৳',
    'BGN': 'лв.',
    'BHD': 'ب.د',
    'BIF': 'Fr',
    'BMD': '\$',
    'BND': 'S\$',
    'BOB': 'Bs.',
    'BRL': 'R\$',
    'BSD': '\$',
    'BTN': 'Nu.',
    'BWP': 'P',
    'BYN': 'Br',
    'BZD': 'BZ\$',
    'CAD': 'C\$',
    'CDF': 'Fr',
    'CHF': 'CHF',
    'CLP': '\$',
    'CNY': '¥',
    'COP': '\$',
    'CRC': '₡',
    'CUP': '₱',
    'CVE': '\$',
    'CZK': 'Kč',
    'DJF': 'Fdj',
    'DKK': 'kr',
    'DOP': 'RD\$',
    'DZD': 'د.ج',
    'EGP': '£',
    'ERN': 'Nkf',
    'ETB': 'Br',
    'EUR': '€',
    'FJD': 'FJ\$',
    'FKP': '£',
    'FOK': 'kr',
    'GBP': '£',
    'GEL': 'ლ',
    'GHS': '₵',
    'GIP': '£',
    'GMD': 'D',
    'GNF': 'Fr',
    'GTQ': 'Q',
    'GYD': '\$',
    'HKD': 'HK\$',
    'HNL': 'L',
    'HRK': 'kn',
    'HTG': 'G',
    'HUF': 'Ft',
    'IDR': 'Rp',
    'ILS': '₪',
    'INR': '₹',
    'IQD': 'ع.د',
    'IRR': '﷼',
    'ISK': 'kr',
    'JMD': '\$',
    'JOD': 'د.ا',
    'JPY': '¥',
    'KES': 'KSh',
    'KGS': 'с',
    'KHR': '៛',
    'KID': 'A\$',
    'KMF': 'Fr',
    'KRW': '₩',
    'KWD': 'د.ك',
    'KYD': '\$',
    'KZT': '₸',
    'LAK': '₭',
    'LBP': 'ل.ل',
    'LKR': 'Rs',
    'LRD': '\$',
    'LSL': 'M',
    'LYD': 'ل.د',
    'MAD': 'د.م.',
    'MDL': 'L',
    'MGA': 'Ar',
    'MKD': 'ден',
    'MMK': 'K',
    'MNT': '₮',
    'MOP': 'MOP\$',
    'MRU': 'UM',
    'MUR': '₨',
    'MVR': 'MVR',
    'MWK': 'MK',
    'MXN': '\$',
    'MYR': 'RM',
    'MZN': 'MT',
    'NAD': '\$',
    'NGN': '₦',
    'NIO': 'C\$',
    'NOK': 'kr',
    'NPR': 'Rs',
    'NZD': 'NZ\$',
    'OMR': 'ر.ع.',
    'PAB': 'B/.',
    'PEN': 'S/.',
    'PGK': 'K',
    'PHP': '₱',
    'PKR': '₨',
    'PLN': 'zł',
    'PYG': '₲',
    'QAR': 'ر.ق',
    'RON': 'lei',
    'RSD': 'дин.',
    'RUB': '₽',
    'RWF': 'Fr',
    'SAR': 'ر.س',
    'SBD': '\$',
    'SCR': '₨',
    'SDG': 'ج.س.',
    'SEK': 'kr',
    'SGD': 'S\$',
    'SHP': '£',
    'SLL': 'Le',
    'SOS': 'S',
    'SRD': '\$',
    'SSP': '£',
    'STN': 'Db',
    'SYP': 'ل.س',
    'SZL': 'E',
    'THB': '฿',
    'TJS': 'ЅМ',
    'TMT': 'T',
    'TND': 'د.ت',
    'TOP': 'T\$',
    'TRY': '₺',
    'TTD': '\$',
    'TVD': 'A\$',
    'TZS': 'TSh',
    'UAH': '₴',
    'UGX': 'USh',
    'USD': '\$',
    'UYU': '\$',
    'UZS': 'лв',
    'VES': 'Bs.S',
    'VND': '₫',
    'VUV': 'Vt',
    'WST': 'WS\$',
    'XAF': 'Fr',
    'XAG': 'oz',
    'XAU': 'oz',
    'XCD': '\$',
    'XOF': 'Fr',
    'XPF': 'CFP',
    'YER': 'ر.ي',
    'ZAR': 'R',
    'ZMK': 'ZK',
    'ZWL': 'Z\$',
  };

  @override
  void initState() {
    super.initState();
    get_doc_pref().then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          'Trans Details',
          style: TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: userDetails
            .doc(this.widget.CurrentUserId)
            .collection('company_details')
            .doc(this.widget.companyId)
            .collection('Books')
            .doc(this.widget.book_sel_doc)
            .collection('cash_transactions')
            .doc(this.widget.t_doc_id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: Text('No data available'));
          } else {
            var transactionData = snapshot.data!.data() as Map<String, dynamic>?;

            if (transactionData == null) {
              return Center(child: Text('No transactions found'));
            }

            // Extract the single transaction details
            String amount = transactionData['amount']?.toString() ?? 'No Amount';
            String category = transactionData['category'] ?? 'No Category';
            String condition = transactionData['condition']?.toString() ?? 'No Condition';
            String customer = transactionData['customer']?.toString() ?? 'No Customer';
            String date = transactionData['date']?.toString() ?? 'No Date';
            String time = transactionData['time']?.toString() ?? 'No Time';
            String payment_method = transactionData['payment method']?.toString() ?? 'No Method';
            String remarks = transactionData['remarks']?.toString() ?? 'No Remarks';
            String file = transactionData['file']?.toString() ?? '';

            bool isPDF = file.toLowerCase().contains('.pdf');
            bool isImage = file.toLowerCase().contains('.png') || file.toLowerCase().contains('.jpg') || file.toLowerCase().contains('.jpeg');

            Map<String, dynamic>? additionalFields = transactionData['additionalFields'];
            var currency = transactionData.containsKey('currency')? transactionData['currency']:'USD';
            originalSymbol = currencySymbols[currency] ?? '\$';
            print('original : $currency');

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: height * 0.08,),
                  Text(condition == 'Credit' ? 'From $customer' : 'To $customer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                  SizedBox(height: height * 0.02,),
                  FutureBuilder<Map<String, String>>(
                    future: _getConvertRate(amount,currency),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (futureSnapshot.hasError) {
                        return Center(child: Text('Error: ${futureSnapshot.error}'));
                      } else if (!futureSnapshot.hasData) {
                        return Text('No amount available');
                      } else {
                        // Safely access the data with null checks
                        // originalSymbol = futureSnapshot.data!['orginal_symbol'] ?? '\$';
                        String convertedSymbol = futureSnapshot.data!['converted_symbol'] ?? '\$';
                        String convertedAmount = futureSnapshot.data!['amount'] ?? '';
                        print('in future $originalSymbol');
                        return Text('$convertedSymbol $convertedAmount', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold));
                      }
                    },
                  ),
                  SizedBox(height: height * 0.02,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified, color: Colors.blue),
                      SizedBox(width: width * 0.02,),
                      Text('Completed')
                    ],
                  ),
                  SizedBox(height: height * 0.004,),
                  Divider(indent: 70, endIndent: 70),
                  SizedBox(height: height * 0.008,),
                  Text('${date}, ${time}', style: TextStyle(fontSize: 15)),
                  SizedBox(height: height * 0.025,),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (file.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(
                                  'No attachment available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            )
                          else if (isPDF)
                            Container(
                              height: 300,
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0), // Optional, for rounded corners
                                  child: SfPdfViewer.network(
                                    file,
                                    controller: PdfViewerController(), // Optional, if you need to control the PDF viewer
                                  ),
                                ),
                              ),
                            )
                          else if (isImage)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(file, height: 200, width: double.infinity,),
                              ),
                          Divider(color: Colors.grey),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '${originalSymbol} ${amount}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '${category}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Remarks',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '${remarks}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Method',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '${payment_method}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (additionalFields != null && additionalFields.isNotEmpty)
                                  ...additionalFields.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            '${entry.value}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: height * 0.1,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }


  Future<String> _isCurrencyInCompanyDetails() async {
    try {
      DocumentSnapshot companyDetailsDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.CurrentUserId)
          .collection('company_details')
          .doc(widget.companyId)
          .get();

      if (companyDetailsDoc.exists) {
        Map<String, dynamic>? data = companyDetailsDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('currency')) {
          String currencies = data['currency'];
          print(currencies);
          return currencies;
        }
      }
      return 'USD';
    } catch (e) {
      print('Error checking currency: $e');
      return 'USD';
    }
  }

  Future<Map<String, String>> _getConvertRate(String amount,String basecurrency) async {
    double rate = double.parse(amount);
    String dbCurrency = await _isCurrencyInCompanyDetails();
    var currency = basecurrency; // Replace with the actual currency code you want to check

    if (currency == dbCurrency) {
      return {'symbol': '\$', 'amount': rate.toString()};
    }

    // Map of currency codes to symbols

    var original_currency = currencySymbols[currency] ?? '\$';

    print('in function : $original_currency');

    var converted_symbol = currencySymbols[dbCurrency] ?? dbCurrency;

    var url = 'https://v6.exchangerate-api.com/v6/98b0a93a65e8cf76ff152cab/pair/$currency/$dbCurrency/$rate';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      var convertRate = result['conversion_rate'];
      print('Converted rate: $convertRate');
      return {'converted_symbol': converted_symbol, 'amount': (rate * convertRate).toStringAsFixed(2),'orginal_symbol':original_currency};
    } else {
      print('Request failed with status: ${response.statusCode}');
      return {'converted_symbol': converted_symbol, 'amount': '','orginal_symbol':original_currency};
    }
  }

  Future<bool> get_doc_pref() async {
    var pref = await SharedPreferences.getInstance();
    var doc_id = pref.getString('docid_company');
    setState(() {
      selectedCompanyId = doc_id!;
    });
    return selectedCompanyId!.isEmpty ? true : false;
  }

  void _showErrorMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(''),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

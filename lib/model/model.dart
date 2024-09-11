import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Modal {
  final String bookSelDoc;
  final currentUserId;
  final companyId;
  late final String selectedCompanyId;
  late final Query baseQuery;
  late final Query query;
  late Stream<QuerySnapshot> stream;

  final CollectionReference userDetails = FirebaseFirestore.instance.collection('Users');
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Modal({required this.bookSelDoc,required this.currentUserId,required this.companyId}) {
    cash_trans_data();
  }



  Future<void> cash_trans_data() async {
    selectedCompanyId = await getDocPref();
    baseQuery = userDetails
        .doc(this.currentUserId)
        .collection('company_details')
        .doc(this.companyId)
        .collection('Books')
        .doc(bookSelDoc)
        .collection('cash_transactions');

    query = baseQuery;
    stream = query.snapshots();
  }


  Future<String> getDocPref() async {
    /// To get the company Doc Id which company we selected by shared preference
    var pref = await SharedPreferences.getInstance();
    var docId = pref.getString('docid_company');
    if (docId != null) {
      return docId;
    } else {
      throw Exception('Company doc ID not found in shared preferences');
    }
  }

  Stream<List<Map<String, dynamic>>> getTransactionStream() {
    return stream.map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }



  Future<List<Map<String, dynamic>>> fetchData() async {
    final data = await query.get();
    return data.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}

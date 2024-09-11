// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
//
// class demo_db extends StatefulWidget {
//   const demo_db({super.key});
//
//   @override
//   State<demo_db> createState() => _demo_dbState();
// }
//
// class _demo_dbState extends State<demo_db> {
//   final CollectionReference user_details = FirebaseFirestore.instance.collection('user_details');
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body:StreamBuilder(
//           stream: user_details.snapshots(),
//           builder:(context,AsyncSnapshot snapshot){
//             if(snapshot.hasData){
//               return ListView.builder(
//                 itemCount: snapshot.data!.docs.length,
//                   itemBuilder:(context, index){
//                   final DocumentSnapshot userSnap = snapshot.data.docs[index];
//                   return Text(userSnap['uname']);
//                   }
//               );
//             }
//             else
//             {
//               return Text('no');
//             }
//           } , ) ,
//
//     );
//   }
// }

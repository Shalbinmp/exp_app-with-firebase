import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task1/App%20screen/view_shared_request.dart';

class NotificationIcon extends StatelessWidget {
  final String userId;

  NotificationIcon({required this.userId});

  Stream<int> getPendingRequestsCount() {
    return FirebaseFirestore.instance
        .collection('SharedData')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: getPendingRequestsCount(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  child: SizedBox()
                  // Container(
                  //   padding: EdgeInsets.all(1),
                  //   decoration: BoxDecoration(
                  //     color: Colors.red,
                  //     borderRadius: BorderRadius.circular(6),
                  //   ),
                  //   constraints: BoxConstraints(
                  //     minWidth: 12,
                  //     minHeight: 12,
                  //   ),
                  //   child:
                  //   Text(
                  //     '',
                  //     style: TextStyle(
                  //       color: Colors.white,
                  //       fontSize: 8,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  // ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DataSharingRequestList(userId: userId),
              ));
            },
          );
        }

        if (snapshot.hasError) {
          return IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => DataSharingRequestList(userId: userId),
              ));
            },
          );
        }

        final int pendingRequestsCount = snapshot.data ?? 0;

        return IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications),
              if (pendingRequestsCount > 0)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '$pendingRequestsCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => DataSharingRequestList(userId: userId),
            ));
          },
        );
      },
    );
  }
}

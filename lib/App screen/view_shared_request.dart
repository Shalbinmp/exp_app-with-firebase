import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DataSharingRequestList extends StatelessWidget {
  final String userId;

  DataSharingRequestList({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text('Data Sharing Requests'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('SharedData')
              .where('recipientId', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No pending requests'));
            }

            var requests = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var request = requests[index];
                return ListTile(
                  title: Text('Data Sharing Request'),
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Users').doc(request['ownerId']).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading...');
                      }
                      if (snapshot.hasError) {
                        return Text('Error loading user data');
                      }
                      if (snapshot.hasData && snapshot.data!.exists) {
                        return Text('From: ${snapshot.data!['uname']}');
                      } else {
                        return Text('Unknown user');
                      }
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => _showConfirmationDialog(context, request.id, true),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => _showConfirmationDialog(context, request.id, false),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String requestId, bool isAccepting) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isAccepting ? 'Accept Request' : 'Decline Request'),
          content: Text('Are you sure you want to ${isAccepting ? 'accept' : 'decline'} this request?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                if (isAccepting) {
                  _acceptRequest(context, requestId);
                } else {
                  _declineRequest(context, requestId);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptRequest(BuildContext context, String sharedDataId) async {
    try {
      await FirebaseFirestore.instance.collection('SharedData').doc(sharedDataId).update({
        'status': 'approved',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request accepted. You now have access to the shared data.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request. Please try again.')),
        );
      }
    }
  }

  Future<void> _declineRequest(BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance.collection('DataSharingRequests').doc(requestId).update({
        'status': 'declined',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request declined.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request. Please try again.')),
        );
      }
    }
  }

  Future<void> _shareData(BuildContext context, String requestId, String userId) async {
    try {
      // Fetch the request details
      DocumentSnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('DataSharingRequests')
          .doc(requestId)
          .get();
      String senderId = requestSnapshot['senderId'];
      String companyId = requestSnapshot['companyId'];

      // Fetch the sender's user details
      DocumentSnapshot senderSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(senderId)
          .get();
      String senderUname = senderSnapshot['uname'];

      // Store senderId and senderUname in recipient's 'shared_data' collection
      DocumentReference sharedDataRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('shared_data')
          .doc(senderId); // Use senderId as the document ID to store data

      DocumentSnapshot sharedDataSnapshot = await sharedDataRef.get();

      if (sharedDataSnapshot.exists) {
        // If the document exists, update the companyIds array
        await sharedDataRef.update({
          'companyIds': FieldValue.arrayUnion([companyId]),
        });
      } else {
        // If the document does not exist, create it with the companyIds array
        Map<String, dynamic> sharedData = {
          'senderId': senderId,
          'senderName': senderUname, // Store sender's name
          'companyIds': [companyId],
        };
        await sharedDataRef.set(sharedData);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data shared successfully!')),
        );
      }
    } catch (error) {
      print('Error sharing data: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share data. Please try again.')),
        );
      }
    }
  }
}

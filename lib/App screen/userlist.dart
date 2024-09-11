import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserList extends StatefulWidget {
  final String currentUserId;
  final String companyId;

  UserList({required this.currentUserId, required this.companyId});

  @override
  _UserListState createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  TextEditingController _searchController = TextEditingController();
  String _searchEmail = '';
  List<Map<String, dynamic>> _users = []; // Store user data with permissions
  List<Map<String, dynamic>> _filteredUsers = []; // Store filtered user data
  Map<String, bool> _permissions = {}; // Store write permissions for users

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Users').get();
      List<Map<String, dynamic>> users = [];
      querySnapshot.docs.forEach((doc) {
        // Exclude the current user
        if (doc.id != widget.currentUserId) {
          users.add({
            'id': doc.id,
            'email': doc['uname'].substring(0, doc['uname'].indexOf('@'))
          });
          _permissions[doc.id] = false; // Initialize permissions to false
        }
      });
      setState(() {
        _users = users;
        _filteredUsers = users; // Initially, filtered users are the same as all users
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _filterUsers(String query) {
    final filteredUsers = _users.where((user) {
      final email = user['email'].toLowerCase();
      final search = query.toLowerCase();
      return email.contains(search);
    }).toList();

    setState(() {
      _filteredUsers = filteredUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _filterUsers(value.trim()); // Filter users as search text changes
              setState(() {
                _searchEmail = value.trim();
              });
            },
            decoration: InputDecoration(
              labelText: 'Search by Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              var user = _filteredUsers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  title: Text(
                    user['email'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Permission: ${_permissions[user['id']] == true ? 'Write' : 'No Write Access'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _permissions[user['id']] ?? false,
                        onChanged: (value) {
                          setState(() {
                            _permissions[user['id']] = value ?? false;
                          });
                        },
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.blue),
                        onPressed: () => _sendDataSharingRequest(context, user['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _sendDataSharingRequest(BuildContext context, String recipientId) async {
    try {
      String? recipientUsername = await _fetchUsername(recipientId);
      bool writeAccess = _permissions[recipientId] ?? false;

      // Create the SharedData document
      DocumentReference sharedDataRef = await FirebaseFirestore.instance.collection('SharedData').add({
        'ownerId': widget.currentUserId,
        'recipientId': recipientId,
        'companyId': widget.companyId,
        'bookIds': [], // This should be populated with relevant book IDs
        'writeAccess': writeAccess,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // If write access is granted, update the relevant books
      if (writeAccess) {
        // Fetch all books for the company
        QuerySnapshot booksSnapshot = await FirebaseFirestore.instance
            .collection('Users/${widget.currentUserId}/company_details/${widget.companyId}/Books')
            .get();

        // Update each book
        List<Future> updateFutures = booksSnapshot.docs.map((doc) {
          return doc.reference.update({
            'writeAccessUsers.$recipientId': true
          });
        }).toList();

        await Future.wait(updateFutures);

        print('Write access granted to $recipientId for all books');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data sharing request sent to ${recipientUsername ?? recipientId}')),
      );
    } catch (error) {
      print('Error in _sendDataSharingRequest: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $error')),
      );
    }
  }

  Future<String?> _fetchUsername(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      if (doc.exists) {
        String username = doc['uname']; // Get the full username
        return username.substring(0, username.indexOf('@')); // Extract email part before '@'
      }
    } catch (e) {
      print('Error fetching username: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

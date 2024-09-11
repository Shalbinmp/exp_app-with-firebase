import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Cashmove_Screen.dart';


class ViewSharedBooks extends StatefulWidget {
  @override
  _ViewSharedBooksState createState() => _ViewSharedBooksState();
}

class _ViewSharedBooksState extends State<ViewSharedBooks> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Shared Books'),
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
        ),
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text('Shared Books'),
        // Uncomment the following lines if you want to include a search functionality
        // bottom: PreferredSize(
        //   preferredSize: Size.fromHeight(48.0),
        //   child: Padding(
        //     padding: const EdgeInsets.all(8.0),
        //     child: TextField(
        //       controller: _searchController,
        //       decoration: InputDecoration(
        //         hintText: 'Search Books',
        //         prefixIcon: Icon(Icons.search),
        //         border: OutlineInputBorder(
        //           borderRadius: BorderRadius.circular(8.0),
        //         ),
        //       ),
        //       onChanged: (value) {
        //         setState(() {});
        //       },
        //     ),
        //   ),
        // ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('SharedData')
            .where('recipientId', isEqualTo: userId)
            .where('status', isEqualTo: 'approved')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No shared data available'));
          }

          // Organize shared data by ownerId
          Map<String, List<DocumentSnapshot>> sharedDataByUser = {};
          snapshot.data!.docs.forEach((doc) {
            var ownerId = doc['ownerId'];
            if (sharedDataByUser.containsKey(ownerId)) {
              sharedDataByUser[ownerId]!.add(doc);
            } else {
              sharedDataByUser[ownerId] = [doc];
            }
          });

          return ListView.builder(
            itemCount: sharedDataByUser.keys.length,
            itemBuilder: (context, index) {
              String ownerId = sharedDataByUser.keys.elementAt(index);
              List<DocumentSnapshot> sharedDataList = sharedDataByUser[ownerId]!;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Users').doc(ownerId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError) {
                    return ListTile(title: Text('Error: ${userSnapshot.error}'));
                  }

                  var userName = userSnapshot.data?.get('uname').split('@').first ?? 'Unknown User';

                  return ExpansionTile(
                    title: Text('Shared User: $userName'),
                    children: sharedDataList.map((sharedData) {
                      var companyId = sharedData['companyId'];
                      var writeAccess = sharedData['writeAccess'] ?? false; // Retrieve writeAccess field
                      if (companyId == null) {
                        return ListTile(title: Text('Invalid shared data'));
                      }

                      return Column(children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('Users')
                              .doc(ownerId)
                              .collection('company_details')
                              .doc(companyId)
                              .get(),
                          builder: (context, companySnapshot) {
                            if (companySnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (companySnapshot.hasError) {
                              return ListTile(title: Text('Error: ${companySnapshot.error}'));
                            }

                            var companyName = companySnapshot.data?.get('company_name') ?? 'Unknown Company';

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(ownerId)
                                  .collection('company_details')
                                  .doc(companyId)
                                  .collection('Books')
                                  .where('book_name', isGreaterThanOrEqualTo: _searchController.text)
                                  .where('book_name', isLessThanOrEqualTo: _searchController.text + '\uf8ff')
                                  .get(),
                              builder: (context, booksSnapshot) {
                                if (booksSnapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                if (booksSnapshot.hasError) {
                                  return ListTile(title: Text('Error: ${booksSnapshot.error}'));
                                }

                                if (!booksSnapshot.hasData || booksSnapshot.data!.docs.isEmpty) {
                                  // No books available, delete the shared data document
                                  FirebaseFirestore.instance
                                      .collection('SharedData')
                                      .doc(sharedData.id)
                                      .delete()
                                      .catchError((error) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete shared data: $error')),
                                    );
                                  });
                                  return ListTile(title: Text('No books available'));
                                }

                                return Column(
                                  children: [
                                    Text(companyName),
                                    ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: booksSnapshot.data!.docs.length,
                                      itemBuilder: (context, index) {
                                        var document = booksSnapshot.data!.docs[index];
                                        var bookData = document.data() as Map<String, dynamic>;
                                        var bookName = bookData['book_name'] ?? 'Unknown Title';
                                        var bookDate = bookData['date'] ?? 'Unknown Date';
                                        var bookTag = bookData['tag'] ?? 'Unknown Tag';

                                        return Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => Csh_Move_Screen(
                                                        book_sel_doc: document.id,
                                                        Bookname: bookName, editable: writeAccess, CurrentUserId: ownerId, UserType: 'shareduser', selectedcompany: companyId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: ListTile(
                                                  leading: CircleAvatar(
                                                    child: Icon(Icons.book, color: Colors.blue[800]),
                                                  ),
                                                  title: Text(bookName, style: TextStyle(fontWeight: FontWeight.bold)),
                                                  subtitle: Text(
                                                    'Updated on $bookDate',
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
                                                ),
                                              ),
                                            ),
                                            // Show PopupMenuButton only if writeAccess is true
                                            if (writeAccess)
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
                                                    _showEditDialog(context, bookName, bookTag, document.id, ownerId, companyId);
                                                  } else if (selectedOption == 'Delete') {
                                                    FirebaseFirestore.instance
                                                        .collection('Users')
                                                        .doc(ownerId)
                                                        .collection('company_details')
                                                        .doc(companyId)
                                                        .collection('Books')
                                                        .doc(document.id)
                                                        .delete()
                                                        .then((_) {
                                                      // Call setState to refresh the UI
                                                      setState(() {});
                                                    });
                                                  }
                                                },
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: 8.0),
                      ]);
                    }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, String bookName, String bookTag, String documentId, String ownerId, String companyId) {
    final TextEditingController _nameController = TextEditingController(text: bookName);
    final TextEditingController _tagController = TextEditingController(text: bookTag);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Book Name'),
              ),
              TextField(
                controller: _tagController,
                decoration: InputDecoration(labelText: 'Book Tag'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String updatedName = _nameController.text.trim();
                String updatedTag = _tagController.text.trim();

                if (updatedName.isNotEmpty && updatedTag.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(ownerId) // Use the correct ownerId
                        .collection('company_details')
                        .doc(companyId)
                        .collection('Books')
                        .doc(documentId)
                        .update({
                      'book_name': updatedName,
                      'tag': updatedTag,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Book updated successfully')),
                    );
                    Navigator.of(context).pop(); // Close the dialog

                    // Call setState to refresh the UI
                    setState(() {});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update book: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill out both fields')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

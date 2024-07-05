import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPostReviewScreen extends StatelessWidget {
  const AdminPostReviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Post Review'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('status', isEqualTo: 'pending') // Only fetch pending posts
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Tidak ada posting untuk direview'));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                child: ListTile(
                  title: Text(document['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: ${document['date'].toDate().toLocal().toString().split(' ')[0]}'),
                      Text('Lokasi: ${document['location']}'),
                      Text('Jenis: ${document['type']}'),
                      Text('Deskripsi: ${document['description']}'),
                      if (document['imageUrls'].isNotEmpty)
                        Image.network(document['imageUrls'][0], height: 150, fit: BoxFit.cover),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          FirebaseFirestore.instance.runTransaction((Transaction transaction) async {
                            DocumentSnapshot freshSnap = await transaction.get(document.reference);
                            transaction.update(freshSnap.reference, {'status': 'approved'});
                            print("Post approved: ${document.id}");
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance.runTransaction((Transaction transaction) async {
                            DocumentSnapshot freshSnap = await transaction.get(document.reference);
                            transaction.update(freshSnap.reference, {'status': 'rejected'});
                            print("Post rejected: ${document.id}");
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

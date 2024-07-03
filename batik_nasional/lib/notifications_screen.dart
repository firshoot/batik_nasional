import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId',
                isEqualTo: auth.FirebaseAuth.instance.currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada notifikasi.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              return ListTile(
                title: Text(document['message']),
                subtitle: Text(document['timestamp'].toDate().toString()),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

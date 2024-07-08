import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .delete();
  }

  Future<void> _deleteReport(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .delete();
  }

  Future<void> _confirmDelete(BuildContext context, String type, String id, String reportId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this $type?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                if (type == 'comment') {
                  await _deleteComment(id);
                } else if (type == 'post') {
                  await _deletePost(id);
                }
                await _deleteReport(reportId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String capitalizeFirstLetter(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Items'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var reports = snapshot.data!.docs;

          return ListView(
            children: reports.map((document) {
              var data = document.data() as Map<String, dynamic>;
              var type = data.containsKey('type') ? data['type'] : 'Unknown';
              var reason = data.containsKey('reason') ? data['reason'] : 'No reason provided';
              var reporterEmail = data.containsKey('reporterEmail') ? data['reporterEmail'] : 'Unknown';
              var postName = data.containsKey('postName') ? data['postName'] : 'Unknown';
              var id = type == 'comment' ? data['commentId'] : data['postId'];
              var reportId = document.id;

              return ListTile(
                title: Text(
                  type == 'comment'
                      ? 'Comment ID: $id'
                      : 'Post ID: $id'
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${capitalizeFirstLetter(type)}'),
                    Text('Reason: $reason'),
                    Text('Reported by: $reporterEmail'),
                    Text('Post Name: $postName'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _confirmDelete(context, type, id, reportId);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

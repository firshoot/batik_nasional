import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Stream<QuerySnapshot> _reportsStream;

  @override
  void initState() {
    super.initState();
    _reportsStream = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _handleReport(String reportId, bool deleteComment) async {
    try {
      if (deleteComment) {
        String? commentId = await _getCommentIdFromReport(reportId);

        if (commentId != null) {
          await FirebaseFirestore.instance
              .collection('comments')
              .doc(commentId)
              .delete();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Komentar telah dihapus.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Komentar tidak ditemukan.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Laporan telah dihapus.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<String?> _getCommentIdFromReport(String reportId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('reportId', isEqualTo: reportId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan dari Pengguna'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada laporan yang tersedia.'));
          }

          var reports = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var document = reports[index];
              var data = document.data() as Map<String, dynamic>;

              if (!data.containsKey('comment') ||
                  !data.containsKey('reporterEmail')) {
                return ListTile(
                  title: Text('Dokumen tidak valid'),
                  subtitle: Text('Field yang diperlukan tidak tersedia.'),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(data['comment']),
                    subtitle: Text('Dilaporkan oleh: ${data['reporterEmail']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Hapus?'),
                                content: Text(
                                    'Apakah Anda yakin ingin menghapus postingan ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Tidak'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _handleReport(document.id, true);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Ya'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.email),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Menghubungi ${data['reporterEmail']}'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

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
    // Tindakan admin berdasarkan laporan
    if (deleteComment) {
      // Ambil ID komentar yang dilaporkan dari laporan
      String? commentId = await _getCommentIdFromReport(reportId);

      if (commentId != null) {
        // Hapus komentar yang dilaporkan
        await FirebaseFirestore.instance
            .collection('comments')
            .doc(commentId)
            .delete();

        // Notifikasi kepada admin bahwa komentar telah dihapus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Komentar telah dihapus.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Jika komentar tidak ditemukan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Komentar tidak ditemukan.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    // Hapus laporan dari koleksi 'reports'
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .delete();

    // Notifikasi kepada admin bahwa laporan telah dihapus
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Laporan telah dihapus.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<String?> _getCommentIdFromReport(String reportId) async {
    // Query untuk mencari komentar berdasarkan ID laporan
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('reportId', isEqualTo: reportId)
        .get();

    // Ambil ID komentar pertama yang ditemukan
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan dari Pengguna'),
      ),
      body: StreamBuilder(
        stream: _reportsStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Tidak ada laporan yang tersedia.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              return ListTile(
                title: Text(document['comment']),
                subtitle: Text('Dilaporkan oleh: ${document['reporterEmail']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _handleReport(document.id,
                            true); // Hapus komentar yang dilaporkan
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.email),
                      onPressed: () {
                        // Tambahkan logika untuk mengirim email atau menghubungi pengguna terkait
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Menghubungi ${document['reporterEmail']}'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
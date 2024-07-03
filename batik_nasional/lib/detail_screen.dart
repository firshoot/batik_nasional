import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:batik_nasional/models/batik.dart';

class DetailScreen extends StatefulWidget {
  final Batik batik;

  const DetailScreen({Key? key, required this.batik}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isSignedIn = false;
  bool isAdmin = false;
  bool isUploader = false; // Tambahkan variabel ini
  final TextEditingController _commentController = TextEditingController();
  late String? userProfileImage;
  late String userEmail = ''; // Inisialisasi userEmail dengan nilai awal

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool signedIn = prefs.getBool('isSignedIn') ?? false;
    var user = auth.FirebaseAuth.instance.currentUser;

    if (user != null) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        isSignedIn = signedIn;
        userProfileImage = userDoc.data()?['profileImage'];
        userEmail = user.email ?? ''; // Pastikan userEmail diinisialisasi
        isAdmin = userDoc.data()?['role'] == 'admin';
        isUploader = user.uid == widget.batik.userId; // Periksa apakah pengguna adalah pengupload
      });
    }
  }

  Future<void> _postComment(String name, String comment) async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null && comment.isNotEmpty) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      var userName = userDoc.data()?['name'] ?? user.email;

      await FirebaseFirestore.instance.collection('comments').add({
        'name': name, // Menggunakan field 'name' atau 'postId' yang sesuai
        'comment': comment,
        'userName': userName,
        'userEmail': user.email,
        'profileImage': userProfileImage,
        'timestamp': Timestamp.now(),
      });

      _commentController.clear();
    }
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  Future<void> _reportComment(String commentId, String comment,
      String reporterEmail, String reason) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'commentId': commentId,
      'comment': comment,
      'reporterEmail': reporterEmail,
      'reason': reason,
      'timestamp': Timestamp.now(),
    });
    // Tambahkan logika untuk memberi notifikasi ke admin atau tindakan lain yang sesuai
    // Contoh: Menampilkan pesan bahwa komentar telah dilaporkan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Komentar telah dilaporkan.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _deletePost() async {
    // Hapus postingan dari Firestore
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.batik.id)
        .delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Postingan telah dihapus')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          widget.batik.name ?? '', // Pastikan widget.batik.name tidak null
        ),
        actions: [
          if (isAdmin || isUploader) // Tampilkan tombol hapus hanya untuk admin atau pengupload
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Konfirmasi'),
                    content: Text('Apakah Anda yakin ingin menghapus postingan ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _deletePost();
                        },
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: widget.batik.imageUrls != null &&
                            widget.batik.imageUrls!.isNotEmpty
                        ? Container(
                            height: 300,
                            child: PageView.builder(
                              itemCount: widget.batik.imageUrls!.length,
                              itemBuilder: (context, index) {
                                return Image.network(
                                  widget.batik.imageUrls![index],
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          )
                        : Container(
                            height: 300,
                            width: double.infinity,
                            color: Colors.grey,
                            child: const Center(child: Text('No Image')),
                          ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget.batik.name ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 70,
                        child: Text(
                          'Lokasi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(' : ${widget.batik.location ?? ''}')
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 70,
                        child: Text(
                          'Dibangun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(' : ${widget.batik.built ?? ''}')
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.house,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 70,
                        child: Text(
                          'Tipe',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(' : ${widget.batik.type ?? ''}')
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.blue.shade200),
                  const SizedBox(height: 8),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.batik.description ?? ''),
                  const SizedBox(height: 16),
                  Divider(color: Colors.blue.shade200),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('comments')
                        .where('name', isEqualTo: widget.batik.name)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Column(
                        children: snapshot.data!.docs.map((document) {
                          String profileImage = document['profileImage'] ?? '';
                          bool isCommentOwner =
                              document['userEmail'] == userEmail;
                          bool canDelete = isAdmin || isCommentOwner;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: profileImage.isNotEmpty
                                  ? NetworkImage(profileImage)
                                  : null,
                              child: profileImage.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(document['comment']),
                            subtitle: Text('By: ${document['userName']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.flag),
                                  onPressed: () {
                                    // Tampilkan dialog laporkan komentar
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Laporkan Komentar'),
                                        content: TextField(
                                          decoration: const InputDecoration(
                                            hintText: 'Alasan pelaporan...',
                                          ),
                                          minLines: 3,
                                          maxLines: 5,
                                          onChanged: (value) {
                                            // Tambahan untuk menyimpan alasan pelaporan
                                          },
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              // Kirim laporan
                                              _reportComment(
                                                document.id,
                                                document['comment'],
                                                userEmail,
                                                '', // Ganti dengan state untuk alasan pelaporan
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Laporkan'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _deleteComment(document.id);
                                    },
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  isSignedIn
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                _postComment(widget.batik.name ?? '',
                                    _commentController.text);
                              },
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            'Sign in to post comments',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                  const SizedBox(height: 8),
                  // Tombol "Tambah Komentar"
                  ElevatedButton(
                    onPressed: () {
                      // Tambahkan logika untuk menampilkan dialog atau action sheet
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Tambah Komentar'),
                          content: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan komentar',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Tutup dialog
                              },
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _postComment(
                                  widget.batik.name ?? '',
                                  _commentController.text,
                                );
                                Navigator.of(context).pop(); // Tutup dialog
                              },
                              child: const Text('Tambah'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Tambah Komentar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

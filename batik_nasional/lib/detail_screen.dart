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
  bool isUploader = false;
  bool isFavorite = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _reportReasonController = TextEditingController();
  late String? userProfileImage;
  late String userEmail = '';

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
    _checkIfFavorite(); // Load status favorit saat inisialisasi
    _loadLocalFavorites(); // Load favorit lokal dari SharedPreferences
    print("Batik ID in initState: ${widget.batik.id}");
  }

  Future<void> _loadLocalFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? localFavorites = prefs.getStringList('favoriteBatikIds');

    if (localFavorites != null) {
      setState(() {
        isFavorite = localFavorites.contains(widget.batik.id);
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(user.uid);
      var favoriteDoc = await favoritesRef.get();

      if (favoriteDoc.exists) {
        List<String> batikIds = List<String>.from(favoriteDoc.data()?['batiks'] ?? []);
        setState(() {
          isFavorite = batikIds.contains(widget.batik.id);
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(user.uid);

      if (isFavorite) {
        // Remove from favorites
        await favoritesRef.update({
          'batiks': FieldValue.arrayRemove([widget.batik.id]),
        });
      } else {
        // Add to favorites
        await favoritesRef.set({
          'batiks': FieldValue.arrayUnion([widget.batik.id]),
        }, SetOptions(merge: true));
      }

      setState(() {
        isFavorite = !isFavorite;
      });
    }
  }

  void _showRemoveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text('Are you sure you want to remove this from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              _toggleFavorite();
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
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
        userEmail = user.email ?? '';
        isUploader = user.uid == widget.batik.userId;

        print("Current User ID: ${user.uid}");
        print("Uploader User ID: ${widget.batik.userId}");
        print("Is Uploader: $isUploader");
      });
    } else {
      setState(() {
        isSignedIn = false;
        isUploader = false;
        print("User not signed in");
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
        'name': name,
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

Future<void> _reportComment(String commentId, String reason) async {
  var user = auth.FirebaseAuth.instance.currentUser;
  if (user != null && reason.isNotEmpty) {
    await FirebaseFirestore.instance.collection('reports').add({
      'type': 'comment',
      'commentId': commentId,
      'reason': reason,
      'reporterEmail': user.email,
      'timestamp': Timestamp.now(),
      'postName': widget.batik.name,
    });

    _reportReasonController.clear();
  }
}

  Future<void> _reportPost(String reason) async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null && reason.isNotEmpty) {
      print("Reporting Post ID: ${widget.batik.id}");
      await FirebaseFirestore.instance.collection('reports').add({
        'type': 'post',
        'postId': widget.batik.id,
        'postName': widget.batik.name,
        'reason': reason,
        'reporterEmail': user.email,
        'timestamp': Timestamp.now(),
      });

      _reportReasonController.clear();
    }
  }

  void _showReportDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Komentar'),
        content: TextField(
          controller: _reportReasonController,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan report',
          ),
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
              _reportComment(commentId, _reportReasonController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Laporkan'),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    print("Batik ID in build: ${widget.batik.id}");
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.batik.name ?? ''),
        actions: [
          IconButton(
            
            icon: const Icon(Icons.flag),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Report Post'),
                  content: TextField(
                    controller: _reportReasonController,
                    decoration: const InputDecoration(
                      hintText: 'Enter reason for reporting',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _reportPost(_reportReasonController.text);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              );
            },
          ),
IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            color: isFavorite ? Colors.red : null,
            onPressed: _toggleFavorite,
          ),
          if (isUploader)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi'),
                    content: const Text('Apakah Anda yakin ingin menghapus postingan ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Fungsi untuk menghapus postingan
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Hapus'),
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
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.place,
          color: Colors.red,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lokasi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4), // Adjust height for better spacing
          ],
        ),
        const SizedBox(width: 36),
        const Text(':'),
        const SizedBox(width: 8),
        Expanded(
          child: Text(widget.batik.location ?? ''),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 8),
        const Text(':'),
        const SizedBox(width: 8),
        Flexible(
          child: Text(widget.batik.built ?? ''),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 8),
        const Text(':'),
        const SizedBox(width: 8),
        Flexible(
          child: Text(widget.batik.type ?? ''),
        ),
      ],
    ),
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
                      var comments = snapshot.data!.docs;

                      return ListView(
                        shrinkWrap: true,
                        children: comments.map((document) {
                          bool canDelete = document['userEmail'] == userEmail;
                          var profileImage = document['profileImage'] ?? '';
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
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Report Comment'),
                                        content: TextField(
                                          controller: _reportReasonController,
                                          decoration: const InputDecoration(
                                            hintText: 'Enter reason for reporting',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _reportComment(document.id, _reportReasonController.text);
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Submit'),
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
                        ): 
                        const Center(
                        ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
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
                                Navigator.of(context).pop();
                              },
                              child: const Text('Batal'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _postComment(
                                  widget.batik.name ?? '',
                                  _commentController.text,
                                );
                                Navigator.of(context).pop();
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

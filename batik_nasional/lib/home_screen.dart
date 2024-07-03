import 'package:batik_nasional/admin_post_review_screen.dart';
import 'package:batik_nasional/profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_post_screen.dart';
import 'sign_in_screen.dart';

class Batik {
  final String name;
  final String imageAsset;
  final String location;
  final String built;
  final String type;
  final String description;
  final List<String> imageUrls;

  Batik({
    required this.name,
    required this.imageAsset,
    required this.location,
    required this.built,
    required this.type,
    required this.description,
    required this.imageUrls,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<void> signOut(BuildContext context) async {
    await auth.FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()));
  }

  Future<void> deletePost(DocumentSnapshot document) async {
    await FirebaseFirestore.instance
        .runTransaction((Transaction transaction) async {
      await transaction.delete(document.reference);
    });
  }

  Future<bool> isAdmin() async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == 'admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (query) {
                // Implement search functionality
              },
            ),
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: const Text('Menu'),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            FutureBuilder<bool>(
              future: isAdmin(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text('Loading...'),
                  );
                }
                if (snapshot.hasData && snapshot.data!) {
                  return ListTile(
                    title: const Text('Admin Post Review'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => AdminPostReviewScreen()));
                    },
                  );
                }
                return Container(); // Return an empty container if the user is not an admin
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                signOut(context);
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'approved')
          .orderBy('timestamp', descending: true)
          .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            print("No Data Available");
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Postingan Masih Kosong'));
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              List<String> imageUrls = List<String>.from(document['imageUrls']);
              String firstImageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

              return Card(
                margin: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    ListTile(
                      title: Text(document['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tanggal: ${document['date'].toDate().toLocal().toString().split(' ')[0]}'),
                          Text('Lokasi: ${document['location']}'),
                          Text('Jenis: ${document['type']}'),
                          Text('Deskripsi: ${document['description']}'),
                          firstImageUrl.isNotEmpty
                            ? Image.network(
                                firstImageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            batik: Batik(
                              name: document['name'],
                              imageAsset: firstImageUrl,
                              location: document['location'],
                              built: document['date'].toDate().toLocal().toString().split(' ')[0],
                              type: document['type'],
                              description: document['description'],
                              imageUrls: imageUrls,
                            ),
                          ),
                        ));
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          deletePost(document);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => AddPostScreen()));
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}

class DetailScreen extends StatefulWidget {
  final Batik batik;

  const DetailScreen({Key? key, required this.batik}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isSignedIn = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool signedIn = prefs.getBool('isSignedIn') ?? false;

    setState(() {
      isSignedIn = signedIn;
    });
  }

  Future<void> _postComment(String postId, String comment) async {
    if (comment.isNotEmpty) {
      await FirebaseFirestore.instance.collection('comments').add({
        'postId': postId,
        'comment': comment,
        'timestamp': Timestamp.now(),
      });

      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.batik.name),
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
                    child: widget.batik.imageUrls.isNotEmpty
                        ? Container(
                            height: 300,
                            child: PageView.builder(
                              itemCount: widget.batik.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Image.network(
                                  widget.batik.imageUrls[index],
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
                  Text(
                    widget.batik.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.batik.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(widget.batik.location),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(widget.batik.built),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(widget.batik.type),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('comments')
                        .where('postId', isEqualTo: widget.batik.name)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      var comments = snapshot.data!.docs;

                      if (comments.isEmpty) {
                        return const Text('No comments yet.');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          var comment = comments[index];
                          return ListTile(
                            title: Text(comment['comment']),
                            subtitle: Text(
                                comment['timestamp'].toDate().toString()),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (isSignedIn)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration:
                                const InputDecoration(hintText: 'Add a comment'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            _postComment(widget.batik.name, _commentController.text);
                          },
                        ),
                      ],
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

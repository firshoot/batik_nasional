import 'package:batik_nasional/admin_sign_up.dart';
import 'package:batik_nasional/favorite.dart';
import 'package:batik_nasional/itemcard.dart';
import 'package:batik_nasional/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:batik_nasional/models/batik.dart';
import 'package:batik_nasional/admin_post_review_screen.dart';
import 'package:batik_nasional/profile.dart';
import 'package:batik_nasional/add_post_screen.dart';
import 'package:batik_nasional/sign_in_screen.dart';
import 'package:batik_nasional/detail_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> signOut(BuildContext context) async {
    await auth.FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()));
  }

  Future<void> deletePost(DocumentSnapshot document) async {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      await transaction.delete(document.reference);
    });
  }

  Future<bool> isAdmin() async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.exists && doc.data()?['role'] == 'admin';
    }
    return false;
  }

  Future<void> sendNotification(String message) async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'message': message,
        'timestamp': Timestamp.now(),
      });
    }
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
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
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
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AdminPostReviewScreen()));
                    },
                  );
                }
                return Container(); // Return an empty container if the user is not an admin
              },
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
                    title: const Text('Admin Sign Up'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => AdminSignUpScreen()));
                    },
                  );
                }
                return Container(); // Return an empty container if the user is not an admin
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () {
                signOut(context);
              },
            ),
                  ListTile(
        title: const Text('Favorites'),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => FavoriteScreen())); // Implement FavoritesScreen
        },
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
                    title: const Text('Laporan'),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ReportScreen()));
                    },
                  );
                }
                return Container(); // Return an empty container if the user is not an admin
              },
            ),
            ListTile(
              title: const Text('Notifikasi'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => NotificationScreen(),
                ));
              },
            ),
          ],
        ),
      ),
      body: PostList(searchQuery: _searchQuery),
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

class PostList extends StatelessWidget {
  final String searchQuery;

  const PostList({Key? key, required this.searchQuery}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('status', isEqualTo: 'approved')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print("Error: ${snapshot.error}");
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          print("No Data Available");
          return Center(child: CircularProgressIndicator());
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          var name = doc['name'].toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          var query = searchQuery.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          return name.contains(query);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(child: Text('Postingan Tidak Ditemukan'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            var document = filteredDocs[index];
            List<String> imageUrls = List<String>.from(document['imageUrls']);
            String firstImageUrl = imageUrls.isNotEmpty ? imageUrls[0] : '';

            return GestureDetector(
              onTap: () {
                var batik = Batik(
                  id: document.id,  // Menginisialisasi ID dokumen
                  name: document['name'],
                  location: document['location'],
                  built: document['date'].toDate().toLocal().toString().split(' ')[0],
                  type: document['type'],
                  description: document['description'],
                  imageUrls: imageUrls,
                  userId: document['userId'],  // Pastikan userId diinisialisasi
                );
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => DetailScreen(batik: batik),
                ));
              },
              child: ItemCard(
                name: document['name'],
                date: document['date'].toDate().toLocal().toString().split(' ')[0],
                imageUrl: firstImageUrl,
              ),
            );
          },
        );
      },
    );
  }
}
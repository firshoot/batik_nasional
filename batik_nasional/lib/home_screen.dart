import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:batik_nasional/add_post_screen.dart'; // Import AddPostScreen
import 'package:batik_nasional/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              signOut(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((document) {
              return Card(
                margin: EdgeInsets.all(10),
                child: Stack(
                  children: [
                    ListTile(
                      title: Text(document['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Tanggal: ${document['date'].toDate().toLocal().toString().split(' ')[0]}'),
                          Text('Lokasi: ${document['location']}'),
                          Text('Jenis: ${document['type']}'),
                          Text('Deskripsi: ${document['description']}'),
                          document['imageUrl'] != null
                              ? Image.network(document['imageUrl'])
                              : Container(),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            batik: Batik(
                              name: document['name'],
                              imageAsset: document['imageUrl'],
                              location: document['location'],
                              built: document['date']
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0],
                              type: document['type'],
                              description: document['description'],
                              imageUrls: [
                                document['imageUrl']
                              ], // Adjust this as needed
                            ),
                            updateFavorites: (favorites) {
                              // Implement your update logic here
                            },
                          ),
                        ));
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
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
  final void Function(Set<String>)? updateFavorites;

  const DetailScreen({Key? key, required this.batik, this.updateFavorites})
      : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool isSignedIn = false;
  bool _isFavorite = false;
  late Set<String> favoritebatiks = <String>{};

  void _checkSignInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool signedIn = prefs.getBool('isSignedIn') ?? false;

    setState(() {
      isSignedIn = signedIn;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
    _loadFavouriteStatus();
  }

  Future<void> _loadFavouriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool favorite = prefs.getBool('favorite_${widget.batik.name}') ?? false;

    setState(() {
      _isFavorite = favorite;
      favoritebatiks =
          prefs.getStringList('favoritebatiks')?.toSet() ?? <String>{};
    });
  }

  Future<void> _toggleFavorite() async {
    bool isFavorite = !_isFavorite;
    await _saveFavoriteStatus(isFavorite);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _saveFavoriteStatus(bool isFavorite) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String batikName = widget.batik.name;

    if (isFavorite) {
      favoritebatiks.add(batikName);
    } else {
      favoritebatiks.remove(batikName);
    }

    await prefs.setStringList('favoritebatiks', favoritebatiks.toList());
    await prefs.setBool('favorite_$batikName', isFavorite);

    // Beritahu widget induk (HomeScreen) bahwa ada perubahan pada daftar favorit
    if (widget.updateFavorites != null) {
      widget.updateFavorites!(favoritebatiks);
    }
  }

  Future<void> _removeFromFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String batikName = widget.batik.name;

    if (favoritebatiks.contains(batikName)) {
      favoritebatiks.remove(batikName);
      await prefs.setStringList('favoritebatiks', favoritebatiks.toList());
      await prefs.remove('favorite_$batikName');

      // Beritahu widget induk (HomeScreen) bahwa ada perubahan pada daftar favorit
      if (widget.updateFavorites != null) {
        widget.updateFavorites!(favoritebatiks);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      widget.batik.imageAsset,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.batik.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              _toggleFavorite();
                            },
                            icon: Icon(
                              isSignedIn && _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                            color:
                                isSignedIn && _isFavorite ? Colors.red : null,
                          ),
                          IconButton(
                            onPressed: () {
                              _removeFromFavorites();
                            },
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                      Text(' : ${widget.batik.location}')
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
                      Text(' : ${widget.batik.built}')
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
                      Text(' : ${widget.batik.type}')
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
                  Text(widget.batik.description),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.blue.shade100),
                  const Text(
                    'Galeri',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.batik.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {},
                            child: Container(
                              decoration: BoxDecoration(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: widget.batik.imageUrls[index],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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

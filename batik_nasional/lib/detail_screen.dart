import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Batik {
  final String name;
  final String location;
  final String built;
  final String type;
  final String description;

  Batik({
    required this.name,
    required this.location,
    required this.built,
    required this.type,
    required this.description,
  });
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget.batik.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
          ],
        ),
      ),
    );
  }
}

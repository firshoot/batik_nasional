import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:batik_nasional/models/batik.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Batik> favoriteBatiks = [];

  @override
  void initState() {
    super.initState();
    _fetchFavoriteBatiks();
  }

  Future<void> _fetchFavoriteBatiks() async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(user.uid);
      var favoriteDoc = await favoritesRef.get();

      List<String> batikIds = [];
      if (favoriteDoc.exists) {
        batikIds = List<String>.from(favoriteDoc.data()?['batiks'] ?? []);
      }

      List<Batik> batiks = [];
      for (String batikId in batikIds) {
        var batikDoc = await FirebaseFirestore.instance.collection('batiks').doc(batikId).get();
        if (batikDoc.exists) {
          batiks.add(Batik.fromFirestore(batikDoc, batikDoc.id));
        }
      }

      if (mounted) {
        setState(() {
          favoriteBatiks = batiks;
        });
      }
    }
  }

  Future<void> _removeFromFavorites(String batikId) async {
    var user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      var favoritesRef = FirebaseFirestore.instance.collection('favorites').doc(user.uid);

      await favoritesRef.update({
        'batiks': FieldValue.arrayRemove([batikId]),
      });

      if (mounted) {
        setState(() {
          favoriteBatiks.removeWhere((batik) => batik.id == batikId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: ListView.builder(
        itemCount: favoriteBatiks.length,
        itemBuilder: (context, index) {
          var batik = favoriteBatiks[index];
          return ListTile(
            title: Text(batik.name ?? ''),
            subtitle: Text(batik.location ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () {
                _showRemoveDialog(batik.id!);
              },
            ),
          );
        },
      ),
    );
  }

  void _showRemoveDialog(String batikId) {
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
              _removeFromFavorites(batikId);
              Navigator.of(context).pop();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Batik {
  final String? id;
  final String? name;
  final String? imageAsset; 
  final String? location;
  final String? built;
  final String? type;
  final String? description;
  final List<String>? imageUrls;
  final String? userId;

  Batik({
    this.id,
    this.name,
    this.imageAsset,
    this.location,
    this.built,
    this.type,
    this.description,
    this.imageUrls,
    this.userId,
  });

  factory Batik.fromFirestore(DocumentSnapshot doc, String id) {
    var data = doc.data() as Map<String, dynamic>?; // Handle null data
    if (data == null) {
      return Batik(
        id: id,
        name: '',
        imageAsset: '',
        location: '',
        built: '',
        type: '',
        description: '',
        imageUrls: [],
        userId: '',
      );
    }

    return Batik(
      id: id,
      name: data['name'] ?? '',
      imageAsset: data['imageAsset'] ?? '',
      location: data['location'] ?? '',
      built: data['built'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userId: data['userId'] ?? '',
    );
  }
}

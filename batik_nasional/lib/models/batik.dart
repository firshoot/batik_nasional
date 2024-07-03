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
  final String? userId; // Tambahkan properti ini

  Batik({
    this.id,
    this.name,
    this.imageAsset,
    this.location,
    this.built,
    this.type,
    this.description,
    this.imageUrls,
    this.userId, // Tambahkan properti ini ke konstruktor
  });

  // Metode untuk mengonversi dari Map ke Batik
  factory Batik.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Batik(
      id: doc.id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      built: data['built'] ?? '',
      type: data['type'] ?? '',
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      userId: data['userId'] ?? '', // Inisialisasi properti ini
    );
  }
}
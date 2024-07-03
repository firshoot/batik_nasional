import 'package:flutter/material.dart';

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

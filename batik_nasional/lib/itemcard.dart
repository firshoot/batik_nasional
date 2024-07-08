import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String name;
  final String date;
  final String imageUrl;

  const ItemCard({
    Key? key,
    required this.name,
    required this.date,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

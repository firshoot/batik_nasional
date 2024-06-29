import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  DateTime? _date;
  String _location = '';
  String _type = 'Modern';
  String _description = '';
  File? _image;

  final picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Pilih Sumber',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Galeri"),
              onTap: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Kamera"),
              onTap: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPost() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Upload image to Firebase Storage
      String? imageUrl;
      if (_image != null) {
        final storageRef = FirebaseStorage.instance.ref().child('batik_images').child(DateTime.now().toIso8601String());
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Save post data to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'name': _name,
        'date': _date,
        'location': _location,
        'type': _type,
        'description': _description,
        'imageUrl': imageUrl ?? '',
        'timestamp': Timestamp.now(),
      });

      // Show success message and clear form
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post added successfully')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama Batik'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name of the batik';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Tanggal Pembuatan'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the date';
                  }
                  return null;
                },
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _date = pickedDate;
                    });
                  }
                },
                readOnly: true,
                controller: TextEditingController(text: _date == null ? '' : _date!.toLocal().toString().split(' ')[0]),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Lokasi'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the location';
                  }
                  return null;
                },
                onSaved: (value) {
                  _location = value!;
                },
              ),
              DropdownButtonFormField(
                decoration: InputDecoration(labelText: 'Jenis Batik'),
                value: _type,
                items: ['Modern', 'Tradisional'].map((String type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _type = newValue!;
                  });
                },
                onSaved: (newValue) {
                  _type = newValue!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Deskripsi'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 20),
              _image == null
                  ? Text('No image selected.')
                  : Image.file(_image!, height: 200, width: 200),
              ElevatedButton(
                onPressed: _showPicker,
                child: Text('Pick Image'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitPost,
                child: Text('Submit Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

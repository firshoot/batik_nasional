import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isLoading = false; // Tambahkan variabel isLoading

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
    try {
      if (_formKey.currentState != null && _formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        setState(() {
          _isLoading = true; // Set isLoading ke true saat memulai proses
        });

        // Upload image to Firebase Storage
        String? imageUrl;
        if (_image != null) {
          final storageRef = FirebaseStorage.instance.ref().child('batik_images').child(DateTime.now().toIso8601String());
          await storageRef.putFile(_image!);
          imageUrl = await storageRef.getDownloadURL();
        }

        // Save post data to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('User is not authenticated');
        }

        await FirebaseFirestore.instance.collection('posts').add({
          'name': _name,
          'date': _date,
          'location': _location,
          'type': _type,
          'description': _description,
          'imageUrl': imageUrl ?? '',
          'timestamp': Timestamp.now(),
          'userId': user.uid,
        });

        // Reset form and show success message
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post added successfully')));
        Navigator.of(context).pop();

        setState(() {
          _isLoading = false; // Set isLoading kembali ke false setelah selesai
        });
      }
    } catch (e) {
      print('Error submitting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      setState(() {
        _isLoading = false; // Pastikan isLoading kembali ke false jika terjadi kesalahan
      });
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
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitPost,
                icon: _isLoading ? CircularProgressIndicator() : Icon(Icons.upload),
                label: Text(_isLoading ? 'Posting...' : 'Submit Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

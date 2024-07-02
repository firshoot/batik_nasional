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
  List<File> _images = [];
  bool _isLoading = false;

  final picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    try {
      List<XFile>? pickedFiles = await picker.pickMultiImage(
        maxWidth: 1920, // optional, set maximum width of image picked
        maxHeight: 1080, // optional, set maximum height of image picked
        imageQuality: 80, // optional, set the quality of image picked
      );
      
      if (pickedFiles != null) {
        if (_images.length + pickedFiles.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maximum 10 images allowed')),
          );
          return;
        }

        setState(() {
          _images.addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)).toList());
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_images.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum 10 images allowed')),
        );
        return;
      }

      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
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
                _takePicture();
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
        if (_images.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gambar Tidak Boleh Kosong')),
          );
          return;
        }

        _formKey.currentState!.save();

        setState(() {
          _isLoading = true;
        });

        List<String> imageUrls = [];
        for (var image in _images) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('batik_images')
              .child(DateTime.now().toIso8601String() + '_' + image.path.split('/').last);
          await storageRef.putFile(image);
          final imageUrl = await storageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }

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
          'imageUrls': imageUrls,
          'timestamp': Timestamp.now(),
          'userId': user.uid,
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Post added successfully')));
        Navigator.of(context).pop();

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error submitting post: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
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
              GestureDetector(
                onTap: _showPicker,
                child: Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: _images.isEmpty
                      ? Center(child: Text('Tekan untuk memilih metode pengambilan gambar'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                children: [
                                  Image.file(
                                    _images[index],
                                    fit: BoxFit.cover,
                                    width: 150,
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        color: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama Batik'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama Tidak Boleh Kosong';
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
                    return 'Tanggal Tidak Boleh Kosong';
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
                controller: TextEditingController(
                    text: _date == null
                        ? ''
                        : _date!.toLocal().toString().split(' ')[0]),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Lokasi'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi Tidak Boleh Kosong';
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
                    return 'Deskripsi Tidak Boleh Kosong';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text(_isLoading ? 'Posting...' : 'Submit Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

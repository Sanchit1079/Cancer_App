import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;  // Added this import
import 'dart:io';
import 'result_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _image;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  Future<void> _uploadAndProcess() async {
    if (_formKey.currentState!.validate() && _image != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now().toString()}_${_nameController.text}');
        
        await storageRef.putFile(_image!);
        final imageUrl = await storageRef.getDownloadURL();

        // Make API call to your ML backend
        // Replace with your actual API endpoint
        final response = await http.post(
          Uri.parse('YOUR_BACKEND_API_ENDPOINT'),
          body: {'image_url': imageUrl},
        );

        if (!mounted) return;

        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              result: response.body,
              imageUrl: imageUrl,
              patientName: _nameController.text,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_image != null)
                Image.file(
                  _image!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadAndProcess,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Upload and Process'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

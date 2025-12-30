import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FaceRecognition extends StatefulWidget {
  const FaceRecognition({super.key});

  @override
  State<FaceRecognition> createState() => _FaceRecognitionState();
}

class _FaceRecognitionState extends State<FaceRecognition> {
  File? _imageFile;
  bool _loading = false;
  String? _lastResult;

  final String serverUrl = "http://10.240.68.145:5000/recognize";  // Ganti IP server awak

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _lastResult = null; // reset previous result
        });
      }
    } catch (e) {
      showMessage("Failed to pick image: $e");
    }
  }

  Future<void> recognizeFace() async {
    if (_imageFile == null) {
      showMessage("Please capture your face first");
      return;
    }

    setState(() {
      _loading = true;
      _lastResult = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse(serverUrl))
        ..files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      setState(() {
        _loading = false;
      });

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['status'] == 'success') {
          setState(() {
            _lastResult = "Success! Recognized: ${data['name']}";
          });
          _showResultDialog("Success", "Face recognized: ${data['name']}");
        } else {
          setState(() {
            _lastResult = "Failed: ${data['message']}";
          });
          _showResultDialog("Failed", data['message'] ?? "Unknown face");
        }
      } else {
        _showResultDialog("Error", "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showResultDialog("Error", "Unexpected error: $e");
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else {
      return const Center(
        child: Icon(Icons.face_retouching_natural, size: 80, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance (Face)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sila hadapkan muka anda ke kamera',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 20),
            if (_lastResult != null)
              Text(
                _lastResult!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text("Capture Face"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: recognizeFace,
                        icon: const Icon(Icons.face),
                        label: const Text("Recognize"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

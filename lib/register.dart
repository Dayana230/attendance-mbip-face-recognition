import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  File? _imageFile;
  bool isLoading = false;

  static const String apiBaseUrl = "http://10.240.68.145:5000"; // ✅ UPDATED IP

  void showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // =====================
  // PICK IMAGE
  // =====================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // =====================
  // REGISTER
  // =====================
  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (_imageFile == null) {
      showMessage("Please capture your face");
      return;
    }

    if (password != confirm) {
      showMessage("Passwords do not match");
      return;
    }

    if (password.length < 6) {
      showMessage("Password must be at least 6 characters");
      return;
    }

    setState(() => isLoading = true);

    try {
      // =====================
      // 1️⃣ UPLOAD FACE FIRST
      // =====================
      print("📤 Uploading face to: $apiBaseUrl/register_face");
      final uri = Uri.parse("$apiBaseUrl/register_face");
      final request = http.MultipartRequest('POST', uri)
        ..fields['name'] = name
        ..files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print("📡 Response: ${response.statusCode}");
      print("📡 Body: $responseBody");

      if (response.statusCode != 200) {
        showMessage("Face registration failed: $responseBody");
        setState(() => isLoading = false);
        return;
      }

      // =====================
      // 2️⃣ CREATE FIREBASE USER
      // =====================
      print("🔥 Creating Firebase user...");
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      print("✅ User created: ${userCredential.user?.displayName}");

      // =====================
      // SUCCESS POPUP
      // =====================
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Registration completed"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase error: ${e.message}");
      showMessage(e.message ?? "Firebase error");
    } catch (e) {
      print("❌ Unexpected error: $e");
      showMessage("Unexpected error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // =====================
  // UI
  // =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset('assets/MBIP.png', height: 200),

              const SizedBox(height: 24),
              Text("Register",
                  style: Theme.of(context).textTheme.headlineMedium),

              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
              ),

              const SizedBox(height: 16),
              _imageFile == null
                  ? const Text("No image selected")
                  : Image.file(_imageFile!, height: 150),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Capture Face"),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : register,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
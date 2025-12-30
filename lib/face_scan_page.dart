import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'scanresultpage.dart';

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);

    try {
      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("❌ Camera init error: $e");
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Camera Error"),
          content: Text("Failed to initialize camera: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndSendImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("📸 Capturing image...");
      final image = await _controller!.takePicture();
      
      final url = 'http://10.240.68.145:5000/recognize';
      print("🌐 Sending to: $url");
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final resBody = await response.stream.bytesToString();

      print("📡 Response Status: ${response.statusCode}");
      print("📡 Response Body: $resBody");

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        if (data['status'] == 'success' && data['name'] != null) {
          print("✅ Face recognized: ${data['name']}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanResultPage(name: data['name']),
            ),
          );
        } else {
          print("❌ Face not recognized: ${data['message']}");
          _showError("Muka Tidak Dikenali", data['message'] ?? "Sila cuba lagi.");
        }
      } else if (response.statusCode == 403) {
        _showError("Scan Disabled", "Admin has disabled face scanning. Please try again later.");
      } else {
        _showError("Server Error", "Kod: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        _isLoading = false;
      });
      _showError("Connection Error", "Cannot connect to server. Make sure:\n1. Flask is running\n2. Phone and laptop on same WiFi\n\nError: $e");
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Attendance")),
      body: _isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(_controller!),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            "Recognizing face...",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: FloatingActionButton.extended(
                      onPressed: _isLoading ? null : _captureAndSendImage,
                      icon: const Icon(Icons.camera),
                      label: const Text("Capture"),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
import 'package:flutter/material.dart';

class ScanResultPage extends StatelessWidget {
  final String name;
  const ScanResultPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            Text(
              "Tahniah $name!",
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Kerana hadir ke Program Mengaji MBIP",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton( 
              onPressed: () => Navigator.pop(context),
              child: const Text("Kembali ke Kamera"),
            ),
          ],
        ),
      ),
    );
  }
}

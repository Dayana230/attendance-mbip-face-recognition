import 'package:attendance_mbip/face_scan_page.dart';
import 'package:attendance_mbip/attendance_history_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? user?.email ?? 'User'; // Boleh tukar ke displayName kalau guna nama

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance MBIP'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //welcome user
            Text('Welcome, $name',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),

            //date
            Text(
              '📅 Date: ${DateTime.now().toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),

            //scan attendance
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FaceScanPage()),
              );
                },
                child: Text('Scan Attendance (Face)'),
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AttendanceHistoryPage()),
                );
                  },
                  child: const Text('View Attendance History'),
                ),
          ],
        ),
      ),
    );
  }
}

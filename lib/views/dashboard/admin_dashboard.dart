import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "Hoş geldin Admin!",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Abonelik Süresi Doldu")),
      body: const Center(
        child: Text(
          "Bu firmanın abonelik süresi sona ermiştir.\nLütfen yönetici ile iletişime geçin.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الأدمن')),
      body: const Center(
        child: Text('إضافة الأسئلة من Firebase لاحقاً'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No messages yet.\nYour chat and alerts will appear here.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

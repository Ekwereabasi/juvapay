import 'package:flutter/material.dart';

class MyChatsView extends StatelessWidget {
  const MyChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Chats')),
      body: const Center(child: Text('Content for User chats')),
    );
  }
} 
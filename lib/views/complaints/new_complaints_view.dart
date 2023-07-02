import 'package:flutter/material.dart';

class NewComplaintView extends StatefulWidget {
  const NewComplaintView({super.key});

  @override
  State<NewComplaintView> createState() => _NewComplaintViewState();
}

class _NewComplaintViewState extends State<NewComplaintView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Complaints'),
      ),
      body: const Text('Lodge your complaints here....'),
    );
  }
}

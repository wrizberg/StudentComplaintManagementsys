import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:studentcomplainmanagementsys/services/auth/auth_service.dart';
import 'package:studentcomplainmanagementsys/services/crud/complaints_service.dart';

class NewComplaintView extends StatefulWidget {
  const NewComplaintView({super.key});

  @override
  State<NewComplaintView> createState() => _NewComplaintViewState();
}

class _NewComplaintViewState extends State<NewComplaintView> {
  DatabaseComplaints? _complaints;
  late final ComplaintsService _complaintsService;
  late final TextEditingController _textController;

  @override
  void initState() {
    _complaintsService = ComplaintsService();
    _textController = TextEditingController();
    super.initState();
  }

  void _textControllerListener() async {
    final complaint = _complaints;
    if (complaint == null) {
      return;
    }
    final text = _textController.text;
    await _complaintsService.updateComplaints(
      complaints: complaint,
      text: text,
    );
  }

  void _setupTextControllerListener() {
    _textController.removeListener(_textControllerListener);
    _textController.addListener(_textControllerListener);
  }

  Future<DatabaseComplaints> createNewComplaint() async {
    final existingComplaint = _complaints;
    if (existingComplaint != null) {
      return existingComplaint;
    }
    final currentUser = AuthService.firebase().currentUser!;
    final email = currentUser.email!;
    final owner = await _complaintsService.getUser(email: email);
    return await _complaintsService.createComplaint(owner: owner);
  }

  void _deleteComplaintIfTextIsEmpty() {
    final complaint = _complaints;
    if (_textController.text.isEmpty && complaint != null) {
      _complaintsService.deleteComplaint(id: complaint.id);
    }
  }

  void _saveComplaintIfTextNotEmpty() async {
    final complaint = _complaints;
    final text = _textController.text;
    if (complaint != null && text.isNotEmpty) {
      await _complaintsService.updateComplaints(
        complaints: complaint,
        text: text,
      );
    }
  }

  @override
  void dispose() {
    _deleteComplaintIfTextIsEmpty();
    _saveComplaintIfTextNotEmpty();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Complaints'),
      ),
      body: FutureBuilder(
        future: createNewComplaint(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              _complaints = snapshot.data as DatabaseComplaints;
              _setupTextControllerListener();
              return TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'start typing your complaints',
                ),
              );

            default:
              return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:codepad_app/models/paste.dart';
import 'package:codepad_app/widgets/code_editor_box.dart';
import 'package:codepad_app/services/paste_service.dart';

class ViewPasteScreen extends StatelessWidget {
  final Paste paste;
  final Function(Paste)? onEdit;

  const ViewPasteScreen({
    super.key,
    required this.paste,
    this.onEdit,
  });

  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: paste.content));
    Fluttertoast.showToast(
      msg: "Copied to clipboard",
      backgroundColor: const Color(0xFF27C93F),
      textColor: Colors.white,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(
            "Delete Paste",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete '${paste.title}'?",
            style: GoogleFonts.inter(
              color: Colors.white70,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2A2A40), width: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  color: Colors.white54,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Delete",
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF5F56),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await PasteService.deletePaste(paste.id);
      if (success) {
        Fluttertoast.showToast(
          msg: "Paste deleted",
          backgroundColor: const Color(0xFFFF5F56),
          textColor: Colors.white,
        );
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F11),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          paste.title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF38BDF8),
                size: 20,
              ),
              onPressed: () => onEdit!(paste),
            ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFFF5F56),
              size: 20,
            ),
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CodeEditorBox(
                  value: paste.content,
                  readOnly: true,
                  onCopyPressed: _copyContent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

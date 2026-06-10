import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:codepad_app/models/paste.dart';
import 'package:codepad_app/services/paste_service.dart';
import 'package:codepad_app/widgets/code_editor_box.dart';

class HomeScreen extends StatefulWidget {
  final Paste? editPaste;
  final VoidCallback onSaved;

  const HomeScreen({
    super.key,
    this.editPaste,
    required this.onSaved,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  String _currentFileName = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editPaste?.title ?? '');
    _contentController = TextEditingController(text: widget.editPaste?.content ?? '');
    _currentFileName = widget.editPaste?.title ?? '';
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editPaste != oldWidget.editPaste) {
      _titleController.text = widget.editPaste?.title ?? '';
      _contentController.text = widget.editPaste?.content ?? '';
      _currentFileName = widget.editPaste?.title ?? '';
    }
  }

  void _onTitleChanged() {
    setState(() {
      _currentFileName = _titleController.text;
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePaste() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      Fluttertoast.showToast(
        msg: "Title cannot be empty",
        backgroundColor: const Color(0xFFFF5F56),
        textColor: Colors.white,
      );
      return;
    }
    if (content.isEmpty) {
      Fluttertoast.showToast(
        msg: "Content cannot be empty",
        backgroundColor: const Color(0xFFFF5F56),
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final isEditing = widget.editPaste != null;
    final paste = Paste(
      id: isEditing ? widget.editPaste!.id : const Uuid().v4(),
      title: title,
      content: content,
      createdAt: isEditing ? widget.editPaste!.createdAt : DateTime.now(),
    );

    final success = isEditing
        ? await PasteService.updatePaste(paste)
        : await PasteService.createPaste(paste);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Fluttertoast.showToast(
        msg: isEditing ? "Paste updated successfully" : "Paste created successfully",
        backgroundColor: const Color(0xFF27C93F),
        textColor: Colors.white,
      );
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _currentFileName = '';
      });
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editPaste != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEditing ? 'Edit Paste' : 'Create New Paste',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Save your code snippets and notes securely',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B6B8A),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter title here',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF4A4A6A),
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1A1A2E),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2A2A40), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePaste,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F0F11),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFF0F0F11),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update My Paste' : 'Create My Paste',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CodeEditorBox(
              controller: _contentController,
              fileName: _currentFileName,
            ),
          ),
        ],
      ),
    );
  }
}

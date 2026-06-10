import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeEditorBox extends StatefulWidget {
  final TextEditingController? controller;
  final String? value;
  final bool readOnly;
  final VoidCallback? onCopyPressed;
  final ValueChanged<String>? onChanged;
  final String? fileName;

  const CodeEditorBox({
    super.key,
    this.controller,
    this.value,
    this.readOnly = false,
    this.onCopyPressed,
    this.onChanged,
    this.fileName,
  });

  @override
  State<CodeEditorBox> createState() => _CodeEditorBoxState();
}

class _CodeEditorBoxState extends State<CodeEditorBox> {
  late TextEditingController _textController;
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _lineScrollController = ScrollController();
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller ?? TextEditingController(text: widget.value);
    _textController.addListener(_updateLineCount);
    _textScrollController.addListener(_syncScroll);
    _updateLineCount();
  }

  @override
  void didUpdateWidget(CodeEditorBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _textController) {
      _textController.removeListener(_updateLineCount);
      _textController = widget.controller!;
      _textController.addListener(_updateLineCount);
      _updateLineCount();
    } else if (widget.value != null && widget.value != oldWidget.value) {
      _textController.text = widget.value!;
      _updateLineCount();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _textController.dispose();
    } else {
      _textController.removeListener(_updateLineCount);
    }
    _textScrollController.removeListener(_syncScroll);
    _textScrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  void _updateLineCount() {
    final text = _textController.text;
    final count = '\n'.allMatches(text).length + 1;
    if (count != _lineCount) {
      setState(() {
        _lineCount = count;
      });
    }
  }

  void _syncScroll() {
    if (_lineScrollController.hasClients) {
      _lineScrollController.jumpTo(_textScrollController.offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        (widget.fileName != null && widget.fileName!.trim().isNotEmpty)
            ? widget.fileName!.trim()
            : 'untitled.txt';

    final lineNumbersText = List.generate(_lineCount, (i) => '${i + 1}').join('\n');
    const double fontSize = 14.0;
    const double lineHeight = 1.5;
    const EdgeInsets verticalPadding = EdgeInsets.symmetric(vertical: 16.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A40), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E32),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFF2A2A40), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5F56),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFBD2E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27C93F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  displayName,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: const Color(0xFF8888A8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (widget.onCopyPressed != null)
                  GestureDetector(
                    onTap: widget.onCopyPressed,
                    child: const Icon(
                      Icons.copy_rounded,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F11),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 44,
                    padding: verticalPadding,
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFF2A2A40), width: 1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: _lineScrollController,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Text(
                        lineNumbersText,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: fontSize,
                          height: lineHeight,
                          color: const Color(0xFF4A4A6A),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: TextField(
                        controller: _textController,
                        scrollController: _textScrollController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        readOnly: widget.readOnly,
                        onChanged: widget.onChanged,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: fontSize,
                          height: lineHeight,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: '// Enter your code or notes here...',
                          hintStyle: GoogleFonts.jetBrainsMono(
                            fontSize: fontSize,
                            height: lineHeight,
                            color: const Color(0xFF3A3A5A),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: verticalPadding,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

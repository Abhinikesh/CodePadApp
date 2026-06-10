import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:codepad_app/models/paste.dart';
import 'package:codepad_app/services/paste_service.dart';
import 'package:codepad_app/screens/view_paste_screen.dart';

class PastesScreen extends StatefulWidget {
  final ValueChanged<Paste> onEdit;

  const PastesScreen({
    super.key,
    required this.onEdit,
  });

  @override
  State<PastesScreen> createState() => _PastesScreenState();
}

class _PastesScreenState extends State<PastesScreen> {
  List<Paste> _pastes = [];
  List<Paste> _filteredPastes = [];
  bool _isRefreshing = false;
  bool _hasLoaded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPastes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPastes() async {
    final cached = await PasteService.loadLocalCache();
    if (mounted) {
      setState(() {
        _pastes = cached;
        _filteredPastes = _filterPastes(cached, _searchController.text);
        _hasLoaded = true;
      });
    }
    if (mounted) setState(() => _isRefreshing = true);
    final fresh = await PasteService.getPastes();
    if (mounted) {
      setState(() {
        _pastes = fresh;
        _filteredPastes = _filterPastes(fresh, _searchController.text);
        _isRefreshing = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filteredPastes = _filterPastes(_pastes, _searchController.text);
    });
  }

  List<Paste> _filterPastes(List<Paste> list, String query) {
    if (query.isEmpty) return list;
    final term = query.toLowerCase();
    return list.where((p) => p.title.toLowerCase().contains(term)).toList();
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String? _getDownloadsPath() {
    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return '$home/Downloads';
      }
    } else if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) {
        return '$home\\Downloads';
      }
    } else if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    }
    return null;
  }

  Future<void> _downloadPaste(Paste paste) async {
    final dirPath = _getDownloadsPath();
    if (dirPath == null) {
      Fluttertoast.showToast(
        msg: "Downloads directory not supported on this platform",
        backgroundColor: const Color(0xFFFF5F56),
        textColor: Colors.white,
      );
      return;
    }
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final sanitizedTitle = paste.title.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      final file = File('${dir.path}/$sanitizedTitle.txt');
      await file.writeAsString(paste.content);
      Fluttertoast.showToast(
        msg: "Saved as $sanitizedTitle.txt in Downloads",
        backgroundColor: const Color(0xFF27C93F),
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Download failed: $e",
        backgroundColor: const Color(0xFFFF5F56),
        textColor: Colors.white,
      );
    }
  }

  Future<void> _confirmDelete(Paste paste) async {
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
      final currentList = List<Paste>.from(_pastes);
      currentList.removeWhere((p) => p.id == paste.id);
      setState(() {
        _pastes = currentList;
        _filteredPastes = _filterPastes(currentList, _searchController.text);
      });
      final success = await PasteService.deletePaste(paste.id);
      if (success) {
        Fluttertoast.showToast(
          msg: "Paste deleted",
          backgroundColor: const Color(0xFFFF5F56),
          textColor: Colors.white,
        );
        _loadPastes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: "Search pastes by title...",
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF4A4A6A),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF4A4A6A),
              ),
              filled: true,
              fillColor: const Color(0xFF1A1A2E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2A2A40), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Total: ${_filteredPastes.length} ${_filteredPastes.length == 1 ? 'paste' : 'pastes'}",
            style: GoogleFonts.inter(
              color: const Color(0xFF38BDF8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (_isRefreshing)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Color(0xFF38BDF8),
              minHeight: 2,
            ),
          const SizedBox(height: 8),
          Expanded(
            child: !_hasLoaded
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF38BDF8),
                      strokeWidth: 2,
                    ),
                  )
                : _filteredPastes.isEmpty
                    ? Center(
                        child: Text(
                          "No pastes found",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4A4A6A),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadPastes(),
                        color: const Color(0xFF38BDF8),
                        backgroundColor: const Color(0xFF1A1A2E),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _filteredPastes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final paste = _filteredPastes[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF2A2A40), width: 1.5),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    paste.title,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F0F11),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      paste.content,
                                      style: GoogleFonts.jetBrainsMono(
                                        color: const Color(0xCCFFFFFF),
                                        fontSize: 13,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 14,
                                            color: Color(0xFF4A4A6A),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDate(paste.createdAt),
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF4A4A6A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility_outlined, size: 18),
                                            color: const Color(0xFF38BDF8),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ViewPasteScreen(paste: paste),
                                                ),
                                              ).then((_) => _loadPastes());
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            color: const Color(0xFF38BDF8),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => widget.onEdit(paste),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.copy_rounded, size: 18),
                                            color: const Color(0xFF38BDF8),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              await Clipboard.setData(ClipboardData(text: paste.content));
                                              Fluttertoast.showToast(
                                                msg: "Copied to clipboard",
                                                backgroundColor: const Color(0xFF27C93F),
                                                textColor: Colors.white,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.share_outlined, size: 18),
                                            color: const Color(0xFF38BDF8),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () async {
                                              await SharePlus.instance.share(
                                                ShareParams(
                                                  text: paste.content,
                                                  subject: paste.title,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.download_outlined, size: 18),
                                            color: const Color(0xFF38BDF8),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _downloadPaste(paste),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                            color: const Color(0xFFFF5F56),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _confirmDelete(paste),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

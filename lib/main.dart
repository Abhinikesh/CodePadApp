import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:codepad_app/supabase_client.dart';
import 'package:codepad_app/models/paste.dart';
import 'package:codepad_app/screens/home_screen.dart';
import 'package:codepad_app/screens/pastes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
    } catch (_) {}
  }
  runApp(const CodePadApp());
}

class CodePadApp extends StatelessWidget {
  const CodePadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodePad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        primaryColor: const Color(0xFF38BDF8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          surface: Color(0xFF1A1A2E),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  Paste? _editPaste;

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;
    if (_currentIndex == 0) {
      currentScreen = HomeScreen(
        editPaste: _editPaste,
        onSaved: () {
          setState(() {
            _editPaste = null;
            _currentIndex = 1;
          });
        },
      );
    } else {
      currentScreen = PastesScreen(
        onEdit: (paste) {
          setState(() {
            _editPaste = paste;
            _currentIndex = 0;
          });
        },
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopNavBar(),
            Expanded(child: currentScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F11),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A40), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Color(0xFF0F0F11),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'CodePad',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          _NavLink(
            label: 'Home',
            isActive: _currentIndex == 0,
            onTap: () {
              setState(() {
                if (_currentIndex == 0) _editPaste = null;
                _currentIndex = 0;
              });
            },
          ),
          const SizedBox(width: 8),
          _NavLink(
            label: 'Pastes',
            isActive: _currentIndex == 1,
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF38BDF8) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? null
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isActive ? const Color(0xFF0F0F11) : const Color(0xFFB0B0C8),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

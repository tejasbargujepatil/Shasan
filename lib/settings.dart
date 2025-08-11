import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // NEW: For logout redirection

import 'admin.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin {
  bool isMarathi = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    loadLanguage();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMarathi = prefs.getBool('isMarathi') ?? false;
    });
  }

  Future<void> toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMarathi', !isMarathi);
    setState(() {
      isMarathi = !isMarathi;
    });

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMarathi ? "🌐 मराठी निवडले" : "🌐 English selected",
          style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.deepPurple.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        elevation: 6,
        showCloseIcon: true,
        closeIconColor: Colors.white,
      ),
    );
  }

  void navigateToAdmin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMarathi ? "कृपया प्रथम लॉगिन करा" : "Please login first",
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Ask for password again
    final TextEditingController passController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(
            isMarathi ? 'प्रवेश संकेतशब्द' : 'Enter Admin Password',
            style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: isMarathi ? 'संकेतशब्द' : 'Password',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                isMarathi ? 'रद्द करा' : 'Cancel',
                style: GoogleFonts.roboto(color: Colors.grey.shade600),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isMarathi ? 'पुष्टी करा' : 'Confirm',
                style: GoogleFonts.roboto(color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context, passController.text),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    // Check email and password
    final email = user.email;
    final enteredPassword = result.trim();

    if (email == 'sgaware80@gmail.com' && enteredPassword == 'ShasanMitra@sgaware80@gmail.c0m') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMarathi ? "❌ प्रवेश नाकारला" : "❌ Access denied",
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openEmailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@shasanmitra.app',
      query: 'subject=Support Needed',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Widget _buildAnimatedCard(Widget child, int index) {
    return FadeInUp(
      duration: Duration(milliseconds: 400 + (index * 100)),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.95),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: child is SwitchListTile ? null : (child as ListTile).onTap,
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
  _buildAnimatedCard(
    SwitchListTile(
      title: Text(
        isMarathi ? "भाषा: मराठी" : "Language: English",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isMarathi ? "इंग्रजी ↔️ मराठी" : "Switch between English and Marathi",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
      ),
      value: isMarathi,
      onChanged: (_) => toggleLanguage(),
      secondary: Icon(Icons.language, color: Colors.deepPurple.shade600),
      activeColor: Colors.deepPurple.shade600,
    ),
    0,
  ),
  _buildAnimatedCard(
    ListTile(
      leading: Icon(Icons.admin_panel_settings, color: Colors.deepPurple.shade600),
      title: Text(
        isMarathi ? "प्रशासक लॉगिन" : "Admin Login / Upload",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isMarathi ? "डेटा व्यवस्थापनासाठी" : "For data upload & management",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.login, color: Colors.deepPurple.shade600, size: 24),
      onTap: () {
        HapticFeedback.lightImpact();
        navigateToAdmin();
      },
    ),
    1,
  ),
  _buildAnimatedCard(
    ListTile(
      leading: Icon(Icons.info_outline, color: Colors.deepPurple.shade600),
      title: Text(
        isMarathi ? "बद्दल" : "About Developer",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "Developed by Tejas Barguje Patil",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.deepPurple.shade600, size: 16),
      onTap: () {
        HapticFeedback.lightImpact();
        showAboutDialog(
          context: context,
          applicationName: "Shasan Mitra",
          applicationVersion: "v1.0.0",
          applicationIcon: Icon(Icons.gavel, color: Colors.deepPurple.shade600),
          children: [
            Text("Developed by Tejas Barguje Patil.", style: GoogleFonts.roboto(fontSize: 16)),
            const SizedBox(height: 10),
            Text("An AI-powered governance assistant app.", style: GoogleFonts.roboto(fontSize: 16)),
          ],
        );
      },
    ),
    2,
  ),
  _buildAnimatedCard(
    ListTile(
      leading: Icon(Icons.email, color: Colors.deepPurple.shade600),
      title: Text(
        isMarathi ? "संपर्क" : "Contact Support",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "support@shasanmitra.app",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.open_in_new, color: Colors.deepPurple.shade600),
      onTap: () {
        HapticFeedback.lightImpact();
        _openEmailSupport();
      },
    ),
    3,
  ),
  _buildAnimatedCard(
    ListTile(
      leading: Icon(Icons.verified, color: Colors.deepPurple.shade600),
      title: Text(
        "App Version",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "1.0.0 (Beta)",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
      ),
    ),
    4,
  ),
  // ✅ Properly add the Logout card inside the list:
  _buildAnimatedCard(
    ListTile(
      leading: Icon(Icons.logout, color: Colors.deepPurple.shade600),
      title: Text(
        isMarathi ? "बाहेर पडा" : "Logout",
        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isMarathi ? "सत्र समाप्त करा" : "End your session",
        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.exit_to_app, color: Colors.deepPurple.shade600),
      onTap: () {
        HapticFeedback.lightImpact();
void confirmLogout() async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isMarathi ? "बाहेर पडायचे आहे?" : "Confirm Logout",
        style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
      ),
      content: Text(
        isMarathi
            ? "तुम्हाला खात्री आहे की तुम्ही सत्र समाप्त करू इच्छिता?"
            : "Are you sure you want to end your session?",
        style: GoogleFonts.roboto(),
      ),
      actions: [
        TextButton(
          child: Text(isMarathi ? "रद्द करा" : "Cancel"),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(isMarathi ? "बाहेर पडा" : "Logout"),
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMarathi ? "✅ यशस्वीरित्या लॉगआउट झाले" : "✅ Successfully logged out",
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
        confirmLogout();
      },
    ),
    5,
  ),
];


    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple.shade700, Colors.purple.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          isMarathi ? "⚙️ सेटिंग्ज" : "⚙️ Settings",
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: cards,
          ),
        ),
      ),
    );

    
  }
}










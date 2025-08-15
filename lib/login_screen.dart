import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'register_screen.dart';
import 'subscription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;
  String? errorText;

  @override
  void initState() {
    super.initState();
    loadSavedCredentials();
  }

  Future<void> loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('email') ?? '';
    passwordController.text = prefs.getString('password') ?? '';
  }

  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  void login() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = emailController.text.trim();
      final password = passwordController.text;

      try {
        UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        await saveCredentials(email, password);

        final uid = userCred.user?.uid;
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!doc.exists) {
          setState(() => errorText = "User profile not found");
          return;
        }

        final role = doc['role'] ?? 'user';

        if (mounted) {
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() => errorText = 'Login failed: ${e.message}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 20,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.gavel, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text('', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 11),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[200],
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.blue),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.length < 6) ? 'Password too short' : null,
                    ),
                    const SizedBox(height: 15),
                    if (errorText != null)
                      Text(errorText!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: login,
                      icon: const Icon(Icons.login),
                      label: const Text('Login'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      child: const Text("Don't have an account? Register"),
                    ),
                    const SizedBox(height: 5),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text("Subscribe to Premium"),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Developed By:\nInnoveda Tech Solutions \ninnoveda.co.in\nDisclaimer:\nOur App does not represent any government entity.This app is only for Education purpose.\nTerms and Condition Apply.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'home.dart';
// import 'register_screen.dart';
// import 'subscription.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   bool obscurePassword = true;
//   String? errorText;

//   @override
//   void initState() {
//     super.initState();
//     loadSavedCredentials();
//   }

//   Future<void> loadSavedCredentials() async {
//     final prefs = await SharedPreferences.getInstance();
//     emailController.text = prefs.getString('email') ?? '';
//     passwordController.text = prefs.getString('password') ?? '';
//   }

//   Future<void> saveCredentials(String email, String password) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('email', email);
//     await prefs.setString('password', password);
//   }

//   void login() async {
//     if (_formKey.currentState?.validate() ?? false) {
//       final email = emailController.text.trim();
//       final password = passwordController.text;

//       try {
//         UserCredential userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
//           email: email,
//           password: password,
//         );

//         await saveCredentials(email, password);

//         final uid = userCred.user?.uid;
//         final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

//         if (!doc.exists) {
//           setState(() => errorText = "User profile not found");
//           return;
//         }

//         final role = doc['role'] ?? 'user';

//         if (mounted) {
//           if (role == 'admin') {
//             Navigator.pushReplacementNamed(context, '/admin');
//           } else {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (_) => const HomeScreen()),
//             );
//           }
//         }
//       } on FirebaseAuthException catch (e) {
//         setState(() => errorText = 'Login failed: ${e.message}');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           final isSmallScreen = constraints.maxWidth < 600;
//           final padding = EdgeInsets.symmetric(
//             horizontal: isSmallScreen ? 16.0 : 32.0,
//             vertical: isSmallScreen ? 16.0 : 32.0,
//           );

//           return Center(
//             child: SingleChildScrollView(
//               padding: padding,
//               child: Card(
//                 elevation: 12,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                 color: Colors.white,
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           'Indian Laws Marathi',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 24 : 30,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue[900],
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 24),
//                         const Icon(Icons.gavel, size: 80, color: Colors.blue),
//                         const SizedBox(height: 24),
//                         Text(
//                           'Welcome Back!',
//                           style: TextStyle(
//                             fontSize: isSmallScreen ? 22 : 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 32),
//                         TextFormField(
//                           controller: emailController,
//                           decoration: InputDecoration(
//                             labelText: 'Email',
//                             prefixIcon: Icon(Icons.email, color: Colors.blue),
//                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                             filled: true,
//                             fillColor: Colors.grey[200],
//                           ),
//                           keyboardType: TextInputType.emailAddress,
//                           validator: (value) =>
//                               (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
//                         ),
//                         const SizedBox(height: 20),
//                         TextFormField(
//                           controller: passwordController,
//                           obscureText: obscurePassword,
//                           decoration: InputDecoration(
//                             labelText: 'Password',
//                             prefixIcon: Icon(Icons.lock, color: Colors.blue),
//                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                             filled: true,
//                             fillColor: Colors.grey[200],
//                             suffixIcon: IconButton(
//                               icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off,
//                                   color: Colors.blue),
//                               onPressed: () => setState(() => obscurePassword = !obscurePassword),
//                             ),
//                           ),
//                           validator: (value) =>
//                               (value == null || value.length < 6) ? 'Password too short' : null,
//                         ),
//                         const SizedBox(height: 20),
//                         if (errorText != null)
//                           Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 14)),
//                         const SizedBox(height: 24),
//                         ElevatedButton.icon(
//                           onPressed: login,
//                           icon: const Icon(Icons.login, size: 20),
//                           label: const Text('Login', style: TextStyle(fontSize: 16)),
//                           style: ElevatedButton.styleFrom(
//                             minimumSize: const Size.fromHeight(50),
//                             backgroundColor: Colors.blue,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                                 context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
//                           },
//                           child: const Text("Don't have an account? Register",
//                               style: TextStyle(fontSize: 14, color: Colors.blue)),
//                         ),
//                         const SizedBox(height: 16),
//                         ElevatedButton.icon(
//                           icon: const Icon(Icons.star, size: 20),
//                           label: const Text("Subscribe to Premium", style: TextStyle(fontSize: 16)),
//                           onPressed: () {
//                             Navigator.push(
//                                 context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.orange,
//                             minimumSize: const Size.fromHeight(45),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         const Text(
//                           'Developed By:\nAJINKYA INNOVATIONS\nGuidance:\nAdv. Kiran Durve.\nAdv. Sanjana Durve.\n\nSource of the Information:\nhttps://www.indiancode.nic.in/\nDisclaimer:\nOur App does not represent any government entity.\nThis app is only for Education purpose.\nTerms and Condition Apply.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(fontSize: 12, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



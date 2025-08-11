import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'epartment_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'chat.dart'; // Import the chatbot file

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  final departmentController = TextEditingController();
  final subdepartmentController = TextEditingController();
  String? selectedDepartment;
  String? selectedSubdepartment;
  List<String> pickedPdfFiles = [];
  int _selectedTabIndex = 0; // 0: Departments, 1: User Management, 2: Chat

  late final GlobalKey<AnimatedListState> _subDepListKey;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _subDepListKey = GlobalKey<AnimatedListState>();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DepartmentProvider>(context);
    final departments = provider.departments;

    List<String> currentSubdepartments =
        selectedDepartment != null ? (departments[selectedDepartment!] ?? []) : [];

    List<String> uploadedPdfs = [];
    if (selectedDepartment != null && selectedSubdepartment != null) {
      uploadedPdfs = provider.getPdfsForSubdepartment(selectedDepartment!, selectedSubdepartment!) ?? [];
    }

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
          'Admin Panel',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Departments'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDepartmentTab(provider, departments, currentSubdepartments, uploadedPdfs),
          _buildUserManagementTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildDepartmentTab(DepartmentProvider provider, Map<String, List<String>> departments,
      List<String> currentSubdepartments, List<String> uploadedPdfs) {
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // Statistics Cards Section - Fetched from Firebase
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('departments').snapshots(),
            builder: (context, snapshot) {
              int totalDepartments = 0;
              int totalSubdepartments = 0;
              
              if (snapshot.hasData) {
                totalDepartments = snapshot.data!.docs.length;
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final subdepartments = data['subdepartments'] as List<dynamic>? ?? [];
                  totalSubdepartments += subdepartments.length;
                }
              }
              
              return Row(
                children: [
                  Expanded(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business,
                              size: 36,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(height: 8),
                            snapshot.connectionState == ConnectionState.waiting
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blue.shade700,
                                    ),
                                  )
                                : Text(
                                    '$totalDepartments',
                                    style: GoogleFonts.roboto(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                            Text(
                              'Total Departments',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_tree,
                              size: 36,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(height: 8),
                            snapshot.connectionState == ConnectionState.waiting
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.green.shade700,
                                    ),
                                  )
                                : Text(
                                    '$totalSubdepartments',
                                    style: GoogleFonts.roboto(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                            Text(
                              'Total Subdepartments',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),

          _animatedSection(
            key: const ValueKey('addDept'),
            title: 'Add Department',
            children: [
              _textInput(departmentController, 'New Department'),
              const SizedBox(height: 12),
              _primaryButton('Add Department', Icons.add_business, () async {
                final deptName = departmentController.text.trim();
                if (deptName.isNotEmpty) {
                  provider.addDepartment(deptName);
                  await FirebaseFirestore.instance.collection('departments').doc(deptName).set({
                    'name': deptName,
                    'subdepartments': [],
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  departmentController.clear();
                }
              }),
            ],
          ),

          const SizedBox(height: 20),

          // Department Selection from Firebase
          _animatedSection(
            key: const ValueKey('deptDropdown'),
            title: 'Select Department',
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('departments').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'No departments found. Create one first.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  List<String> firebaseDepartments = snapshot.data!.docs
                      .map((doc) => doc.id)
                      .toList();
                  
                  // Update current subdepartments based on Firebase data
                  if (selectedDepartment != null) {
                    var selectedDoc = snapshot.data!.docs
                        .where((doc) => doc.id == selectedDepartment)
                        .firstOrNull;
                    if (selectedDoc != null) {
                      final data = selectedDoc.data() as Map<String, dynamic>;
                      currentSubdepartments = List<String>.from(data['subdepartments'] ?? []);
                    }
                  }
                  
                  return DropdownButtonFormField<String>(
                    value: firebaseDepartments.contains(selectedDepartment) ? selectedDepartment : null,
                    hint: const Text('Choose Department from Cloud'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.cloud),
                      helperText: '${firebaseDepartments.length} departments available',
                    ),
                    items: firebaseDepartments
                        .map((dep) => DropdownMenuItem(
                              value: dep, 
                              child: Row(
                                children: [
                                  Icon(Icons.business, size: 16, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(dep),
                                ],
                              )
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedDepartment = val;
                        selectedSubdepartment = null;
                        pickedPdfFiles.clear();
                      });
                    },
                  );
                },
              ),
            ],
          ),

          if (selectedDepartment != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _animatedSection(
                key: const ValueKey('subDept'),
                title: 'Add Subdepartment to $selectedDepartment',
                children: [
                  _textInput(subdepartmentController, 'New Subdepartment'),
                  const SizedBox(height: 12),
                  _primaryButton('Add Subdepartment', Icons.add, () async {
                    final subdep = subdepartmentController.text.trim();
                    if (subdep.isNotEmpty) {
                      try {
                        final docRef = FirebaseFirestore.instance
                            .collection('departments')
                            .doc(selectedDepartment);
                        final docSnap = await docRef.get();
                        if (docSnap.exists) {
                          final data = docSnap.data()!;
                          final currentSubs = List<String>.from(data['subdepartments'] ?? []);
                          if (!currentSubs.contains(subdep)) {
                            currentSubs.add(subdep);
                            await docRef.update({'subdepartments': currentSubs});
                            provider.addSubDepartment(selectedDepartment!, subdep);
                            subdepartmentController.clear();
                            setState(() {});
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Subdepartment "$subdep" added successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Subdepartment "$subdep" already exists'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding subdepartment: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }),
                  const SizedBox(height: 12),
                  // Display current subdepartments from Firebase
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('departments')
                        .doc(selectedDepartment)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }
                      
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('Department not found');
                      }
                      
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final subdepartments = List<String>.from(data['subdepartments'] ?? []);
                      
                      if (subdepartments.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'No subdepartments in this department',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Subdepartments (${subdepartments.length}):',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...subdepartments.map((subdep) => Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              leading: Icon(Icons.subdirectory_arrow_right, color: Colors.green),
                              title: Text(subdep),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  try {
                                    final docRef = FirebaseFirestore.instance
                                        .collection('departments')
                                        .doc(selectedDepartment);
                                    final docSnap = await docRef.get();
                                    if (docSnap.exists) {
                                      final data = docSnap.data()!;
                                      final currentSubs = List<String>.from(data['subdepartments'] ?? []);
                                      currentSubs.remove(subdep);
                                      await docRef.update({'subdepartments': currentSubs});
                                      provider.removeSubDepartment(selectedDepartment!, subdep);
                                      if (selectedSubdepartment == subdep) {
                                        selectedSubdepartment = null;
                                      }
                                      setState(() {});
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error removing subdepartment: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          )),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

          if (currentSubdepartments.isNotEmpty)
            _animatedSection(
              key: const ValueKey('pdfUpload'),
              title: 'Upload PDFs to $selectedDepartment',
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: selectedDepartment != null
                      ? FirebaseFirestore.instance
                          .collection('departments')
                          .doc(selectedDepartment)
                          .snapshots()
                      : null,
                  builder: (context, snapshot) {
                    List<String> firebaseSubdepartments = [];
                    
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      firebaseSubdepartments = List<String>.from(data['subdepartments'] ?? []);
                    }
                    
                    if (firebaseSubdepartments.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'No subdepartments available. Add one first.',
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: firebaseSubdepartments.contains(selectedSubdepartment) 
                              ? selectedSubdepartment 
                              : null,
                          hint: const Text('Choose Subdepartment from Cloud'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.cloud_queue),
                            helperText: '${firebaseSubdepartments.length} subdepartments available',
                          ),
                          items: firebaseSubdepartments
                              .map((subdep) => DropdownMenuItem(
                                    value: subdep, 
                                    child: Row(
                                      children: [
                                        Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Text(subdep),
                                      ],
                                    )
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedSubdepartment = val;
                              pickedPdfFiles.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: Text(selectedSubdepartment != null 
                              ? 'Upload PDF(s) to $selectedSubdepartment' 
                              : 'Upload PDF(s)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            minimumSize: const Size.fromHeight(45),
                          ),
                          onPressed: selectedSubdepartment == null
                              ? null
                              : () async {
                                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf'],
                                    allowMultiple: true,
                                  );
                                  if (result != null) {
                                    try {
                                      List<String> downloadUrls = [];

                                      for (var file in result.files) {
                                        String fileName = file.name;
                                        File localFile = File(file.path!);

                                        final storageRef = FirebaseStorage.instance
                                            .ref()
                                            .child('pdfs/$selectedDepartment/$selectedSubdepartment/$fileName');

                                        UploadTask uploadTask = storageRef.putFile(localFile);
                                        TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
                                        String downloadUrl = await snapshot.ref.getDownloadURL();

                                        downloadUrls.add(downloadUrl);
                                      }

                                      provider.addPdfsToSubdepartment(
                                        selectedDepartment!,
                                        selectedSubdepartment!,
                                        downloadUrls,
                                      );

                                      setState(() {
                                        pickedPdfFiles = provider.getPdfsForSubdepartment(
                                          selectedDepartment!,
                                          selectedSubdepartment!,
                                        ) ?? [];
                                      });
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${result.files.length} PDF(s) uploaded successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error uploading PDFs: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                ...uploadedPdfs.map((pdfName) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        AnimationController(
                          vsync: this,
                          duration: const Duration(milliseconds: 400),
                        )..forward(),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(pdfName),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            provider.removePdfFromSubdepartment(
                                selectedDepartment!, selectedSubdepartment!, pdfName);
                            setState(() {
                              pickedPdfFiles = provider.getPdfsForSubdepartment(
                                      selectedDepartment!, selectedSubdepartment!) ??
                                  [];
                            });
                          },
                        ),
                      ),
                    )),
              ],
            ),

          const SizedBox(height: 20),
          _animatedSection(
            key: const ValueKey('allDepts'),
            title: 'All Departments',
            children: departments.entries.map((entry) {
              return ExpansionTile(
                title: Text(entry.key),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => provider.removeDepartment(entry.key),
                ),
                children: entry.value.map((subdep) => ListTile(title: Text(subdep))).toList(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.people, size: 32, color: Colors.deepPurple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'User Subscription Management',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  // Add refresh button
                  IconButton(
                    onPressed: () {
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final userDoc = snapshot.data!.docs[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final userId = userDoc.id;
                    final email = userData['email'] ?? 'No email';
                    final isPremium = userData['isPremium'] ?? false;
                    final paidAmount = userData['paidAmount'] ?? 0.0;
                    final subscriptionDate = userData['subscriptionDate']?.toDate();
                    final isBlocked = userData['isBlocked'] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: isPremium ? Colors.amberAccent : Colors.grey,
                          child: Icon(
                            isPremium ? Icons.star : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          email,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            color: isBlocked ? Colors.red : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isPremium ? Icons.verified : Icons.free_cancellation,
                                  size: 16,
                                  color: isPremium ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPremium ? 'Premium User' : 'Free User',
                                  style: TextStyle(
                                    color: isPremium ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (isBlocked)
                              Row(
                                children: [
                                  Icon(Icons.block, size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BLOCKED',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _userInfoRow('User ID:', userId),
                                _userInfoRow('Email:', email),
                                _userInfoRow('Premium Status:', isPremium ? 'Yes' : 'No'),
                                _userInfoRow('Paid Amount:', '₹${paidAmount.toStringAsFixed(2)}'),
                                if (subscriptionDate != null)
                                  _userInfoRow(
                                    'Subscription Date:',
                                    '${subscriptionDate.day}/${subscriptionDate.month}/${subscriptionDate.year}',
                                  ),
                                _userInfoRow('Account Status:', isBlocked ? 'BLOCKED' : 'Active'),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _togglePremiumStatus(userId, !isPremium),
                                      icon: Icon(isPremium ? Icons.star_border : Icons.star),
                                      label: Text(isPremium ? 'Remove Premium' : 'Make Premium'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isPremium ? Colors.orange : Colors.greenAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _toggleBlockStatus(userId, !isBlocked),
                                      icon: Icon(isBlocked ? Icons.check_circle : Icons.block),
                                      label: Text(isBlocked ? 'Unblock' : 'Block'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isBlocked ? Colors.green : Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () => _showUpdatePaymentDialog(userId, paidAmount),
                                    icon: const Icon(Icons.payment),
                                    label: const Text('Update Payment'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.smart_toy,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Assistant',
                            style: GoogleFonts.roboto(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            'Chat with AI for administrative assistance',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(
            child: ChatScreen(departmentName: 'Admin',), // Use your existing chat widget here
          ),
        ],
      ),
    );
  }

  Widget _userInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePremiumStatus(String userId, bool isPremium) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isPremium': isPremium,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium ? 'User upgraded to Premium' : 'Premium status removed',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating premium status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleBlockStatus(String userId, bool isBlocked) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'isBlocked': isBlocked,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked ? 'User account blocked' : 'User account unblocked',
          ),
          backgroundColor: isBlocked ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating block status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUpdatePaymentDialog(String userId, double currentAmount) {
    final paymentController = TextEditingController(text: currentAmount.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Payment Amount'),
        content: TextField(
          controller: paymentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newAmount = double.parse(paymentController.text);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'paidAmount': newAmount,
                  'lastUpdated': FieldValue.serverTimestamp(),
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment amount updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating payment: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _animatedSection({
    required Key key,
    required String title,
    required List<Widget> children,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Card(
        key: key,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ]),
        ),
      ),
    );
  }

  Widget _textInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.input),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: const Size.fromHeight(45),
      ),
    );
  }
}




















// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'epartment_provider.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'login_screen.dart';
// import 'chat.dart'; // Import the chatbot file

// class AdminScreen extends StatefulWidget {
//   const AdminScreen({super.key});

//   @override
//   State<AdminScreen> createState() => _AdminScreenState();
// }

// class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
//   final departmentController = TextEditingController();
//   final subdepartmentController = TextEditingController();
//   String? selectedDepartment;
//   String? selectedSubdepartment;
//   List<String> pickedPdfFiles = [];
//   int _selectedTabIndex = 0; // 0: Departments, 1: User Management, 2: Chat

//   late final GlobalKey<AnimatedListState> _subDepListKey;
//   late final TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _subDepListKey = GlobalKey<AnimatedListState>();
//     _tabController = TabController(length: 3, vsync: this);
//     _tabController.addListener(() {
//       setState(() {
//         _selectedTabIndex = _tabController.index;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<DepartmentProvider>(context);
//     final departments = provider.departments;

//     List<String> currentSubdepartments =
//         selectedDepartment != null ? (departments[selectedDepartment!] ?? []) : [];

//     List<String> uploadedPdfs = [];
//     if (selectedDepartment != null && selectedSubdepartment != null) {
//       uploadedPdfs = provider.getPdfsForSubdepartment(selectedDepartment!, selectedSubdepartment!) ?? [];
//     }

//     return Scaffold(
//       appBar: AppBar(
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.deepPurple.shade700, Colors.purple.shade400],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         title: Text(
//           'Admin Panel',
//           style: GoogleFonts.roboto(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout, color: Colors.white),
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut();
//               Navigator.pushAndRemoveUntil(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LoginScreen()),
//                 (route) => false,
//               );
//             },
//           ),
//         ],
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           labelColor: Colors.white,
//           unselectedLabelColor: Colors.white70,
//           tabs: const [
//             Tab(icon: Icon(Icons.business), text: 'Departments'),
//             Tab(icon: Icon(Icons.people), text: 'Users'),
//             Tab(icon: Icon(Icons.chat), text: 'Chat'),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildDepartmentTab(provider, departments, currentSubdepartments, uploadedPdfs),
//           _buildUserManagementTab(),
//           _buildChatTab(),
//         ],
//       ),
//     );
//   }

//   Widget _buildDepartmentTab(DepartmentProvider provider, Map<String, List<String>> departments,
//       List<String> currentSubdepartments, List<String> uploadedPdfs) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: ListView(
//         children: [
//           _animatedSection(
//             key: const ValueKey('addDept'),
//             title: 'Add Department',
//             children: [
//               _textInput(departmentController, 'New Department'),
//               const SizedBox(height: 12),
//               _primaryButton('Add Department', Icons.add_business, () async {
//                 final deptName = departmentController.text.trim();
//                 if (deptName.isNotEmpty) {
//                   provider.addDepartment(deptName);
//                   await FirebaseFirestore.instance.collection('departments').doc(deptName).set({
//                     'name': deptName,
//                     'subdepartments': [],
//                     'timestamp': FieldValue.serverTimestamp(),
//                   });
//                   departmentController.clear();
//                 }
//               }),
//             ],
//           ),

//           const SizedBox(height: 20),

//           AnimatedSize(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             child: selectedDepartment == null && departments.isEmpty
//                 ? const SizedBox()
//                 : _animatedSection(
//                     key: const ValueKey('deptDropdown'),
//                     title: 'Select Department',
//                     children: [
//                       DropdownButtonFormField<String>(
//                         value: selectedDepartment,
//                         hint: const Text('Choose Department'),
//                         isExpanded: true,
//                         decoration: const InputDecoration(border: OutlineInputBorder()),
//                         items: departments.keys
//                             .map((dep) => DropdownMenuItem(value: dep, child: Text(dep)))
//                             .toList(),
//                         onChanged: (val) {
//                           setState(() {
//                             selectedDepartment = val;
//                             selectedSubdepartment = null;
//                             pickedPdfFiles.clear();
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//           ),

//           if (selectedDepartment != null)
//             AnimatedSwitcher(
//               duration: const Duration(milliseconds: 400),
//               child: _animatedSection(
//                 key: const ValueKey('subDept'),
//                 title: 'Add Subdepartment',
//                 children: [
//                   _textInput(subdepartmentController, 'New Subdepartment'),
//                   const SizedBox(height: 12),
//                   _primaryButton('Add Subdepartment', Icons.add, () async {
//                     final subdep = subdepartmentController.text.trim();
//                     if (subdep.isNotEmpty) {
//                       provider.addSubDepartment(selectedDepartment!, subdep);
//                       subdepartmentController.clear();
//                       setState(() {});
//                       final docRef = FirebaseFirestore.instance
//                           .collection('departments')
//                           .doc(selectedDepartment);
//                       final docSnap = await docRef.get();
//                       if (docSnap.exists) {
//                         final data = docSnap.data()!;
//                         final currentSubs = List<String>.from(data['subdepartments'] ?? []);
//                         if (!currentSubs.contains(subdep)) {
//                           currentSubs.add(subdep);
//                           await docRef.update({'subdepartments': currentSubs});
//                         }
//                       }
//                     }
//                   }),
//                   const SizedBox(height: 12),
//                   AnimatedList(
//                     key: _subDepListKey,
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     initialItemCount: currentSubdepartments.length,
//                     itemBuilder: (context, index, animation) {
//                       final subdep = currentSubdepartments[index];
//                       return SizeTransition(
//                         sizeFactor: animation,
//                         child: ListTile(
//                           title: Text(subdep),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.delete),
//                             onPressed: () {
//                               provider.removeSubDepartment(selectedDepartment!, subdep);
//                               if (selectedSubdepartment == subdep) {
//                                 selectedSubdepartment = null;
//                               }
//                               setState(() {});
//                             },
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),

//           if (currentSubdepartments.isNotEmpty)
//             _animatedSection(
//               key: const ValueKey('pdfUpload'),
//               title: 'Upload PDFs',
//               children: [
//                 DropdownButtonFormField<String>(
//                   value: selectedSubdepartment,
//                   hint: const Text('Choose Subdepartment'),
//                   isExpanded: true,
//                   decoration: const InputDecoration(border: OutlineInputBorder()),
//                   items: currentSubdepartments
//                       .map((subdep) => DropdownMenuItem(value: subdep, child: Text(subdep)))
//                       .toList(),
//                   onChanged: (val) {
//                     setState(() {
//                       selectedSubdepartment = val;
//                       pickedPdfFiles.clear();
//                     });
//                   },
//                 ),
//                 const SizedBox(height: 12),
//                 ElevatedButton.icon(
//                   icon: const Icon(Icons.upload_file),
//                   label: const Text('Upload PDF(s)'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.indigo,
//                     minimumSize: const Size.fromHeight(45),
//                   ),
//                   onPressed: selectedSubdepartment == null
//                       ? null
//                       : () async {
//                           FilePickerResult? result = await FilePicker.platform.pickFiles(
//                             type: FileType.custom,
//                             allowedExtensions: ['pdf'],
//                             allowMultiple: true,
//                           );
//                           if (result != null) {
//                             List<String> downloadUrls = [];

//                             for (var file in result.files) {
//                               String fileName = file.name;
//                               File localFile = File(file.path!);

//                               final storageRef = FirebaseStorage.instance
//                                   .ref()
//                                   .child('pdfs/$selectedDepartment/$selectedSubdepartment/$fileName');

//                               UploadTask uploadTask = storageRef.putFile(localFile);
//                               TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
//                               String downloadUrl = await snapshot.ref.getDownloadURL();

//                               downloadUrls.add(downloadUrl);
//                             }

//                             provider.addPdfsToSubdepartment(
//                               selectedDepartment!,
//                               selectedSubdepartment!,
//                               downloadUrls,
//                             );

//                             setState(() {
//                               pickedPdfFiles = provider.getPdfsForSubdepartment(
//                                 selectedDepartment!,
//                                 selectedSubdepartment!,
//                               ) ?? [];
//                             });
//                           }
//                         },
//                 ),
//                 const SizedBox(height: 12),
//                 ...uploadedPdfs.map((pdfName) => SlideTransition(
//                       position: Tween<Offset>(
//                         begin: const Offset(1, 0),
//                         end: Offset.zero,
//                       ).animate(
//                         AnimationController(
//                           vsync: this,
//                           duration: const Duration(milliseconds: 400),
//                         )..forward(),
//                       ),
//                       child: ListTile(
//                         leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
//                         title: Text(pdfName),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete),
//                           onPressed: () {
//                             provider.removePdfFromSubdepartment(
//                                 selectedDepartment!, selectedSubdepartment!, pdfName);
//                             setState(() {
//                               pickedPdfFiles = provider.getPdfsForSubdepartment(
//                                       selectedDepartment!, selectedSubdepartment!) ??
//                                   [];
//                             });
//                           },
//                         ),
//                       ),
//                     )),
//               ],
//             ),

//           const SizedBox(height: 20),
//           _animatedSection(
//             key: const ValueKey('allDepts'),
//             title: 'All Departments',
//             children: departments.entries.map((entry) {
//               return ExpansionTile(
//                 title: Text(entry.key),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete),
//                   onPressed: () => provider.removeDepartment(entry.key),
//                 ),
//                 children: entry.value.map((subdep) => ListTile(title: Text(subdep))).toList(),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUserManagementTab() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           Card(
//             elevation: 6,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Icon(Icons.people, size: 32, color: Colors.deepPurple),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: Text(
//                       'User Subscription Management',
//                       style: GoogleFonts.roboto(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.deepPurple,
//                       ),
//                     ),
//                   ),
//                   // Add refresh button
//                   IconButton(
//                     onPressed: () {
//                       setState(() {});
//                     },
//                     icon: const Icon(Icons.refresh),
//                     color: Colors.deepPurple,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('users')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.people_outline, size: 64, color: Colors.grey),
//                         const SizedBox(height: 16),
//                         Text(
//                           'No users found',
//                           style: GoogleFonts.roboto(fontSize: 18, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   );
//                 }

//                 return ListView.builder(
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final userDoc = snapshot.data!.docs[index];
//                     final userData = userDoc.data() as Map<String, dynamic>;
//                     final userId = userDoc.id;
//                     final email = userData['email'] ?? 'No email';
//                     final isPremium = userData['isPremium'] ?? false;
//                     final paidAmount = userData['paidAmount'] ?? 0.0;
//                     final subscriptionDate = userData['subscriptionDate']?.toDate();
//                     final isBlocked = userData['isBlocked'] ?? false;

//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//                       elevation: 3,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       child: ExpansionTile(
//                         leading: CircleAvatar(
//                           backgroundColor: isPremium ? Colors.amberAccent : Colors.grey,
//                           child: Icon(
//                             isPremium ? Icons.star : Icons.person,
//                             color: Colors.white,
//                           ),
//                         ),
//                         title: Text(
//                           email,
//                           style: GoogleFonts.roboto(
//                             fontWeight: FontWeight.w600,
//                             color: isBlocked ? Colors.red : Colors.black87,
//                           ),
//                         ),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Icon(
//                                   isPremium ? Icons.verified : Icons.free_cancellation,
//                                   size: 16,
//                                   color: isPremium ? Colors.green : Colors.orange,
//                                 ),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   isPremium ? 'Premium User' : 'Free User',
//                                   style: TextStyle(
//                                     color: isPremium ? Colors.green : Colors.orange,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (isBlocked)
//                               Row(
//                                 children: [
//                                   Icon(Icons.block, size: 16, color: Colors.red),
//                                   const SizedBox(width: 4),
//                                   Text(
//                                     'BLOCKED',
//                                     style: TextStyle(
//                                       color: Colors.red,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 _userInfoRow('User ID:', userId),
//                                 _userInfoRow('Email:', email),
//                                 _userInfoRow('Premium Status:', isPremium ? 'Yes' : 'No'),
//                                 _userInfoRow('Paid Amount:', '₹${paidAmount.toStringAsFixed(2)}'),
//                                 if (subscriptionDate != null)
//                                   _userInfoRow(
//                                     'Subscription Date:',
//                                     '${subscriptionDate.day}/${subscriptionDate.month}/${subscriptionDate.year}',
//                                   ),
//                                 _userInfoRow('Account Status:', isBlocked ? 'BLOCKED' : 'Active'),
//                                 const SizedBox(height: 16),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                                   children: [
//                                     ElevatedButton.icon(
//                                       onPressed: () => _togglePremiumStatus(userId, !isPremium),
//                                       icon: Icon(isPremium ? Icons.star_border : Icons.star),
//                                       label: Text(isPremium ? 'Remove Premium' : 'Make Premium'),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: isPremium ? Colors.orange : Colors.greenAccent,
//                                         foregroundColor: Colors.white,
//                                       ),
//                                     ),
//                                     ElevatedButton.icon(
//                                       onPressed: () => _toggleBlockStatus(userId, !isBlocked),
//                                       icon: Icon(isBlocked ? Icons.check_circle : Icons.block),
//                                       label: Text(isBlocked ? 'Unblock' : 'Block'),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: isBlocked ? Colors.green : Colors.red,
//                                         foregroundColor: Colors.white,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Center(
//                                   child: TextButton.icon(
//                                     onPressed: () => _showUpdatePaymentDialog(userId, paidAmount),
//                                     icon: const Icon(Icons.payment),
//                                     label: const Text('Update Payment'),
//                                     style: TextButton.styleFrom(
//                                       foregroundColor: Colors.deepPurple,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChatTab() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Colors.deepPurple.shade50,
//             Colors.white,
//           ],
//         ),
//       ),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             child: Card(
//               elevation: 6,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.deepPurple.shade100,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(
//                         Icons.smart_toy,
//                         color: Colors.deepPurple,
//                         size: 28,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'AI Assistant',
//                             style: GoogleFonts.roboto(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.deepPurple,
//                             ),
//                           ),
//                           Text(
//                             'Chat with AI for administrative assistance',
//                             style: GoogleFonts.roboto(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const Expanded(
//             child: ChatScreen(departmentName: 'Admin',), // Use your existing chat widget here
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _userInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: GoogleFonts.roboto(
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: GoogleFonts.roboto(
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _togglePremiumStatus(String userId, bool isPremium) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .update({
//         'isPremium': isPremium,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             isPremium ? 'User upgraded to Premium' : 'Premium status removed',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating premium status: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   Future<void> _toggleBlockStatus(String userId, bool isBlocked) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .update({
//         'isBlocked': isBlocked,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             isBlocked ? 'User account blocked' : 'User account unblocked',
//           ),
//           backgroundColor: isBlocked ? Colors.red : Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error updating block status: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   void _showUpdatePaymentDialog(String userId, double currentAmount) {
//     final paymentController = TextEditingController(text: currentAmount.toString());
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Update Payment Amount'),
//         content: TextField(
//           controller: paymentController,
//           keyboardType: TextInputType.number,
//           decoration: const InputDecoration(
//             labelText: 'Amount (₹)',
//             prefixText: '₹ ',
//             border: OutlineInputBorder(),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               try {
//                 final newAmount = double.parse(paymentController.text);
//                 await FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(userId)
//                     .update({
//                   'paidAmount': newAmount,
//                   'lastUpdated': FieldValue.serverTimestamp(),
//                 });
                
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Payment amount updated successfully'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Error updating payment: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text('Update'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _animatedSection({
//     required Key key,
//     required String title,
//     required List<Widget> children,
//   }) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 400),
//       child: Card(
//         key: key,
//         elevation: 6,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//             Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 12),
//             ...children,
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _textInput(TextEditingController controller, String label) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: const Icon(Icons.input),
//         border: const OutlineInputBorder(),
//       ),
//     );
//   }

//   Widget _primaryButton(String label, IconData icon, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green,
//         minimumSize: const Size.fromHeight(45),
//       ),
//     );
//   }
// }








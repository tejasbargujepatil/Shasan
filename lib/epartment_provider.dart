// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';


// class DepartmentProvider with ChangeNotifier {
//   Map<String, List<String>> _departments = {};

//   // Structure: { department: { subdepartment: [pdfUrl, ...] } }
//   Map<String, Map<String, List<String>>> _departmentPdfs = {};

//   List<String> _filteredKeys = [];

//   Map<String, List<String>> get departments => _departments;

//   Map<String, Map<String, List<String>>> get departmentPdfs => _departmentPdfs;

//   List<String> get departmentKeys =>
//       _filteredKeys.isEmpty ? _departments.keys.toList() : _filteredKeys;

//   DepartmentProvider() {
//     loadFromPrefs();
//   }

//   void addDepartment(String department) {
//     if (!_departments.containsKey(department)) {
//       _departments[department] = [];
//       _filteredKeys = _departments.keys.toList();
//       saveToPrefs();
//       notifyListeners();
//     }
//   }

//   void removeDepartment(String department) {
//     _departments.remove(department);
//     _departmentPdfs.remove(department);
//     _filteredKeys = _departments.keys.toList();
//     saveToPrefs();
//     notifyListeners();
//   }

//   void addSubDepartment(String department, String subdepartment) {
//     if (_departments.containsKey(department)) {
//       if (!_departments[department]!.contains(subdepartment)) {
//         _departments[department]!.add(subdepartment);

//         _departmentPdfs.putIfAbsent(department, () => {});
//         _departmentPdfs[department]!.putIfAbsent(subdepartment, () => []);

//         saveToPrefs();
//         notifyListeners();
//       }
//     }
//   }

//   void removeSubDepartment(String department, String subdepartment) {
//     _departments[department]?.remove(subdepartment);
//     _departmentPdfs[department]?.remove(subdepartment);
//     saveToPrefs();
//     notifyListeners();
//   }

//   void filterDepartments(String query) {
//     if (query.isEmpty) {
//       _filteredKeys = _departments.keys.toList();
//     } else {
//       _filteredKeys = _departments.keys
//           .where((key) => key.toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     }
//     notifyListeners();
//   }

//   // --- PDF (Firebase URL) Management ---

//   void addPdfsToSubdepartment(
//       String department, String subdepartment, List<String> pdfUrls) {
//     _departmentPdfs.putIfAbsent(department, () => {});
//     _departmentPdfs[department]!.putIfAbsent(subdepartment, () => []);

//     for (var url in pdfUrls) {
//       if (!_departmentPdfs[department]![subdepartment]!.contains(url)) {
//         _departmentPdfs[department]![subdepartment]!.add(url);
//       }
//     }

//     debugPrint("📄 PDF URLs for [$department > $subdepartment]: "
//         "${_departmentPdfs[department]![subdepartment]}");

//     saveToPrefs();
//     notifyListeners();
//   }

//   List<String> getPdfsForSubdepartment(String department, String subdepartment) {
//     return _departmentPdfs[department]?[subdepartment] ?? [];
//   }

//   void removePdfFromSubdepartment(
//       String department, String subdepartment, String pdfUrl) {
//     _departmentPdfs[department]?[subdepartment]?.remove(pdfUrl);
//     saveToPrefs();
//     notifyListeners();
//   }

//   // --- Persistence (SharedPreferences) ---

//   Future<void> saveToPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     prefs.setString('departments', jsonEncode(_departments));
//     prefs.setString('departmentPdfs', jsonEncode(_departmentPdfs));
//   }

//   Future<void> loadFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();

//     String? data = prefs.getString('departments');
//     if (data != null) {
//       _departments = Map<String, List<String>>.from(
//         jsonDecode(data).map((k, v) => MapEntry(k, List<String>.from(v))),
//       );
//     } else {
//       _departments = {};
//     }
//     _filteredKeys = _departments.keys.toList();

//     String? pdfData = prefs.getString('departmentPdfs');
//     if (pdfData != null) {
//       _departmentPdfs = Map<String, Map<String, List<String>>>.from(
//         jsonDecode(pdfData).map((deptKey, subMap) => MapEntry(
//             deptKey,
//             Map<String, List<String>>.from(subMap.map((subKey, pdfList) =>
//                 MapEntry(subKey, List<String>.from(pdfList)))))),
//       );
//     } else {
//       _departmentPdfs = {};
//     }

//     notifyListeners();
//   }

//   /// Optional: Clear all saved data (e.g., on logout)
//   Future<void> clearAllData() async {
//     _departments.clear();
//     _departmentPdfs.clear();
//     _filteredKeys.clear();

//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('departments');
//     await prefs.remove('departmentPdfs');

//     notifyListeners();
//   }
// }






// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class DepartmentProvider extends ChangeNotifier {
//   Map<String, List<String>> _departments = {};
//   Map<String, Map<String, List<String>>> _departmentPdfs = {};
//   List<String> _filteredKeys = [];


//   // ✅ This is the missing getter your `home.dart` needs
//   List<String> get departmentKeys => _departments.keys.toList();


//   Map<String, List<String>> get departments => _departments;
//   Map<String, Map<String, List<String>>> get departmentPdfs => _departmentPdfs;
//   List<String> get filteredKeys => _filteredKeys;

//   // Load from SharedPreferences (cached)
//   Future<void> loadFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final deptJson = prefs.getString('departments');
//     final pdfJson = prefs.getString('departmentPdfs');

//     if (deptJson != null && pdfJson != null) {
//       _departments = Map<String, List<String>>.from(
//         jsonDecode(deptJson).map((key, value) => MapEntry(key, List<String>.from(value))),
//       );

//       _departmentPdfs = Map<String, Map<String, List<String>>>.from(
//         jsonDecode(pdfJson).map((dept, subMap) {
//           return MapEntry(dept, Map<String, List<String>>.from(
//             subMap.map((sub, urls) => MapEntry(sub, List<String>.from(urls)))
//           ));
//         }),
//       );

//       _filteredKeys = _departments.keys.toList();
//       notifyListeners();
//     }
//   }

//   // Save to SharedPreferences
//   Future<void> saveToPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('departments', jsonEncode(_departments));
//     await prefs.setString('departmentPdfs', jsonEncode(_departmentPdfs));
//   }

//   // 🔥 Fetch from Firestore (Main source)
//   Future<void> fetchFromFirestore() async {
//   try {
//     final firestore = FirebaseFirestore.instance;
//     final snapshot = await firestore.collection('departments').get();

//     Map<String, List<String>> departments = {};
//     Map<String, Map<String, List<String>>> departmentPdfs = {};

//     for (var doc in snapshot.docs) {
//       final deptName = doc.id;
//       final subDeptSnap = await firestore
//           .collection('departments')
//           .doc(deptName)
//           .collection('subdepartments')
//           .get();

//       List<String> subDepartments = [];
//       Map<String, List<String>> subDeptPdfs = {};

//       for (var subDoc in subDeptSnap.docs) {
//         final subDeptName = subDoc.id;
//         final pdfList = subDoc.data()['pdfs'] ?? [];
//         subDepartments.add(subDeptName);
//         subDeptPdfs[subDeptName] = List<String>.from(pdfList);
//       }

//       departments[deptName] = subDepartments;
//       departmentPdfs[deptName] = subDeptPdfs;
//     }

//     _departments = departments;
//     _departmentPdfs = departmentPdfs;
//     _filteredKeys = departments.keys.toList();

//     await saveToPrefs();
//     notifyListeners();
//   } catch (e) {
//     debugPrint("❌ Firestore fetch error: $e");
//   }
// }


//   void filterDepartments(String query) {
//     if (query.isEmpty) {
//       _filteredKeys = _departments.keys.toList();
//     } else {
//       _filteredKeys = _departments.keys
//           .where((key) => key.toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     }
//     notifyListeners();
//   }

//   void addDepartment(String department) {
//   if (!_departments.containsKey(department)) {
//     _departments[department] = [];
//     notifyListeners();
//     saveToPrefs();
//   }
// }

// void removeDepartment(String department) {
//   _departments.remove(department);
//   _departmentPdfs.remove(department);
//   notifyListeners();
//   saveToPrefs();
// }

// void addSubDepartment(String department, String subDepartment) {
//   if (_departments[department] == null) return;
//   if (!_departments[department]!.contains(subDepartment)) {
//     _departments[department]!.add(subDepartment);
//     notifyListeners();
//     saveToPrefs();
//   }
// }

// void removeSubDepartment(String department, String subDepartment) {
//   _departments[department]?.remove(subDepartment);
//   _departmentPdfs[department]?.remove(subDepartment);
//   notifyListeners();
//   saveToPrefs();
// }

// void addPdfsToSubdepartment(String department, String subDepartment, List<String> urls) {
//   _departmentPdfs[department] ??= {};
//   _departmentPdfs[department]![subDepartment] ??= [];
//   _departmentPdfs[department]![subDepartment]!.addAll(urls);
//   notifyListeners();
//   saveToPrefs();
// }

// List<String>? getPdfsForSubdepartment(String department, String subDepartment) {
//   return _departmentPdfs[department]?[subDepartment];
// }

// void removePdfFromSubdepartment(String department, String subDepartment, String url) {
//   _departmentPdfs[department]?[subDepartment]?.remove(url);
//   notifyListeners();
//   saveToPrefs();
// }

// }



import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentProvider with ChangeNotifier {
  Map<String, List<String>> _departments = {};
  Map<String, Map<String, List<String>>> _pdfs = {};
  List<String> _filteredDepartmentKeys = [];

  Map<String, List<String>> get departments => _departments;
  List<String> get departmentKeys => _filteredDepartmentKeys.isNotEmpty ? _filteredDepartmentKeys : _departments.keys.toList();

  DepartmentProvider() {
    _filteredDepartmentKeys = [];
  }

  Future<void> fetchFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('departments').get();
      final Map<String, List<String>> tempDepartments = {};
      final Map<String, Map<String, List<String>>> tempPdfs = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final deptName = data['name'] as String? ?? doc.id; // Fallback to doc ID
        final subdepartments = List<String>.from(data['subdepartments'] ?? []);
        tempDepartments[deptName] = subdepartments;

        // Initialize PDFs map for this department
        tempPdfs[deptName] = {};
        final pdfData = data['pdfs'] as Map<String, dynamic>? ?? {};
        for (var subdept in subdepartments) {
          tempPdfs[deptName]![subdept] = List<String>.from(pdfData[subdept] ?? []);
        }
      }

      _departments = tempDepartments;
      _pdfs = tempPdfs;
      _filteredDepartmentKeys = _departments.keys.toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      rethrow; // Rethrow for debugging
    }
  }

  void addDepartment(String deptName) async {
    if (!_departments.containsKey(deptName)) {
      _departments[deptName] = [];
      _pdfs[deptName] = {};
      _filteredDepartmentKeys = _departments.keys.toList();
      notifyListeners();

     FirebaseFirestore.instance.collection('departments').doc(deptName).set({
        'name': deptName,
        'subdepartments': [],
        'timestamp': FieldValue.serverTimestamp(),
      }).catchError((e) {
        debugPrint('Error adding department: $e');
      });
    }
  }

  void addSubDepartment(String deptName, String subDeptName) async {
    if (_departments.containsKey(deptName) && !_departments[deptName]!.contains(subDeptName)) {
      _departments[deptName]!.add(subDeptName);
      _pdfs[deptName] ??= {};
      _pdfs[deptName]![subDeptName] = [];
      _filteredDepartmentKeys = _departments.keys.toList();
      notifyListeners();

      final docRef = FirebaseFirestore.instance.collection('departments').doc(deptName);
      await docRef.update({
        'subdepartments': FieldValue.arrayUnion([subDeptName]),
      }).catchError((e) {
        debugPrint('Error updating subdepartments: $e');
      });
    }
  }

  void addPdfsToSubdepartment(String deptName, String subDeptName, List<String> pdfUrls) async {
    if (_departments.containsKey(deptName) && _departments[deptName]!.contains(subDeptName)) {
      _pdfs[deptName] ??= {};
      _pdfs[deptName]![subDeptName] ??= [];
      _pdfs[deptName]![subDeptName]!.addAll(pdfUrls);
      notifyListeners();

      final docRef = FirebaseFirestore.instance.collection('departments').doc(deptName);
      await docRef.update({
        'pdfs.$subDeptName': FieldValue.arrayUnion(pdfUrls),
      }).catchError((e) {
        debugPrint('Error adding PDFs: $e');
      });
    }
  }

  List<String>? getPdfsForSubdepartment(String deptName, String subDeptName) {
    return _pdfs[deptName]?[subDeptName];
  }

  void removeSubDepartment(String deptName, String subDeptName) async {
    if (_departments.containsKey(deptName)) {
      _departments[deptName]!.remove(subDeptName);
      _pdfs[deptName]?.remove(subDeptName);
      _filteredDepartmentKeys = _departments.keys.toList();
      notifyListeners();

      final docRef = FirebaseFirestore.instance.collection('departments').doc(deptName);
      await docRef.update({
        'subdepartments': FieldValue.arrayRemove([subDeptName]),
        'pdfs.$subDeptName': FieldValue.delete(),
      }).catchError((e) {
        debugPrint('Error removing subdepartment: $e');
      });
    }
  }

  void removePdfFromSubdepartment(String deptName, String subDeptName, String pdfUrl) async {
    if (_pdfs.containsKey(deptName) && _pdfs[deptName]!.containsKey(subDeptName)) {
      _pdfs[deptName]![subDeptName]!.remove(pdfUrl);
      notifyListeners();

      final docRef = FirebaseFirestore.instance.collection('departments').doc(deptName);
      await docRef.update({
        'pdfs.$subDeptName': _pdfs[deptName]![subDeptName],
      }).catchError((e) {
        debugPrint('Error removing PDF: $e');
      });
    }
  }

  void removeDepartment(String deptName) async {
    _departments.remove(deptName);
    _pdfs.remove(deptName);
    _filteredDepartmentKeys = _departments.keys.toList();
    notifyListeners();

    await FirebaseFirestore.instance.collection('departments').doc(deptName).delete().catchError((e) {
      debugPrint('Error deleting department: $e');
    });
  }

  void filterDepartments(String query) {
    if (query.isEmpty) {
      _filteredDepartmentKeys = _departments.keys.toList();
    } else {
      _filteredDepartmentKeys = _departments.keys
          .where((dept) => dept.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}
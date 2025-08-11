import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'chat.dart';
import 'settings.dart';
import 'epartment_provider.dart';

enum SortOption { alphabetical, newest, oldest }
enum SearchType { all, departments, subdepartments, pdfs }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController searchController = TextEditingController();
  SortOption _currentSortOption = SortOption.alphabetical;
  SearchType _currentSearchType = SearchType.all;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<DepartmentProvider>().fetchFromFirestore();
    });
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
        _buildDepartmentsScreen(),
        const ChatScreen(departmentName: 'General Help'),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ChatScreen(departmentName: 'General Help'),
                  ),
                );
              },
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.chat),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        backgroundColor: Colors.deepPurple.shade800,
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDepartmentsScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Shasan Mitra",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 254, 255),
              ),
            ),
            const SizedBox(height: 10),
            _buildSearchAndFilterSection(),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<DepartmentProvider>(
                builder: (context, provider, _) {
                  if (searchController.text.isEmpty) {
                    return _buildDepartmentGrid(provider);
                  } else {
                    return _buildSearchResults(provider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: _getSearchHint(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              context.read<DepartmentProvider>().filterDepartments('');
                            });
                          },
                        )
                      : IconButton(
                          icon: Icon(_isSearchExpanded ? Icons.expand_less : Icons.tune),
                          onPressed: () {
                            setState(() {
                              _isSearchExpanded = !_isSearchExpanded;
                            });
                          },
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    context.read<DepartmentProvider>().filterDepartments(value);
                  });
                },
              ),
            ),
          ],
        ),
        if (_isSearchExpanded) _buildExpandedSearchOptions(),
      ],
    );
  }

  Widget _buildExpandedSearchOptions() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search In:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SearchType.values.map((type) {
              return ChoiceChip(
                label: Text(_getSearchTypeLabel(type)),
                selected: _currentSearchType == type,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentSearchType = type;
                      if (searchController.text.isNotEmpty) {
                        context.read<DepartmentProvider>().filterDepartments(searchController.text);
                      }
                    });
                  }
                },
                selectedColor: Colors.deepPurple.shade200,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sort By:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: SortOption.values.map((option) {
              return ChoiceChip(
                label: Text(_getSortOptionLabel(option)),
                selected: _currentSortOption == option,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentSortOption = option;
                    });
                  }
                },
                selectedColor: Colors.deepPurple.shade200,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getSearchHint() {
    switch (_currentSearchType) {
      case SearchType.departments:
        return 'Search Departments...';
      case SearchType.subdepartments:
        return 'Search Sub-departments...';
      case SearchType.pdfs:
        return 'Search PDFs...';
      case SearchType.all:
      default:
        return 'Search Departments, Sub-departments, PDFs...';
    }
  }

  String _getSearchTypeLabel(SearchType type) {
    switch (type) {
      case SearchType.all:
        return 'All';
      case SearchType.departments:
        return 'Departments';
      case SearchType.subdepartments:
        return 'Sub-departments';
      case SearchType.pdfs:
        return 'PDFs';
    }
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.alphabetical:
        return 'A-Z';
      case SortOption.newest:
        return 'Newest';
      case SortOption.oldest:
        return 'Oldest';
    }
  }

  Widget _buildDepartmentGrid(DepartmentProvider provider) {
    final departments = _sortDepartments(provider.departmentKeys);

    if (departments.isEmpty) {
      return const Center(
        child: Text(
          'No departments found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return GridView.builder(
      itemCount: departments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final dept = departments[index];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final subs = provider.departments[dept] ?? [];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubDepartmentScreen(
                  departmentName: dept,
                  subDepartments: subs,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.shade400.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(4, 6),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  dept,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(DepartmentProvider provider) {
    final searchQuery = searchController.text.toLowerCase();
    List<SearchResult> results = [];

    // Search in departments
    if (_currentSearchType == SearchType.all || _currentSearchType == SearchType.departments) {
      for (String dept in provider.departmentKeys) {
        if (dept.toLowerCase().contains(searchQuery)) {
          results.add(SearchResult(
            title: dept,
            subtitle: 'Department',
            type: SearchResultType.department,
            departmentName: dept,
          ));
        }
      }
    }

    // Search in sub-departments
    if (_currentSearchType == SearchType.all || _currentSearchType == SearchType.subdepartments) {
      provider.departments.forEach((dept, subs) {
        for (String sub in subs) {
          if (sub.toLowerCase().contains(searchQuery)) {
            results.add(SearchResult(
              title: sub,
              subtitle: 'Sub-department in $dept',
              type: SearchResultType.subdepartment,
              departmentName: dept,
              subdepartmentName: sub,
            ));
          }
        }
      });
    }

    // Search in PDFs
    if (_currentSearchType == SearchType.all || _currentSearchType == SearchType.pdfs) {
      provider.departments.forEach((dept, subs) {
        for (String sub in subs) {
          final pdfs = provider.getPdfsForSubdepartment(dept, sub) ?? [];
          for (String pdf in pdfs) {
            final pdfName = pdf.split('/').last;
            if (pdfName.toLowerCase().contains(searchQuery)) {
              results.add(SearchResult(
                title: pdfName,
                subtitle: 'PDF in $dept > $sub',
                type: SearchResultType.pdf,
                departmentName: dept,
                subdepartmentName: sub,
                pdfPath: pdf,
              ));
            }
          }
        }
      });
    }

    results = _sortSearchResults(results);

    if (results.isEmpty) {
      return const Center(
        child: Text(
          'No results found.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(_getIconForSearchResult(result.type)),
            title: Text(result.title),
            subtitle: Text(result.subtitle),
            onTap: () => _handleSearchResultTap(context, result, provider),
          ),
        );
      },
    );
  }

  List<String> _sortDepartments(List<String> departments) {
    List<String> sorted = List.from(departments);
    switch (_currentSortOption) {
      case SortOption.alphabetical:
        sorted.sort();
        break;
      case SortOption.newest:
      case SortOption.oldest:
        // For now, just use alphabetical. In a real app, you'd sort by date
        sorted.sort();
        if (_currentSortOption == SortOption.oldest) {
          sorted = sorted.reversed.toList();
        }
        break;
    }
    return sorted;
  }

  List<SearchResult> _sortSearchResults(List<SearchResult> results) {
    switch (_currentSortOption) {
      case SortOption.alphabetical:
        results.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.newest:
      case SortOption.oldest:
        // For now, just use alphabetical. In a real app, you'd sort by date
        results.sort((a, b) => a.title.compareTo(b.title));
        if (_currentSortOption == SortOption.oldest) {
          results = results.reversed.toList();
        }
        break;
    }
    return results;
  }

  IconData _getIconForSearchResult(SearchResultType type) {
    switch (type) {
      case SearchResultType.department:
        return Icons.folder;
      case SearchResultType.subdepartment:
        return Icons.folder_open;
      case SearchResultType.pdf:
        return Icons.picture_as_pdf;
    }
  }

  void _handleSearchResultTap(BuildContext context, SearchResult result, DepartmentProvider provider) {
    switch (result.type) {
      case SearchResultType.department:
        final subs = provider.departments[result.departmentName!] ?? [];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SubDepartmentScreen(
              departmentName: result.departmentName!,
              subDepartments: subs,
            ),
          ),
        );
        break;
      case SearchResultType.subdepartment:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfListScreen(
              departmentName: result.departmentName!,
              subdepartmentName: result.subdepartmentName!,
            ),
          ),
        );
        break;
      case SearchResultType.pdf:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(pdfUrl: result.pdfPath!),
          ),
        );
        break;
    }
  }
}

enum SearchResultType { department, subdepartment, pdf }

class SearchResult {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final String? departmentName;
  final String? subdepartmentName;
  final String? pdfPath;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    this.departmentName,
    this.subdepartmentName,
    this.pdfPath,
  });
}

class SubDepartmentScreen extends StatefulWidget {
  final String departmentName;
  final List<String> subDepartments;

  const SubDepartmentScreen({
    super.key,
    required this.departmentName,
    required this.subDepartments,
  });

  @override
  State<SubDepartmentScreen> createState() => _SubDepartmentScreenState();
}

class _SubDepartmentScreenState extends State<SubDepartmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSubDepartments = [];
  SortOption _sortOption = SortOption.alphabetical;

  @override
  void initState() {
    super.initState();
    _filteredSubDepartments = List.from(widget.subDepartments);
    _sortSubDepartments();
  }

  void _filterSubDepartments(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSubDepartments = List.from(widget.subDepartments);
      } else {
        _filteredSubDepartments = widget.subDepartments
            .where((sub) => sub.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _sortSubDepartments();
    });
  }

  void _sortSubDepartments() {
    switch (_sortOption) {
      case SortOption.alphabetical:
        _filteredSubDepartments.sort();
        break;
      case SortOption.newest:
      case SortOption.oldest:
        _filteredSubDepartments.sort();
        if (_sortOption == SortOption.oldest) {
          _filteredSubDepartments = _filteredSubDepartments.reversed.toList();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.departmentName),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption option) {
              setState(() {
                _sortOption = option;
                _sortSubDepartments();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('Sort A-Z'),
              ),
              const PopupMenuItem(
                value: SortOption.newest,
                child: Text('Sort Newest'),
              ),
              const PopupMenuItem(
                value: SortOption.oldest,
                child: Text('Sort Oldest'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5E35B1), Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Sub-departments...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterSubDepartments('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterSubDepartments,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredSubDepartments.length,
                itemBuilder: (context, index) {
                  final subDept = _filteredSubDepartments[index];
                  return Card(
                    color: Colors.white.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        subDept,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 18, color: Colors.deepPurple),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfListScreen(
                              departmentName: widget.departmentName,
                              subdepartmentName: subDept,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfListScreen extends StatefulWidget {
  final String departmentName;
  final String subdepartmentName;

  const PdfListScreen({
    super.key,
    required this.departmentName,
    required this.subdepartmentName,
  });

  @override
  State<PdfListScreen> createState() => _PdfListScreenState();
}

class _PdfListScreenState extends State<PdfListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredPdfs = [];
  SortOption _sortOption = SortOption.alphabetical;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DepartmentProvider>(context, listen: false);
    final pdfList = provider.getPdfsForSubdepartment(
            widget.departmentName, widget.subdepartmentName) ??
        [];
    _filteredPdfs = List.from(pdfList);
    _sortPdfs();
  }

  void _filterPdfs(String query) {
    final provider = Provider.of<DepartmentProvider>(context, listen: false);
    final pdfList = provider.getPdfsForSubdepartment(
            widget.departmentName, widget.subdepartmentName) ??
        [];

    setState(() {
      if (query.isEmpty) {
        _filteredPdfs = List.from(pdfList);
      } else {
        _filteredPdfs = pdfList
            .where((pdf) => pdf
                .split('/')
                .last
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
      _sortPdfs();
    });
  }

  void _sortPdfs() {
    switch (_sortOption) {
      case SortOption.alphabetical:
        _filteredPdfs
            .sort((a, b) => a.split('/').last.compareTo(b.split('/').last));
        break;
      case SortOption.newest:
      case SortOption.oldest:
        _filteredPdfs
            .sort((a, b) => a.split('/').last.compareTo(b.split('/').last));
        if (_sortOption == SortOption.oldest) {
          _filteredPdfs = _filteredPdfs.reversed.toList();
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.departmentName} > ${widget.subdepartmentName} PDFs'),
        backgroundColor: Colors.deepPurple,
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOption option) {
              setState(() {
                _sortOption = option;
                _sortPdfs();
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: SortOption.alphabetical,
                child: Text('Sort A-Z'),
              ),
              const PopupMenuItem(
                value: SortOption.newest,
                child: Text('Sort Newest'),
              ),
              const PopupMenuItem(
                value: SortOption.oldest,
                child: Text('Sort Oldest'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF512DA8), Color(0xFF673AB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search PDFs...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterPdfs('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _filterPdfs,
              ),
            ),
            Expanded(
              child: _filteredPdfs.isEmpty
                  ? const Center(
                      child: Text(
                        'No PDFs found.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredPdfs.length,
                      itemBuilder: (context, index) {
                        final pdfPath = _filteredPdfs[index];
                        final pdfName = pdfPath.split('/').last;
                        final pdfUrl = pdfPath;

                        return Card(
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.picture_as_pdf,
                                color: Colors.red),
                            title: Text(
                              pdfName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PdfViewerScreen(pdfUrl: pdfUrl),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    final pdfName = Uri.decodeFull(pdfUrl.split('/').last.split('?').first);
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfName),
        backgroundColor: Colors.deepPurple,
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}

















// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// import 'chat.dart';
// import 'settings.dart';
// import 'epartment_provider.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   final TextEditingController searchController = TextEditingController();

//  @override
// void initState() {
//   super.initState();
//   Future.microtask(() async {
//     await context.read<DepartmentProvider>().fetchFromFirestore();
//   });
// }


//   void _onNavTap(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   List<Widget> get _screens => [
//         _buildDepartmentsScreen(),
//         const ChatScreen(departmentName: 'General Help'),
//         const SettingsScreen(),
//       ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(child: _screens[_selectedIndex]),
//       floatingActionButton: _selectedIndex == 0
//           ? FloatingActionButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) =>
//                         const ChatScreen(departmentName: 'General Help'),
//                   ),
//                 );
//               },
//               backgroundColor: Colors.deepPurple,
//               child: const Icon(Icons.chat),
//             )
//           : null,
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onNavTap,
//         backgroundColor: Colors.deepPurple.shade800,
//         selectedItemColor: Colors.amberAccent,
//         unselectedItemColor: Colors.white70,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
//           BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
//         ],
//       ),
//     );
//   }

//   Widget _buildDepartmentsScreen() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text(
//               "Shasan Mitra",
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//                 color: Color.fromARGB(255, 255, 254, 255),
//               ),
//             ),
//             const SizedBox(height: 10),
//             TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search Department...',
//                 prefixIcon: const Icon(Icons.search),
//                 filled: true,
//                 fillColor: Colors.white,
//                 contentPadding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(30),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//               onChanged: (value) {
//                 context.read<DepartmentProvider>().filterDepartments(value);
//               },
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: Consumer<DepartmentProvider>(
//                 builder: (context, provider, _) {
//                   final departments = provider.departmentKeys;

//                   if (departments.isEmpty) {
//                     return const Center(
//                       child: Text(
//                         'No departments found.',
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     );
//                   }

//                   return GridView.builder(
//                     itemCount: departments.length,
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       mainAxisSpacing: 18,
//                       crossAxisSpacing: 18,
//                       childAspectRatio: 1.1,
//                     ),
//                     itemBuilder: (context, index) {
//                       final dept = departments[index];
//                       return InkWell(
//                         borderRadius: BorderRadius.circular(20),
//                         onTap: () {
//                           final subs = provider.departments[dept] ?? [];
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => SubDepartmentScreen(
//                                 departmentName: dept,
//                                 subDepartments: subs,
//                               ),
//                             ),
//                           );
//                         },
//                         child: Container(
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Color(0xFF9575CD), Color(0xFF7E57C2)],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.deepPurple.shade400.withOpacity(0.5),
//                                 blurRadius: 10,
//                                 offset: const Offset(4, 6),
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 8),
//                               child: Text(
//                                 dept,
//                                 textAlign: TextAlign.center,
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class SubDepartmentScreen extends StatelessWidget {
//   final String departmentName;
//   final List<String> subDepartments;

//   const SubDepartmentScreen({
//     super.key,
//     required this.departmentName,
//     required this.subDepartments,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(departmentName),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF5E35B1), Color(0xFF7C4DFF)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: subDepartments.length,
//           itemBuilder: (context, index) {
//             final subDept = subDepartments[index];
//             return Card(
//               color: Colors.white.withOpacity(0.95),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 title: Text(
//                   subDept,
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 trailing: const Icon(Icons.arrow_forward_ios,
//                     size: 18, color: Colors.deepPurple),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => PdfListScreen(
//                         departmentName: departmentName,
//                         subdepartmentName: subDept,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class PdfListScreen extends StatelessWidget {
//   final String departmentName;
//   final String subdepartmentName;

//   const PdfListScreen({
//     super.key,
//     required this.departmentName,
//     required this.subdepartmentName,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<DepartmentProvider>(context);
//     final pdfList = provider.getPdfsForSubdepartment(departmentName, subdepartmentName) ?? [];

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('$departmentName > $subdepartmentName PDFs'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF512DA8), Color(0xFF673AB7)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: pdfList.isEmpty
//             ? const Center(
//                 child: Text(
//                   'No PDFs uploaded for this subdepartment.',
//                   style: TextStyle(color: Colors.white70, fontSize: 16),
//                 ),
//               )
//             : ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: pdfList.length,
//                 itemBuilder: (context, index) {
//                   final pdfPath = pdfList[index];
//                   final pdfName = pdfPath.split('/').last;
//                   final pdfUrl = pdfPath;

//                   return Card(
//                     color: Colors.white.withOpacity(0.95),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: ListTile(
//                       leading:
//                           const Icon(Icons.picture_as_pdf, color: Colors.red),
//                       title: Text(
//                         pdfName,
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => PdfViewerScreen(pdfUrl: pdfUrl),
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }

// class PdfViewerScreen extends StatelessWidget {
//   final String pdfUrl;

//   const PdfViewerScreen({super.key, required this.pdfUrl});

//   @override
//   Widget build(BuildContext context) {
//     final pdfName = Uri.decodeFull(pdfUrl.split('/').last.split('?').first);
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(pdfName),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: SfPdfViewer.network(pdfUrl),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database.dart';
import '../models/content_models.dart';
import 'sidebar.dart';
import 'editor_page.dart';
import '../services/export_service.dart';
import '../services/search_service.dart';

class AccountingNotebookApp extends StatefulWidget {
  const AccountingNotebookApp({super.key});

  @override
  State<AccountingNotebookApp> createState() => _AccountingNotebookAppState();
}

class _AccountingNotebookAppState extends State<AccountingNotebookApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppDatabase _database = AppDatabase.instance;
  final ExportService _exportService = ExportService();
  final SearchService _searchService = SearchService();
  
  Subject? _selectedSubject;
  Lesson? _selectedLesson;
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _database.getAllSubjects();
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load subjects: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _createSubject() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Subject'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Subject Title',
            hintText: 'e.g., Financial Accounting',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final subject = Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result,
        description: null,
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _database.insertSubject(subject);
        await _loadSubjects();
        _showSuccess('Subject created successfully');
      } catch (e) {
        _showError('Failed to create subject: $e');
      }
    }
  }

  Future<void> _createLesson() async {
    if (_selectedSubject == null) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Lesson'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Lesson Title',
            hintText: 'e.g., Depreciation Methods',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final lesson = Lesson(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        subjectId: _selectedSubject!.id,
        title: result,
        tags: [],
        content: '[]', // Empty Quill Delta
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _database.insertLesson(lesson);
        final newLesson = await _database.getLesson(lesson.id);
        setState(() {
          _selectedLesson = newLesson;
        });
        _showSuccess('Lesson created successfully');
      } catch (e) {
        _showError('Failed to create lesson: $e');
      }
    }
  }

  Future<void> _exportData() async {
    try {
      await _exportService.exportToJson(_database);
      _showSuccess('Data exported successfully');
    } catch (e) {
      _showError('Failed to export data: $e');
    }
  }

  Future<void> _importData() async {
    try {
      await _exportService.importFromJson(_database);
      await _loadSubjects();
      _showSuccess('Data imported successfully');
    } catch (e) {
      _showError('Failed to import data: $e');
    }
  }

  void _onSubjectSelected(Subject subject) {
    setState(() {
      _selectedSubject = subject;
      _selectedLesson = null;
    });
  }

  void _onLessonSelected(Lesson lesson) {
    setState(() {
      _selectedLesson = lesson;
    });
  }

  Widget _buildMainContent() {
    if (_selectedLesson != null) {
      return EditorPage(
        lesson: _selectedLesson!,
        database: _database,
        onLessonUpdated: (lesson) {
          setState(() {
            _selectedLesson = lesson;
          });
        },
      );
    } else if (_selectedSubject != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a lesson or create a new one',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createLesson,
              icon: const Icon(Icons.add),
              label: const Text('Create New Lesson'),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a subject to get started',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createSubject,
              icon: const Icon(Icons.add),
              label: const Text('Create New Subject'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Accounting Notebook'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportData();
                  break;
                case 'import':
                  _importData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.upload),
                  title: Text('Import Data'),
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Sidebar(
        subjects: _subjects,
        selectedSubject: _selectedSubject,
        selectedLesson: _selectedLesson,
        database: _database,
        onSubjectSelected: _onSubjectSelected,
        onLessonSelected: _onLessonSelected,
        onCreateSubject: _createSubject,
        onCreateLesson: _createLesson,
        isLoading: _isLoading,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
      floatingActionButton: _selectedSubject != null && _selectedLesson == null
          ? FloatingActionButton(
              onPressed: _createLesson,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

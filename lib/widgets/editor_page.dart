import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/database.dart';
import '../models/content_models.dart';
import 'rich_text_editor.dart';

class EditorPage extends StatefulWidget {
  final Lesson lesson;
  final AppDatabase database;
  final Function(Lesson) onLessonUpdated;

  const EditorPage({
    super.key,
    required this.lesson,
    required this.database,
    required this.onLessonUpdated,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late Lesson _currentLesson;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
  }

  @override
  void didUpdateWidget(EditorPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id) {
      _currentLesson = widget.lesson;
      _hasUnsavedChanges = false;
    }
  }

  Future<void> _saveLesson(String content) async {
    try {
      final updatedLesson = _currentLesson.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );

      await widget.database.updateLesson(updatedLesson);
      
      final refreshedLesson = await widget.database.getLesson(_currentLesson.id);
      setState(() {
        _currentLesson = refreshedLesson ?? _currentLesson;
        _hasUnsavedChanges = false;
      });
      
      widget.onLessonUpdated(_currentLesson);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save lesson: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _editLessonTitle() async {
    final controller = TextEditingController(text: _currentLesson.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Lesson Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _currentLesson.title) {
      try {
        final updatedLesson = _currentLesson.copyWith(
          title: result,
          updatedAt: DateTime.now(),
        );

        await widget.database.updateLesson(updatedLesson);
        final refreshedLesson = await widget.database.getLesson(_currentLesson.id);
        setState(() {
          _currentLesson = refreshedLesson ?? _currentLesson;
        });
        widget.onLessonUpdated(_currentLesson);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update title: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lesson header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentLesson.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _editLessonTitle,
                          tooltip: 'Edit title',
                        ),
                      ],
                    ),
                    if (_currentLesson.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _currentLesson.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (_hasUnsavedChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Unsaved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Editor
        Expanded(
          child: RichTextEditor(
            initialContent: _currentLesson.content,
            database: widget.database,
            lessonId: _currentLesson.id,
            onContentChanged: _onContentChanged,
            onSave: _saveLesson,
          ),
        ),
      ],
    );
  }
}

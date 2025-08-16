import 'package:flutter/material.dart';
import '../models/database.dart';
import '../models/content_models.dart';

class Sidebar extends StatefulWidget {
  final List<Subject> subjects;
  final Subject? selectedSubject;
  final Lesson? selectedLesson;
  final AppDatabase database;
  final Function(Subject) onSubjectSelected;
  final Function(Lesson) onLessonSelected;
  final VoidCallback onCreateSubject;
  final VoidCallback onCreateLesson;
  final bool isLoading;

  const Sidebar({
    super.key,
    required this.subjects,
    this.selectedSubject,
    this.selectedLesson,
    required this.database,
    required this.onSubjectSelected,
    required this.onLessonSelected,
    required this.onCreateSubject,
    required this.onCreateLesson,
    this.isLoading = false,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  Map<String, List<Lesson>> _subjectLessons = {};
  Set<String> _expandedSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjects != widget.subjects) {
      _loadLessons();
    }
  }

  Future<void> _loadLessons() async {
    final Map<String, List<Lesson>> lessons = {};
    for (final subject in widget.subjects) {
      try {
        lessons[subject.id] = await widget.database.getLessonsForSubject(subject.id);
      } catch (e) {
        lessons[subject.id] = [];
      }
    }
    setState(() {
      _subjectLessons = lessons;
    });
  }

  void _toggleExpanded(String subjectId) {
    setState(() {
      if (_expandedSubjects.contains(subjectId)) {
        _expandedSubjects.remove(subjectId);
      } else {
        _expandedSubjects.add(subjectId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subjects & Lessons',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organize your accounting notes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No subjects yet',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: widget.onCreateSubject,
                              icon: const Icon(Icons.add),
                              label: const Text('Create Subject'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.subjects.length,
                        itemBuilder: (context, index) {
                          final subject = widget.subjects[index];
                          final lessons = _subjectLessons[subject.id] ?? [];
                          final isExpanded = _expandedSubjects.contains(subject.id);
                          final isSelected = widget.selectedSubject?.id == subject.id;

                          return ExpansionTile(
                            key: ValueKey(subject.id),
                            title: Text(
                              subject.title,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                            subtitle: subject.tags.isNotEmpty
                                ? Wrap(
                                    spacing: 4,
                                    children: subject.tags.take(2).map((tag) => Chip(
                                      label: Text(tag),
                                      visualDensity: VisualDensity.compact,
                                    )).toList(),
                                  )
                                : null,
                            leading: Icon(
                              Icons.folder,
                              color: isSelected ? Theme.of(context).colorScheme.primary : null,
                            ),
                            onExpansionChanged: (expanded) {
                              if (expanded) {
                                _expandedSubjects.add(subject.id);
                                widget.onSubjectSelected(subject);
                              } else {
                                _expandedSubjects.remove(subject.id);
                              }
                            },
                            children: [
                              if (lessons.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    leading: const Icon(Icons.note_add, size: 20),
                                    title: const Text('No lessons yet'),
                                    subtitle: const Text('Create your first lesson'),
                                    onTap: widget.onCreateLesson,
                                    dense: true,
                                  ),
                                )
                              else
                                ...lessons.map((lesson) {
                                  final isLessonSelected = widget.selectedLesson?.id == lesson.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.description,
                                        size: 20,
                                        color: isLessonSelected 
                                            ? Theme.of(context).colorScheme.primary 
                                            : null,
                                      ),
                                      title: Text(
                                        lesson.title,
                                        style: TextStyle(
                                          fontWeight: isLessonSelected 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: isLessonSelected 
                                              ? Theme.of(context).colorScheme.primary 
                                              : null,
                                        ),
                                      ),
                                      subtitle: lesson.tags.isNotEmpty
                                          ? Text(lesson.tags.take(2).join(', '))
                                          : null,
                                      onTap: () => widget.onLessonSelected(lesson),
                                      dense: true,
                                      selected: isLessonSelected,
                                    ),
                                  );
                                }).toList(),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: ListTile(
                                  leading: const Icon(Icons.add, size: 20),
                                  title: const Text('Add Lesson'),
                                  onTap: widget.onCreateLesson,
                                  dense: true,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onCreateSubject,
                icon: const Icon(Icons.add),
                label: const Text('New Subject'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/content_models.dart';
import '../tools/journal_tool.dart';

class JournalEmbed extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onEdit;

  const JournalEmbed({
    super.key,
    required this.data,
    required this.onEdit,
  });

  void _editEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => JournalTool(
        initialData: data,
        onSave: (newData) {
          Navigator.pop(context);
          onEdit(newData);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = JournalEntry.fromJson(data);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.book,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Journal Entry',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(entry.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _editEntry(context),
                  tooltip: 'Edit entry',
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (entry.description.isNotEmpty) ...[
                  Text(
                    entry.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Transaction table
                Table(
                  border: TableBorder.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                  children: [
                    // Header
                    TableRow(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Debit row
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(entry.accountDebit),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('\$${entry.debitAmount.toStringAsFixed(2)}'),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(''),
                        ),
                      ],
                    ),
                    // Credit row
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(entry.accountCredit),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(''),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('\$${entry.creditAmount.toStringAsFixed(2)}'),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Tags
                if (entry.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: entry.tags.map((tag) => Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

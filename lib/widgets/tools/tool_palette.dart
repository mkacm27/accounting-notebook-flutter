import 'package:flutter/material.dart';
import 'journal_tool.dart';
import 'amortization_tool.dart';
import 'custom_table_tool.dart';

class ToolPalette extends StatelessWidget {
  final Function(String, Map<String, dynamic>) onToolSelected;
  final VoidCallback onClose;

  const ToolPalette({
    super.key,
    required this.onToolSelected,
    required this.onClose,
  });

  void _showJournalTool(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => JournalTool(
        onSave: (data) {
          Navigator.pop(context);
          onToolSelected('journal', data);
        },
      ),
    );
  }

  void _showAmortizationTool(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AmortizationTool(
        onSave: (data) {
          Navigator.pop(context);
          onToolSelected('amortization', data);
        },
      ),
    );
  }

  void _showCustomTableTool(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => CustomTableTool(
        onSave: (data) {
          Navigator.pop(context);
          onToolSelected('customTable', data);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Insert Accounting Tool',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ToolOption(
              icon: Icons.book,
              title: 'Journal Entry',
              description: 'Record debit and credit transactions',
              onTap: () => _showJournalTool(context),
            ),
            const SizedBox(height: 12),
            _ToolOption(
              icon: Icons.trending_down,
              title: 'Amortization Schedule',
              description: 'Calculate asset depreciation over time',
              onTap: () => _showAmortizationTool(context),
            ),
            const SizedBox(height: 12),
            _ToolOption(
              icon: Icons.table_chart,
              title: 'Custom Table',
              description: 'Create custom data tables',
              onTap: () => _showCustomTableTool(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ToolOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ToolOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

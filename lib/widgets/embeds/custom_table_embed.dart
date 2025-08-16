import 'package:flutter/material.dart';
import '../../models/content_models.dart';
import '../tools/custom_table_tool.dart';

class CustomTableEmbed extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onEdit;

  const CustomTableEmbed({
    super.key,
    required this.data,
    required this.onEdit,
  });

  void _editTable(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CustomTableTool(
        initialData: data,
        onSave: (newData) {
          Navigator.pop(context);
          onEdit(newData);
        },
      ),
    );
  }

  String _formatCellValue(dynamic value, String type) {
    if (value == null || value.toString().isEmpty) return '';
    
    switch (type) {
      case 'currency':
        final numValue = double.tryParse(value.toString()) ?? 0.0;
        return '\$${numValue.toStringAsFixed(2)}';
      case 'number':
        final numValue = double.tryParse(value.toString()) ?? 0.0;
        return numValue.toString();
      case 'date':
        // Assume date is in ISO format or simple date string
        try {
          final date = DateTime.parse(value.toString());
          return '${date.month}/${date.day}/${date.year}';
        } catch (e) {
          return value.toString();
        }
      default:
        return value.toString();
    }
  }

  Color _getCellBackgroundColor(String type, BuildContext context) {
    switch (type) {
      case 'currency':
        return Colors.green.withOpacity(0.05);
      case 'number':
        return Colors.blue.withOpacity(0.05);
      case 'date':
        return Colors.orange.withOpacity(0.05);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableData = CustomTableData.fromJson(data);

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
                  Icons.table_chart,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tableData.name.isNotEmpty ? tableData.name : 'Custom Table',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _editTable(context),
                  tooltip: 'Edit table',
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
                // Table
                if (tableData.columns.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 48,
                      ),
                      child: Table(
                        border: TableBorder.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        children: [
                          // Header row
                          TableRow(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            children: tableData.columns.map((column) {
                              return Container(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      column.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '(${column.type})',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          
                          // Data rows
                          ...tableData.rows.map((row) {
                            return TableRow(
                              children: row.asMap().entries.map((entry) {
                                final colIndex = entry.key;
                                final cellValue = entry.value;
                                final column = colIndex < tableData.columns.length 
                                    ? tableData.columns[colIndex] 
                                    : TableColumn(name: 'Unknown', type: 'text');
                                
                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  color: _getCellBackgroundColor(column.type, context),
                                  child: Text(
                                    _formatCellValue(cellValue, column.type),
                                    style: TextStyle(
                                      fontWeight: column.type == 'currency' 
                                          ? FontWeight.w500 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'No columns defined',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Summary
                if (tableData.rows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${tableData.rows.length} rows × ${tableData.columns.length} columns',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                
                // Tags
                if (tableData.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: tableData.tags.map((tag) => Chip(
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

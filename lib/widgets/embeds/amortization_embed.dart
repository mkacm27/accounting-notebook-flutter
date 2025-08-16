import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/content_models.dart';
import '../tools/amortization_tool.dart';

class AmortizationEmbed extends StatelessWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onEdit;

  const AmortizationEmbed({
    super.key,
    required this.data,
    required this.onEdit,
  });

  void _editSchedule(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AmortizationTool(
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
    final schedule = AmortizationSchedule.fromJson(data);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

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
                  Icons.trending_down,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Amortization Schedule',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _editSchedule(context),
                  tooltip: 'Edit schedule',
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
                // Asset summary
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.assetName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Purchase Date: ${dateFormat.format(schedule.purchaseDate)}'),
                          Text('Asset Value: ${currencyFormat.format(schedule.assetValue)}'),
                          Text('Useful Life: ${schedule.usefulLifeYears} years'),
                          Text('Method: ${schedule.method.replaceAll('-', ' ').toUpperCase()}'),
                          Text('Salvage Value: ${currencyFormat.format(schedule.salvageValue)}'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Schedule table (first 5 periods + summary)
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
                          child: Text('Period', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Accumulated', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    // First few periods
                    ...schedule.schedule.take(5).map((period) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(period.period),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(currencyFormat.format(period.expense)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(currencyFormat.format(period.accumulated)),
                        ),
                      ],
                    )).toList(),
                    // Show "..." if more periods exist
                    if (schedule.schedule.length > 5)
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('...', textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('...', textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('...', textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    // Last period if more than 5
                    if (schedule.schedule.length > 5) ...[
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(schedule.schedule.last.period),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(currencyFormat.format(schedule.schedule.last.expense)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(currencyFormat.format(schedule.schedule.last.accumulated)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                
                // Total summary
                if (schedule.schedule.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Total Periods: ${schedule.schedule.length} | '
                      'Total Depreciation: ${currencyFormat.format(schedule.schedule.last.accumulated)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                
                // Tags
                if (schedule.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 4,
                    children: schedule.tags.map((tag) => Chip(
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

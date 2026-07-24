import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// An inline widget for editing chart data points
/// Allows users to add, edit, and remove data points directly in the block
class InlineChartDataEditor extends StatefulWidget {
  final List<Map<String, dynamic>> initialData;
  final Function(List<Map<String, dynamic>>) onDataChanged;
  final ThemeData theme;

  const InlineChartDataEditor({
    required this.initialData,
    required this.onDataChanged,
    required this.theme,
    super.key,
  });

  @override
  State<InlineChartDataEditor> createState() => _InlineChartDataEditorState();
}

class _InlineChartDataEditorState extends State<InlineChartDataEditor> {
  late List<Map<String, dynamic>> _data;
  final Map<int, TextEditingController> _xControllers = {};
  final Map<int, TextEditingController> _yControllers = {};
  bool _showBulkImport = false;
  final TextEditingController _bulkImportController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _data = List<Map<String, dynamic>>.from(widget.initialData);

    // If empty, add one sample row
    if (_data.isEmpty) {
      _data.add({'x': '', 'y': 0.0});
    }

    _initializeControllers();
  }

  void _initializeControllers() {
    // Dispose old controllers
    _disposeControllers();

    // Create new controllers for current data
    for (int i = 0; i < _data.length; i++) {
      _xControllers[i] = TextEditingController(
        text: _data[i]['x']?.toString() ?? '',
      );
      _yControllers[i] = TextEditingController(
        text: _data[i]['y']?.toString() ?? '0',
      );
    }
  }

  void _disposeControllers() {
    for (var controller in _xControllers.values) {
      controller.dispose();
    }
    for (var controller in _yControllers.values) {
      controller.dispose();
    }
    _xControllers.clear();
    _yControllers.clear();
  }

  @override
  void dispose() {
    _bulkImportController.dispose();
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final containerPadding = isWide ? 12.0 : 8.0;
    final borderRadius = isWide ? 12.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with add and bulk import buttons
          Row(
            children: [
              Icon(
                IconsaxPlusLinear.edit,
                color: widget.theme.colorScheme.primary,
                size: isWide ? 20 : 18,
              ),
              SizedBox(width: isWide ? 8 : 6),
              Text(
                'Data Points',
                style: widget.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isWide ? null : 13,
                ),
              ),
              const Spacer(),
              if (!_showBulkImport)
                isWide
                    ? TextButton.icon(
                        icon: const Icon(
                          IconsaxPlusLinear.document_upload,
                          size: 16,
                        ),
                        label: const Text(
                          'Bulk Import',
                          style: TextStyle(fontSize: 14),
                        ),
                        onPressed: _toggleBulkImport,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                    : IconButton(
                        icon: const Icon(
                          IconsaxPlusLinear.document_upload,
                          size: 16,
                        ),
                        onPressed: _toggleBulkImport,
                        tooltip: 'Bulk Import',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
              SizedBox(width: isWide ? 8 : 4),
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: widget.theme.colorScheme.primary,
                ),
                onPressed: _addDataPoint,
                tooltip: 'Add data point',
                iconSize: isWide ? 20 : 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: isWide ? 12 : 8),

          // Bulk import mode
          if (_showBulkImport) ...[
            Container(
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(isWide ? 8 : 6),
                border: Border.all(
                  color: widget.theme.colorScheme.outline.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              padding: EdgeInsets.all(isWide ? 12 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bulk Import Mode',
                        style: widget.theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.theme.colorScheme.primary,
                          fontSize: isWide ? null : 13,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          IconsaxPlusLinear.close_circle,
                          size: isWide ? 16 : 14,
                        ),
                        label: Text(
                          'Exit',
                          style: TextStyle(fontSize: isWide ? 14 : 12),
                        ),
                        onPressed: _toggleBulkImport,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 8 : 6,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isWide ? 8 : 6),
                  Text(
                    'Paste CSV data (label, value) - one row per line:',
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.theme.colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: isWide ? 13 : 12,
                    ),
                  ),
                  SizedBox(height: isWide ? 8 : 6),
                  TextField(
                    controller: _bulkImportController,
                    maxLines: isWide ? 8 : 6,
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: isWide ? 13 : 12,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      hintText: 'Jan, 100\nFeb, 150\nMar, 120',
                      contentPadding: EdgeInsets.all(isWide ? 12 : 10),
                    ),
                    onChanged: (_) => _parseBulkData(),
                  ),
                ],
              ),
            ),
            SizedBox(height: isWide ? 12 : 8),
          ],

          // Data list
          if (!_showBulkImport)
            if (_data.isEmpty)
              _buildEmptyState(isWide)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _data.length,
                itemBuilder: (context, index) {
                  return _buildDataPointRow(context, index, isWide);
                },
              ),
        ],
      ),
    );
  }

  Widget _buildDataPointRow(BuildContext context, int index, bool isWide) {
    final itemPadding = isWide ? 8.0 : 6.0;
    final borderRadius = isWide ? 8.0 : 6.0;
    final circleSize = isWide ? 24.0 : 20.0;

    return Container(
      margin: EdgeInsets.only(bottom: isWide ? 8 : 6),
      padding: EdgeInsets.all(itemPadding),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Index
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: widget.theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.theme.colorScheme.onPrimaryContainer,
                  fontSize: isWide ? 11 : 10,
                ),
              ),
            ),
          ),
          SizedBox(width: isWide ? 8 : 6),

          // X value (label)
          Expanded(
            child: TextField(
              controller: _xControllers[index],
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: 'Jan',
                labelStyle: TextStyle(fontSize: isWide ? 13 : 12),
                hintStyle: TextStyle(fontSize: isWide ? 13 : 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isWide ? 8 : 6,
                  vertical: isWide ? 8 : 6,
                ),
                isDense: true,
              ),
              style: widget.theme.textTheme.bodySmall?.copyWith(
                fontSize: isWide ? 13 : 12,
              ),
              onChanged: (value) {
                setState(() {
                  _data[index]['x'] = value;
                });
                widget.onDataChanged(_data);
              },
            ),
          ),
          SizedBox(width: isWide ? 8 : 6),

          // Y value (number)
          Expanded(
            child: TextField(
              controller: _yControllers[index],
              decoration: InputDecoration(
                labelText: 'Value',
                hintText: '0',
                labelStyle: TextStyle(fontSize: isWide ? 13 : 12),
                hintStyle: TextStyle(fontSize: isWide ? 13 : 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isWide ? 8 : 6,
                  vertical: isWide ? 8 : 6,
                ),
                isDense: true,
              ),
              style: widget.theme.textTheme.bodySmall?.copyWith(
                fontSize: isWide ? 13 : 12,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                setState(() {
                  _data[index]['y'] = double.tryParse(value) ?? 0.0;
                });
                widget.onDataChanged(_data);
              },
            ),
          ),
          SizedBox(width: isWide ? 4 : 2),

          // Delete button
          IconButton(
            icon: Icon(
              Icons.remove_circle,
              color: widget.theme.colorScheme.error,
              size: isWide ? 18 : 16,
            ),
            onPressed: () => _removeDataPoint(index),
            tooltip: 'Remove',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isWide) {
    return Padding(
      padding: EdgeInsets.all(isWide ? 16 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconsaxPlusLinear.chart,
            size: isWide ? 32 : 28,
            color: widget.theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          SizedBox(height: isWide ? 8 : 6),
          Text(
            'No data points',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: isWide ? 13 : 12,
            ),
          ),
          SizedBox(height: isWide ? 4 : 3),
          Text(
            'Tap the + button to add data',
            style: widget.theme.textTheme.bodySmall?.copyWith(
              color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: isWide ? 11 : 10,
            ),
          ),
        ],
      ),
    );
  }

  void _addDataPoint() {
    setState(() {
      final newIndex = _data.length;
      _data.add({'x': '', 'y': 0.0});
      // Only create controller for the new data point
      _xControllers[newIndex] = TextEditingController(text: '');
      _yControllers[newIndex] = TextEditingController(text: '0');
    });
    widget.onDataChanged(_data);
  }

  void _removeDataPoint(int index) {
    setState(() {
      // Dispose only the controller being removed
      _xControllers[index]?.dispose();
      _yControllers[index]?.dispose();

      _data.removeAt(index);

      // Rebuild controller map with adjusted indices
      final newXControllers = <int, TextEditingController>{};
      final newYControllers = <int, TextEditingController>{};

      for (int i = 0; i < _data.length; i++) {
        if (i < index) {
          newXControllers[i] = _xControllers[i]!;
          newYControllers[i] = _yControllers[i]!;
        } else {
          // Reuse controllers from index + 1
          newXControllers[i] = _xControllers[i + 1]!;
          newYControllers[i] = _yControllers[i + 1]!;
        }
      }

      _xControllers.clear();
      _yControllers.clear();
      _xControllers.addAll(newXControllers);
      _yControllers.addAll(newYControllers);
    });
    widget.onDataChanged(_data);
  }

  void _toggleBulkImport() {
    setState(() {
      _showBulkImport = !_showBulkImport;
      if (_showBulkImport) {
        // Pre-fill bulk import with existing data
        _bulkImportController.text = _data
            .map((item) => '${item['x']}, ${item['y']}')
            .join('\n');
      }
    });
  }

  void _parseBulkData() {
    final text = _bulkImportController.text.trim();
    if (text.isEmpty) return;

    final lines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return;

    final newData = <Map<String, dynamic>>[];
    for (var line in lines) {
      // Support both comma and tab separated values
      final parts = line.contains(',')
          ? line.split(',')
          : line.split(RegExp(r'\s+'));

      if (parts.length >= 2) {
        final x = parts[0].trim();
        final y = double.tryParse(parts[1].trim()) ?? 0.0;
        newData.add({'x': x, 'y': y});
      } else if (parts.length == 1) {
        // Just a value, use index as label
        final y = double.tryParse(parts[0].trim()) ?? 0.0;
        newData.add({'x': (newData.length + 1).toString(), 'y': y});
      }
    }

    if (newData.isNotEmpty) {
      setState(() {
        _data = newData;
        _initializeControllers();
      });
      widget.onDataChanged(_data);
    }
  }
}

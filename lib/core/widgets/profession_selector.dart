import 'package:flutter/material.dart';
import 'package:barruu/core/constants/user_constants.dart';

/// Widget for selecting profession for professional accounts
class ProfessionSelector extends StatefulWidget {
  final String? selectedProfession;
  final ValueChanged<String?> onProfessionSelected;

  const ProfessionSelector({
    super.key,
    required this.selectedProfession,
    required this.onProfessionSelected,
  });

  @override
  State<ProfessionSelector> createState() => _ProfessionSelectorState();
}

class _ProfessionSelectorState extends State<ProfessionSelector> {
  final TextEditingController _customProfessionController = TextEditingController();
  bool _isCustom = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedProfession != null && 
        !Professions.all.contains(widget.selectedProfession)) {
      _isCustom = true;
      _customProfessionController.text = widget.selectedProfession!;
    }
  }

  @override
  void dispose() {
    _customProfessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profession',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your profession or area of expertise',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _isCustom ? Professions.other : widget.selectedProfession,
          decoration: const InputDecoration(
            labelText: 'Select profession',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work_outline),
          ),
          items: Professions.all.map((profession) {
            return DropdownMenuItem(
              value: profession,
              child: Text(profession),
            );
          }).toList(),
          onChanged: (value) {
            if (value == Professions.other) {
              setState(() {
                _isCustom = true;
              });
              // When 'Other' is selected, wait for user to enter custom profession
              // The onProfessionSelected callback will be triggered when text field changes
            } else {
              setState(() {
                _isCustom = false;
                _customProfessionController.clear();
              });
              widget.onProfessionSelected(value);
            }
          },
          validator: (value) {
            if (!_isCustom && value == null) {
              return 'Please select your profession';
            }
            return null;
          },
        ),
        if (_isCustom) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customProfessionController,
            decoration: const InputDecoration(
              labelText: 'Enter your profession',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit_outlined),
              helperText: 'Specify your profession',
            ),
            onChanged: (value) {
              widget.onProfessionSelected(value.trim().isEmpty ? null : value.trim());
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your profession';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

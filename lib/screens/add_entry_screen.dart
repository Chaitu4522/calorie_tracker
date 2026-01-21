import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Screen for adding or editing a calorie entry.
class AddEntryScreen extends StatefulWidget {
  final Entry? entryToEdit;

  const AddEntryScreen({super.key, this.entryToEdit});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _geminiService = GeminiService();

  File? _selectedImage;
  bool _isEstimating = false;
  bool _hasEstimated = false;
  String? _errorMessage;

  bool get isEditing => widget.entryToEdit != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (isEditing) {
      _descriptionController.text = widget.entryToEdit!.description;
      _caloriesController.text = widget.entryToEdit!.calories.toString();
      // Start on manual tab when editing
      _tabController.index = 1;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(pickedFile.path);
          _hasEstimated = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to pick image. Please try again.';
      });
    }
  }

  Future<void> _estimateCalories() async {
    if (_descriptionController.text.trim().isEmpty && _selectedImage == null) {
      setState(() {
        _errorMessage = 'Please add a description or photo';
      });
      return;
    }

    setState(() {
      _isEstimating = true;
      _errorMessage = null;
    });

    final provider = context.read<AppProvider>();
    final apiKey = await provider.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isEstimating = false;
        _errorMessage = 'API key not found. Please update in Settings.';
      });
      return;
    }

    GeminiResult result;

    if (_selectedImage != null) {
      result = await _geminiService.estimateCalories(
        apiKey: apiKey,
        imageFile: _selectedImage!,
        description: _descriptionController.text.trim(),
      );
    } else {
      result = await _geminiService.estimateCaloriesFromText(
        apiKey: apiKey,
        description: _descriptionController.text.trim(),
      );
    }

    if (!mounted) return;

    setState(() {
      _isEstimating = false;
      if (result.success) {
        _caloriesController.text = result.calories.toString();
        _hasEstimated = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.errorMessage;
      }
    });
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) return;

    final description = _descriptionController.text.trim();
    final calories = int.parse(_caloriesController.text);

    final provider = context.read<AppProvider>();
    bool success;

    if (isEditing) {
      final updatedEntry = widget.entryToEdit!.copyWith(
        description: description,
        calories: calories,
      );
      success = await provider.updateEntry(updatedEntry);
    } else {
      success = await provider.addEntry(
        description: description,
        calories: calories,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save entry')),
      );
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<AppProvider>();
      final success = await provider.deleteEntry(widget.entryToEdit!.id!);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete entry')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'Add Entry'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteEntry,
              color: Colors.red,
            ),
        ],
        bottom: isEditing
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'AI Estimate'),
                  Tab(text: 'Manual Entry'),
                ],
              ),
      ),
      body: isEditing
          ? _buildManualEntryForm()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAiEstimateTab(),
                _buildManualEntryForm(),
              ],
            ),
    );
  }

  Widget _buildAiEstimateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo selection
            if (_selectedImage != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _hasEstimated = false;
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Remove Photo'),
              ),
            ] else ...[
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _PhotoButton(
                      icon: Icons.camera_alt,
                      label: 'Take Photo',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                    Container(
                      width: 1,
                      height: 80,
                      color: Colors.grey.shade300,
                    ),
                    _PhotoButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Description input
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., 200g grilled chicken breast, homemade',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Estimate button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isEstimating ? null : _estimateCalories,
                icon: _isEstimating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_isEstimating ? 'Estimating...' : 'Estimate Calories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Estimated calories display
            if (_hasEstimated) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Estimated Calories',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixText: 'kcal',
                  helperText: 'You can adjust this value if needed',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter calories';
                  }
                  final calories = int.tryParse(value);
                  if (calories == null || calories <= 0) {
                    return 'Enter a valid calorie amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Entry'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: isEditing ? _formKey : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Chicken salad',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories',
                border: OutlineInputBorder(),
                suffixText: 'kcal',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter calories';
                }
                final calories = int.tryParse(value);
                if (calories == null || calories <= 0) {
                  return 'Enter a valid calorie amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (isEditing) {
                    if (_formKey.currentState!.validate()) {
                      _saveEntry();
                    }
                  } else {
                    // Create a local form key for manual entry tab
                    final desc = _descriptionController.text.trim();
                    final cal = int.tryParse(_caloriesController.text);
                    if (desc.isNotEmpty && cal != null && cal > 0) {
                      _saveEntry();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields correctly'),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEditing ? 'Update Entry' : 'Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button widget for photo selection.
class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.teal),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.teal)),
          ],
        ),
      ),
    );
  }
}

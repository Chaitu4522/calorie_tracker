import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/providers.dart';

/// Settings screen for profile and data management.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Profile'),
          _SettingsTile(
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Change name and daily goal',
            onTap: () => _showEditProfileDialog(context),
          ),
          _SettingsTile(
            icon: Icons.key,
            title: 'Update API Key',
            subtitle: 'Change your Gemini API key',
            onTap: () => _showApiKeyDialog(context),
          ),
          _SectionHeader(title: 'Data'),
          _SettingsTile(
            icon: Icons.upload_file,
            title: 'Import Data',
            subtitle: 'Import entries from CSV file',
            onTap: () => _importData(context),
          ),
          _SettingsTile(
            icon: Icons.download,
            title: 'Export Data',
            subtitle: 'Download as CSV file',
            onTap: () => _exportData(context),
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Clear All Data',
            subtitle: 'Delete all entries and reset app',
            textColor: Colors.red,
            onTap: () => _showClearDataDialog(context),
          ),
          _SectionHeader(title: 'About'),
          const _SettingsTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: '1.0.0',
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Calorie Tracker is a minimal app for tracking your daily calorie intake with AI-powered estimation using Google Gemini.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final nameController = TextEditingController(text: provider.userName);
    final goalController = TextEditingController(text: provider.dailyGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              decoration: const InputDecoration(labelText: 'Daily Calorie Goal', border: OutlineInputBorder(), suffixText: 'kcal'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final goal = int.tryParse(goalController.text);
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                return;
              }
              if (goal == null || goal < 500 || goal > 10000) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Goal must be between 500 and 10,000')));
                return;
              }
              await provider.updateProfile(name: name, dailyGoal: goal);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final apiKeyController = TextEditingController();
    bool obscureKey = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update API Key'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: apiKeyController,
                decoration: InputDecoration(
                  labelText: 'New Gemini API Key',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(obscureKey ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => obscureKey = !obscureKey)),
                      IconButton(icon: const Icon(Icons.help_outline), onPressed: () => _showApiKeyGuide(context)),
                    ],
                  ),
                ),
                obscureText: obscureKey,
              ),
              const SizedBox(height: 8),
              const Text('Leave empty to keep current key', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final apiKey = apiKeyController.text.trim();
                if (apiKey.isNotEmpty) {
                  if (apiKey.length < 20) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key seems too short')));
                    return;
                  }
                  await provider.updateProfile(apiKey: apiKey);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API key updated')));
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Get Your Gemini API Key'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Go to:'),
              SelectableText('https://aistudio.google.com/app/apikey', style: TextStyle(color: Colors.blue)),
              SizedBox(height: 8),
              Text('2. Sign in with your Google account'),
              SizedBox(height: 8),
              Text('3. Click "Create API Key"'),
              SizedBox(height: 8),
              Text('4. Copy the key and paste it here'),
              SizedBox(height: 8),
              Text('5. Keep this key private'),
              SizedBox(height: 16),
              Text('Note: The free tier allows 1,500 requests/day.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = Uri.parse('https://aistudio.google.com/app/apikey');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open Link'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String csvContent;

      if (file.bytes != null) {
        csvContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read file');
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Data'),
          content: Text('This will import entries from "${file.name}".\n\nExisting entries will NOT be deleted. Imported entries will be added to your existing data.\n\nContinue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
          ],
        ),
      );

      if (confirmed != true) return;

      final provider = context.read<AppProvider>();
      final imported = await provider.importData(csvContent);

      if (imported >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported $imported entries')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to import data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final provider = context.read<AppProvider>();
      final csvData = await provider.exportData();

      if (csvData.isEmpty || csvData == 'Date,Time,Description,Calories\n') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/calorie_export_$timestamp.csv');
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(file.path)], subject: 'Calorie Tracker Export');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all your entries and reset the app. This action cannot be undone.\n\nAre you sure you want to continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final provider = context.read<AppProvider>();
              await provider.clearAllData();
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/setup', (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.textColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.teal),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}

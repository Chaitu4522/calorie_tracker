import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';

/// Initial setup screen shown on first launch.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController(text: '2000');
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<AppProvider>();
    final success = await provider.completeSetup(
      name: _nameController.text.trim(),
      dailyGoal: int.parse(_goalController.text),
      apiKey: _apiKeyController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setup failed. Please try again.')),
      );
    }
  }

  void _showApiKeyGuide() {
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
              SelectableText(
                'https://makersuite.google.com/app/apikey',
                style: TextStyle(color: Colors.blue),
              ),
              SizedBox(height: 8),
              Text('2. Sign in with your Google account'),
              SizedBox(height: 8),
              Text('3. Click "Create API Key"'),
              SizedBox(height: 8),
              Text('4. Copy the key and paste it here'),
              SizedBox(height: 8),
              Text('5. Keep this key private - don\'t share it'),
              SizedBox(height: 16),
              Text(
                'Note: The free tier allows 1,500 requests/day.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final url = Uri.parse(
                'https://makersuite.google.com/app/apikey',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open Link'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Welcome message
                const Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Calorie Tracker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track your calories with AI-powered estimation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Name input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Your Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Daily goal input
                TextFormField(
                  controller: _goalController,
                  decoration: const InputDecoration(
                    labelText: 'Daily Calorie Goal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                    suffixText: 'kcal',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your daily goal';
                    }
                    final goal = int.tryParse(value);
                    if (goal == null || goal < 500 || goal > 10000) {
                      return 'Enter a value between 500 and 10,000';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // API key input
                TextFormField(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _obscureApiKey = !_obscureApiKey);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: _showApiKeyGuide,
                        ),
                      ],
                    ),
                  ),
                  obscureText: _obscureApiKey,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your API key';
                    }
                    if (value.trim().length < 20) {
                      return 'API key seems too short';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Continue button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

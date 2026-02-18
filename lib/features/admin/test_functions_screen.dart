import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';

class TestFunctionsScreen extends StatefulWidget {
  const TestFunctionsScreen({super.key});

  @override
  State<TestFunctionsScreen> createState() => _TestFunctionsScreenState();
}

class _TestFunctionsScreenState extends State<TestFunctionsScreen> {
  String _status = 'Ready to test';
  bool _loading = false;

  Future<void> _testFunction(String functionName) async {
    setState(() {
      _loading = true;
      _status = 'Testing $functionName...';
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(functionName);
      final result = await callable.call();
      
      setState(() {
        _status = '✅ $functionName: Success!\n${result.data}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ $functionName: Error\n${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Functions'),
        backgroundColor: figmaOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Embedding Functions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _TestButton(
              label: 'embedAllActivities',
              onPressed: _loading ? null : () => _testFunction('embedAllActivities'),
            ),
            _TestButton(
              label: 'embedAllDrives',
              onPressed: _loading ? null : () => _testFunction('embedAllDrives'),
            ),
            _TestButton(
              label: 'embedAllResources',
              onPressed: _loading ? null : () => _testFunction('embedAllResources'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Other Functions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _TestButton(
              label: 'generateAIInsights',
              onPressed: _loading ? null : () => _testFunction('generateAIInsights'),
            ),
            const SizedBox(height: 16),
            Text(
              'Note: chatWithRAG and matchVolunteerToActivities require userId parameter.\nTest them from their respective screens.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  const _TestButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: figmaOrange,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }
}

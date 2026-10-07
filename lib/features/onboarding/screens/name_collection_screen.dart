import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/onboarding_provider.dart';

class NameCollectionScreen extends ConsumerStatefulWidget {
  const NameCollectionScreen({super.key});

  @override
  ConsumerState<NameCollectionScreen> createState() => _NameCollectionScreenState();
}

class _NameCollectionScreenState extends ConsumerState<NameCollectionScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final notifier = ref.read(onboardingProvider.notifier);
      await notifier.submitName(_controller.text);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "What's your name?",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "I will address you by name to make our voice practice sessions feel friendly and personal.",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 36),
                          TextFormField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please type your name';
                              }
                              if (value.length > 20) {
                                return 'Name is too long';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              hintText: 'Enter your name...',
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.accentGold),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submit,
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

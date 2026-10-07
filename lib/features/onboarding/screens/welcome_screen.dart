import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        // Brand Icon Card
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppTheme.primaryNavy,
                            border: Border.all(color: AppTheme.secondaryNavy),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withValues(alpha: 0.05),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Image.asset('assets/images/app_logo.png'),
                        ),
                        const SizedBox(height: 20),
                        // Slogan
                        const Text(
                          'Speak English Confidently',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'A warm, patient English tutor that understands Tamil and never judges your mistakes.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Features list
                    Column(
                      children: [
                        _buildFeatureRow(
                          icon: Icons.chat_bubble_outline,
                          title: 'Speak Naturally',
                          desc: 'Practice real-life scenario conversations with a patient AI.',
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureRow(
                          icon: Icons.g_translate_outlined,
                          title: 'Tamil Explanations',
                          desc: 'Get clear, detailed grammar help in Tamil when you make mistakes.',
                        ),
                        const SizedBox(height: 14),
                        _buildFeatureRow(
                          icon: Icons.sentiment_satisfied_alt_outlined,
                          title: 'Fear-Free Learning',
                          desc: 'No grades, no stress. Praise effort first, corrections second.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/onboarding');
                        },
                        child: const Text('Get Started'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryNavy.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryNavy.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accentGold, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

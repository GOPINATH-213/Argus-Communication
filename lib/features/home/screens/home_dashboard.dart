import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/hive_service.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/practice_session_screen.dart';
import '../../../core/notifications/notification_service.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _reminderTime = HiveService.getReminderTime();
  }

  late String _reminderTime;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(onboardingProvider);

    final List<Widget> children = [
      _buildPracticeTab(profile),
      _buildProgressTab(),
      _buildHistoryTab(),
      _buildSettingsTab(profile),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryNavy,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/images/app_logo.png'),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Argus',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
            ),
            const Text(
              ' Comm.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryNavy,
        selectedItemColor: AppTheme.accentGold,
        unselectedItemColor: AppTheme.textMuted,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Practice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  // ==================== PRACTICE TAB ====================
  Widget _buildPracticeTab(UserProfileState profile) {
    final name = profile.name ?? 'Friend';
    final usedTurns = HiveService.getUsedTurnsToday();
    final remainingTurns = 20 - usedTurns;

    // Determine greeting based on current time
    final hour = DateTime.now().hour;
    String timeGreeting = "Good morning";
    if (hour >= 12 && hour < 17) {
      timeGreeting = "Good afternoon";
    } else if (hour >= 17) {
      timeGreeting = "Good evening";
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Intro
          Text(
            '$timeGreeting,',
            style: const TextStyle(fontSize: 16, color: AppTheme.textMuted),
          ),
          Text(
            '$name!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Card Row
          Row(
            children: [
              // Streak Stat
              Expanded(
                child: _buildStatCard(
                  title: 'Day Streak',
                  value: '${profile.streak} Days',
                  icon: Icons.local_fire_department,
                  iconColor: AppTheme.alertOrange,
                ),
              ),
              const SizedBox(width: 16),
              // Daily Limit Stat
              Expanded(
                child: _buildStatCard(
                  title: 'Turns Left',
                  value: '$remainingTurns / 20',
                  icon: Icons.chat_bubble,
                  iconColor: AppTheme.accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Start Practice CTA Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.03),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ready to practice?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Speak English confidently in real-life settings. I\'m ready to listen!',
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: remainingTurns > 0
                        ? () => _showScenarioSelectionSheet(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: remainingTurns > 0
                          ? AppTheme.accentGold
                          : Colors.grey,
                    ),
                    child: Text(
                      remainingTurns > 0
                          ? 'Start Practice'
                          : 'Daily Limit Reached',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Real-Life Scenarios Heading
          const Text(
            'Practice Scenarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Scenarios list
          _buildScenarioItem(
            title: 'Railway Station',
            desc:
                'Practice buying tickets and asking the Station Master for directions.',
            icon: Icons.directions_railway_outlined,
            onTap: () => _startScenarioPractice('Railway Station'),
          ),
          const SizedBox(height: 12),
          _buildScenarioItem(
            title: 'Job Interview',
            desc:
                'Rehearse answering classic interview questions with HR manager.',
            icon: Icons.work_outline,
            onTap: () => _startScenarioPractice('Job Interview'),
          ),
          const SizedBox(height: 12),
          _buildScenarioItem(
            title: 'Hotel Booking',
            desc:
                'Check in, verify your room key, and request guest accommodations.',
            icon: Icons.hotel_outlined,
            onTap: () => _startScenarioPractice('Hotel Booking'),
          ),
          const SizedBox(height: 12),
          _buildScenarioItem(
            title: 'General Practice',
            desc:
                'Casual chat about your daily routine, food, hobbies and dreams.',
            icon: Icons.chat_bubble_outline,
            onTap: () => _startScenarioPractice('General Practice'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryNavy.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioItem({
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final remainingTurns = 20 - HiveService.getUsedTurnsToday();
    return InkWell(
      onTap: remainingTurns > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.secondaryNavy.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.secondaryNavy.withValues(alpha: 0.5),
              child: Icon(icon, color: AppTheme.accentGold),
            ),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: AppTheme.accentGold.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  void _showScenarioSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a Topic',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.directions_railway,
                  color: AppTheme.accentGold,
                ),
                title: const Text('Railway Station'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startScenarioPractice('Railway Station');
                },
              ),
              ListTile(
                leading: const Icon(Icons.work, color: AppTheme.accentGold),
                title: const Text('Job Interview'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startScenarioPractice('Job Interview');
                },
              ),
              ListTile(
                leading: const Icon(Icons.hotel, color: AppTheme.accentGold),
                title: const Text('Hotel Booking'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startScenarioPractice('Hotel Booking');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.chat_bubble,
                  color: AppTheme.accentGold,
                ),
                title: const Text('General Practice'),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startScenarioPractice('General Practice');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startScenarioPractice(String topic) {
    ref.read(chatProvider.notifier).startSession(topic);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PracticeSessionScreen()),
    ).then((_) {
      // Reload limit counters when returning
      setState(() {});
    });
  }

  // ==================== PROGRESS TAB ====================
  Widget _buildProgressTab() {
    final metrics = HiveService.getProgressMetrics();

    if (metrics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: AppTheme.textMuted, size: 64),
              SizedBox(height: 16),
              Text(
                'No progress data yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Complete conversations to see grammar and fluency charts here!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    // Prepare line chart points
    List<FlSpot> grammarSpots = [];
    List<FlSpot> fluencySpots = [];
    List<FlSpot> confidenceSpots = [];

    for (int i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final idx = i.toDouble();
      grammarSpots.add(FlSpot(idx, (m['grammar'] as num).toDouble()));
      fluencySpots.add(FlSpot(idx, (m['fluency'] as num).toDouble()));
      confidenceSpots.add(FlSpot(idx, (m['confidence'] as num).toDouble()));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Growth Analytics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track your grammar, fluency, and overall confidence scores.',
            style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 28),

          // Chart Display
          Container(
            height: 260,
            padding: const EdgeInsets.only(
              right: 20,
              top: 20,
              bottom: 10,
              left: 10,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondaryNavy.withValues(alpha: 0.5),
              ),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: grammarSpots,
                    isCurved: true,
                    color: AppTheme.accentGold,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: fluencySpots,
                    isCurved: true,
                    color: AppTheme.successGreen,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: confidenceSpots,
                    isCurved: true,
                    color: AppTheme.alertOrange,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(color: AppTheme.accentGold, label: 'Grammar'),
              const SizedBox(width: 20),
              _buildLegendItem(color: AppTheme.successGreen, label: 'Fluency'),
              const SizedBox(width: 20),
              _buildLegendItem(
                color: AppTheme.alertOrange,
                label: 'Confidence',
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Summary Stats card
          const Text(
            'Milestones Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryBox(
                  'Total Practice Days',
                  '${metrics.length}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryBox(
                  'Average Grammar',
                  '${(metrics.map((e) => e['grammar'] as num).reduce((a, b) => a + b) / metrics.length).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  Widget _buildSummaryBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryNavy.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab() {
    final sessions = HiveService.getSessionsList();

    if (sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_edu, color: AppTheme.textMuted, size: 64),
              SizedBox(height: 16),
              Text(
                'No conversation history',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your dialogues, speech corrections, and Tamil explanations will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20.0),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final date = DateTime.parse(session['date'] as String);
        final dateStr =
            "${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        final turnsList = (session['turns'] as List)
            .cast<Map<dynamic, dynamic>>();

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: ExpansionTile(
            title: Text(
              session['topic'] as String? ?? 'General Practice',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold,
              ),
            ),
            subtitle: Text(
              '$dateStr • ${turnsList.length ~/ 2} Turns',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: turnsList.map<Widget>((turn) {
                    final isUser = turn['isUser'] as bool;
                    final text = turn['text'] as String;

                    if (isUser) {
                      final corrected = turn['correctedText'] as String?;
                      final explain = turn['tamilExplanation'] as String?;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'You: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  text,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          if (corrected != null && corrected != text) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryNavy.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: AppTheme.accentGold,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Corrected: $corrected',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (explain != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      explain,
                                      style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    } else {
                      // AI response
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Coach: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentGold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: AppTheme.accentGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==================== SETTINGS TAB ====================
  Widget _buildSettingsTab(UserProfileState profile) {
    final curLevel = HiveService.getDifficultyLevel();

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Title
        const Text(
          'App Configurations',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Difficulty Settings
        const Text(
          'Coach Vocabulary Difficulty',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: curLevel,
          dropdownColor: AppTheme.primaryNavy,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.psychology, color: AppTheme.accentGold),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Beginner',
              child: Text(
                'Beginner (Simple words)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            DropdownMenuItem(
              value: 'Intermediate',
              child: Text(
                'Intermediate',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            DropdownMenuItem(
              value: 'Advanced',
              child: Text(
                'Advanced (Complex scenarios)',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              HiveService.saveDifficultyLevel(val);
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 28),

        // Practice Reminder Settings
        const Text(
          'Daily Practice Alarm',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ListTile(
          tileColor: AppTheme.primaryNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: const Icon(
            Icons.notifications_active,
            color: AppTheme.accentGold,
          ),
          title: const Text('Reminder Time'),
          trailing: Text(
            _reminderTime,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGold,
              fontSize: 16,
            ),
          ),
          onTap: () async {
            final timeStr = HiveService.getReminderTime();
            final parts = timeStr.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );

            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );

            if (picked != null) {
              final formattedTime =
                  "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";

              debugPrint("Selected: $formattedTime");

              await HiveService.saveReminderTime(formattedTime);
              debugPrint("Saved to Hive");

              try {
                await NotificationService.scheduleDailyReminder(
                  picked.hour,
                  picked.minute,
                );

                debugPrint("Notification Scheduled");
              } catch (e) {
                debugPrint("Notification Error: $e");
              }

              setState(() {
                _reminderTime = formattedTime;
              });

              debugPrint("UI Updated");
            }
          },
        ),
        const SizedBox(height: 48),

        // Danger zone
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade900,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: AppTheme.primaryNavy,
                  title: const Text('Reset All Data?'),
                  content: const Text(
                    'This will delete your name, streak counter, and complete practice history. This is permanent.',
                  ),
                  actions: [
                    TextButton(
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(onboardingProvider.notifier)
                            .resetAllData();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/welcome',
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          child: const Text('Clear All Practice Data'),
        ),
      ],
    );
  }
}

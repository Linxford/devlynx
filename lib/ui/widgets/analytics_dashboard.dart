import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../data/analytics_manager.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({Key? key}) : super(key: key);

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadAnalytics();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    try {
      final analytics = await AnalyticsManager.getAnalyticsSummary();
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return _buildLoadingState(colorScheme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colorScheme),
            const SizedBox(height: 24),
            _buildMetricsGrid(colorScheme),
            const SizedBox(height: 24),
            _buildChartsSection(colorScheme),
            const SizedBox(height: 24),
            _buildInsightsSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(colorScheme, 200, 40),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildShimmer(colorScheme, double.infinity, 120)),
              const SizedBox(width: 16),
              Expanded(child: _buildShimmer(colorScheme, double.infinity, 120)),
              const SizedBox(width: 16),
              Expanded(child: _buildShimmer(colorScheme, double.infinity, 120)),
            ],
          ),
          const SizedBox(height: 24),
          _buildShimmer(colorScheme, double.infinity, 200),
        ],
      ),
    );
  }

  Widget _buildShimmer(ColorScheme colorScheme, double width, double height) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                colorScheme.surfaceVariant.withValues(alpha: 0.3),
                colorScheme.surfaceVariant.withValues(alpha: 0.1),
                colorScheme.surfaceVariant.withValues(alpha: 0.3),
              ],
              stops: [0.0, _pulseAnimation.value, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.8),
                colorScheme.primary.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Developer Analytics',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Your productivity insights',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildRefreshButton(colorScheme),
      ],
    );
  }

  Widget _buildRefreshButton(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: IconButton(
        onPressed: () {
          setState(() {
            _isLoading = true;
          });
          _loadAnalytics();
        },
        icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildMetricsGrid(ColorScheme colorScheme) {
    final totalProjects = _analytics['total_projects'] ?? 0;
    final totalSessions = _analytics['total_sessions'] ?? 0;
    final avgSessionTime = _analytics['avg_session_time'] ?? 0.0;
    final totalCommands = _analytics['total_commands'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            colorScheme,
            'Projects',
            totalProjects.toString(),
            Icons.folder_outlined,
            const Color(0xFF4CAF50),
            '+${_analytics['projects_growth'] ?? 0}% this week',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            colorScheme,
            'Sessions',
            totalSessions.toString(),
            Icons.timer_outlined,
            const Color(0xFF2196F3),
            '${_analytics['sessions_today'] ?? 0} today',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            colorScheme,
            'Avg Time',
            '${avgSessionTime.toStringAsFixed(1)}h',
            Icons.schedule_outlined,
            const Color(0xFFFF9800),
            'per session',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            colorScheme,
            'Commands',
            totalCommands.toString(),
            Icons.terminal_outlined,
            const Color(0xFF9C27B0),
            '${_analytics['commands_today'] ?? 0} today',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ColorScheme colorScheme,
    String title,
    String value,
    IconData icon,
    Color accentColor,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withOpacity(0.9),
            colorScheme.surfaceVariant.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withOpacity(0.9),
            colorScheme.surfaceVariant.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _buildChartToggle(colorScheme),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: _buildActivityChart(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildChartToggle(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(colorScheme, '7D', true),
          _buildToggleButton(colorScheme, '30D', false),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    ColorScheme colorScheme,
    String text,
    bool isActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildActivityChart(ColorScheme colorScheme) {
    final dailyData =
        _analytics['daily_activity'] as Map<String, dynamic>? ?? {};

    return CustomPaint(
      painter: ActivityChartPainter(data: dailyData, colorScheme: colorScheme),
      child: Container(),
    );
  }

  Widget _buildInsightsSection(ColorScheme colorScheme) {
    final insights = _analytics['insights'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...insights
            .take(3)
            .map((insight) => _buildInsightCard(colorScheme, insight)),
      ],
    );
  }

  Widget _buildInsightCard(ColorScheme colorScheme, String insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.primaryContainer.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityChartPainter extends CustomPainter {
  final Map<String, dynamic> data;
  final ColorScheme colorScheme;

  ActivityChartPainter({required this.data, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final gradient = LinearGradient(
      colors: [
        colorScheme.primary.withOpacity(0.8),
        colorScheme.primary.withOpacity(0.4),
      ],
    );

    paint.shader = gradient.createShader(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    final path = Path();
    final entries = data.entries.toList();

    if (entries.isEmpty) return;

    final maxValue = entries
        .map((e) => (e.value as num).toDouble())
        .reduce(math.max);
    final stepX = size.width / (entries.length - 1);

    for (int i = 0; i < entries.length; i++) {
      final x = i * stepX;
      final y = size.height - (entries[i].value / maxValue) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw data points
    final pointPaint = Paint()
      ..color = colorScheme.primary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < entries.length; i++) {
      final x = i * stepX;
      final y = size.height - (entries[i].value / maxValue) * size.height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

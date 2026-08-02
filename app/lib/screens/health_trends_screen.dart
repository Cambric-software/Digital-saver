import 'dart:math' as math;
import 'package:flutter/material.dart';

// Health trends and history screen
class HealthTrendsScreen extends StatefulWidget {
  const HealthTrendsScreen({super.key});

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Week';

  final List<String> _periods = ['Day', 'Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0F172A),
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Health Trends',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1E3A5F).withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  
                  // Summary cards
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  
                  // Charts
                  _buildCharts(),
                  const SizedBox(height: 24),
                  
                  // Health insights
                  _buildInsights(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF2563EB) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard(
          'Avg Heart Rate',
          '72',
          'bpm',
          Icons.favorite,
          Colors.red,
          '+2 from last $_selectedPeriod',
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard(
          'Avg SpO2',
          '97',
          '%',
          Icons.air,
          const Color(0xFF3B82F6),
          'Stable',
        )),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Heart Rate Pattern',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 168),
            painter: _HeartRateChartPainter(),
          ),
        ),
        const SizedBox(height: 24),
        
        const Text(
          'Activity Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: CustomPaint(
            size: const Size(double.infinity, 168),
            painter: _ActivityChartPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Insights',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          icon: Icons.trending_up,
          title: 'Activity Goal Progress',
          description: 'You\'ve reached 75% of your daily activity goal. Keep moving!',
          color: const Color(0xFF10B981),
          progress: 0.75,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.favorite,
          title: 'Heart Rate Variability',
          description: 'Your HRV improved by 12% this week compared to last week.',
          color: Colors.red,
          progress: 0.65,
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.bedtime,
          title: 'Sleep Quality',
          description: 'Your average sleep duration is 7.2 hours. Consider going to bed 30 minutes earlier.',
          color: const Color(0xFF8B5CF6),
          progress: 0.82,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
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

class _HeartRateChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.red.withOpacity(0.3),
          Colors.red.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    final points = _generateHeartRateData();
    final stepX = size.width / (points.length - 1);
    
    path.moveTo(0, size.height - points[0] * size.height);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - points[0] * size.height);

    for (int i = 1; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - points[i] * size.height;
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw labels
    final textPainter = TextPainter(
      text: TextSpan(
        text: '120',
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(4, 4));
    
    textPainter.text = TextSpan(
      text: '60',
      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(4, size.height - 20));
  }

  List<double> _generateHeartRateData() {
    final random = math.Random(42);
    return List.generate(24, (i) {
      final base = 0.5 + random.nextDouble() * 0.3;
      // Add some peaks for realistic heart rate pattern
      if (i >= 8 && i <= 10) return base + 0.2; // Morning activity
      if (i >= 12 && i <= 13) return base + 0.15; // Lunch activity
      if (i >= 17 && i <= 19) return base + 0.25; // Evening activity
      if (i >= 0 && i <= 6) return base - 0.2; // Sleep
      return base;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActivityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final barPaintAlt = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final data = _generateActivityData();
    final barWidth = (size.width - 48) / data.length;
    final maxValue = data.reduce(math.max);

    // Draw bars
    for (int i = 0; i < data.length; i++) {
      final x = 24 + i * barWidth;
      final height = (data[i] / maxValue) * (size.height - 40);
      final y = size.height - height - 20;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth - 8, height),
          const Radius.circular(4),
        ),
        i == 3 ? barPaint : barPaintAlt,
      );
    }

    // Draw baseline
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(24, size.height - 20),
      Offset(size.width - 24, size.height - 20),
      linePaint,
    );

    // Draw labels
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i < days.length; i++) {
      final x = 24 + i * barWidth + (barWidth - 8) / 2;
      textPainter.text = TextSpan(
        text: days[i],
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 12));
    }
  }

  List<int> _generateActivityData() {
    final random = math.Random(42);
    return List.generate(7, (i) => 3000 + random.nextInt(7000));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

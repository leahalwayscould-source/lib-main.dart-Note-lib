import 'package:flutter/material.dart';

class PricingTab extends StatefulWidget {
  const PricingTab({super.key});

  @override
  State<PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab> {
  // Pricing factors
  int _experienceLevel = 5; // years
  double _sizeMultiplier = 1.0; // small, medium, large
  double _mediumMultiplier = 1.0;
  int _productionHours = 10;
  double _skillRating = 3.0; // 1-5 stars
  double _baseHourlyRate = 50.0;
  bool _isEstablished = false;

  late List<String> _mediumOptions;
  late String _selectedMedium;
  late List<String> _sizeOptions;
  late String _selectedSize;

  @override
  void initState() {
    super.initState();
    _mediumOptions = [
      'Digital',
      'Oil',
      'Acrylic',
      'Watercolor',
      'Sculpture',
      'Photography'
    ];
    _selectedMedium = _mediumOptions[0];
    _sizeOptions = ['Small (A5-5x7)', 'Medium (8x10-11x14)', 'Large (16x20+)'];
    _selectedSize = _sizeOptions[1];
    _mediumMultiplier = _getMediumMultiplier(_selectedMedium);
    _sizeMultiplier = _getSizeMultiplier(_selectedSize);
  }

  double _getMediumMultiplier(String medium) {
    switch (medium) {
      case 'Oil':
        return 1.5;
      case 'Watercolor':
        return 1.2;
      case 'Sculpture':
        return 2.0;
      case 'Photography':
        return 1.3;
      case 'Digital':
        return 0.8;
      default:
        return 1.0;
    }
  }

  double _getSizeMultiplier(String size) {
    if (size.contains('Small')) return 0.8;
    if (size.contains('Large')) return 1.8;
    return 1.0; // Medium
  }

  double _calculatePrice() {
    double baseCost = _productionHours * _baseHourlyRate;
    double experienceFactor = 1.0 + (_experienceLevel * 0.1); // 10% per year
    double skillFactor = _skillRating / 3.0; // normalize to around 1.0
    double establishedBonus = _isEstablished ? 1.3 : 1.0;

    double finalPrice = baseCost *
        _mediumMultiplier *
        _sizeMultiplier *
        experienceFactor *
        skillFactor *
        establishedBonus;

    return finalPrice.roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    double suggestedPrice = _calculatePrice();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Art Pricing Calculator'),
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price Display Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Suggested Price',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[300],
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '\$${suggestedPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[300]),
                      children: [
                        const TextSpan(
                          text:
                              'Based on your experience level, medium, size, production hours, and market demand.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Factors Section
            Text(
              'Price Factors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Experience Level
            _FactorCard(
              title: 'Years of Experience',
              value: _experienceLevel.toString(),
              onChanged: (value) {
                setState(() {
                  _experienceLevel = value.toInt();
                });
              },
              min: 0,
              max: 50,
              tooltipText: 'More experience = higher prices',
            ),
            const SizedBox(height: 12),

            // Production Hours
            _FactorCard(
              title: 'Production Hours',
              value: _productionHours.toString(),
              onChanged: (value) {
                setState(() {
                  _productionHours = value.toInt();
                });
              },
              min: 1,
              max: 100,
              tooltipText: 'Time invested in creating the artwork',
            ),
            const SizedBox(height: 12),

            // Hourly Rate
            _FactorCard(
              title: 'Base Hourly Rate (\$)',
              value: _baseHourlyRate.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  _baseHourlyRate = value;
                });
              },
              min: 10,
              max: 500,
              tooltipText: 'Adjust based on your market and skill level',
            ),
            const SizedBox(height: 12),

            // Skill Rating
            _SkillRatingCard(
              rating: _skillRating,
              onChanged: (value) {
                setState(() {
                  _skillRating = value;
                });
              },
            ),
            const SizedBox(height: 12),

            // Medium Dropdown
            _DropdownCard(
              title: 'Medium',
              value: _selectedMedium,
              options: _mediumOptions,
              onChanged: (value) {
                setState(() {
                  _selectedMedium = value;
                  _mediumMultiplier = _getMediumMultiplier(value);
                });
              },
              tooltipText: 'Different mediums have different market values',
            ),
            const SizedBox(height: 12),

            // Size Dropdown
            _DropdownCard(
              title: 'Artwork Size',
              value: _selectedSize,
              options: _sizeOptions,
              onChanged: (value) {
                setState(() {
                  _selectedSize = value;
                  _sizeMultiplier = _getSizeMultiplier(value);
                });
              },
              tooltipText: 'Larger pieces typically command higher prices',
            ),
            const SizedBox(height: 12),

            // Established Artist Toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Established Artist',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Add 30% to final price',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEstablished,
                    onChanged: (value) {
                      setState(() {
                        _isEstablished = value;
                      });
                    },
                    activeThumbColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Price Breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _BreakdownRow(
                    label: 'Base Cost (Hours × Rate)',
                    value:
                        '\$${(_productionHours * _baseHourlyRate).toStringAsFixed(2)}',
                  ),
                  _BreakdownRow(
                    label: 'Medium Multiplier',
                    value: '${_mediumMultiplier.toStringAsFixed(1)}x',
                  ),
                  _BreakdownRow(
                    label: 'Size Multiplier',
                    value: '${_sizeMultiplier.toStringAsFixed(1)}x',
                  ),
                  _BreakdownRow(
                    label: 'Experience Factor',
                    value:
                        '${(1.0 + (_experienceLevel * 0.1)).toStringAsFixed(2)}x',
                  ),
                  _BreakdownRow(
                    label: 'Skill Factor',
                    value: '${(_skillRating / 3.0).toStringAsFixed(2)}x',
                  ),
                  if (_isEstablished)
                    _BreakdownRow(
                      label: 'Established Bonus',
                      value: '1.30x',
                    ),
                  const Divider(color: Colors.grey),
                  _BreakdownRow(
                    label: 'Final Suggested Price',
                    value: '\$${suggestedPrice.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        'Pro Tips',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Research comparable artists in your niche\n'
                    '• Consider your local market and demand\n'
                    '• Factor in materials and overhead costs\n'
                    '• Be open to negotiating with collectors\n'
                    '• Update prices as your experience grows',
                    style: TextStyle(color: Colors.grey[300], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _FactorCard extends StatelessWidget {
  final String title;
  final String value;
  final Function(double) onChanged;
  final double min;
  final double max;
  final String tooltipText;

  const _FactorCard({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.tooltipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Tooltip(
                message: tooltipText,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: double.parse(value),
            min: min,
            max: max,
            divisions: ((max - min) ~/ 1),
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}

class _SkillRatingCard extends StatelessWidget {
  final double rating;
  final Function(double) onChanged;

  const _SkillRatingCard({
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Skill Level',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${'⭐' * rating.toInt()} ${rating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: rating,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final Function(String) onChanged;
  final String tooltipText;

  const _DropdownCard({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.tooltipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: options
                .map((option) =>
                    DropdownMenuItem(value: option, child: Text(option)))
                .toList(),
            onChanged: (selected) {
              if (selected != null) onChanged(selected);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[700],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tooltipText,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _BreakdownRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? Colors.white : Colors.grey[400],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isBold ? Colors.deepPurple : Colors.grey[300],
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

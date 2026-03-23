import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'subscription_plans_screen.dart';

class MockupTab extends StatefulWidget {
  const MockupTab({super.key});

  @override
  State<MockupTab> createState() => _MockupTabState();
}

class _MockupTabState extends State<MockupTab> {
  final ImagePicker _imagePicker = ImagePicker();
  String _selectedEnvironment = 'Modern Living Room';
  String _selectedArtSize = 'Medium (24x36)';
  Color _selectedWallColor = Colors.grey[400]!;
  double _rotationAngle = 0;
  Uint8List? _selectedArtworkBytes;
  String? _selectedArtworkName;

  final List<String> _environments = [
    'Modern Living Room',
    'Minimalist Office',
    'Gallery White Wall',
    'Brick Loft',
    'Bedroom Accent Wall',
    'Cafe Corner',
  ];

  final List<String> _artSizes = [
    'Small (8x10)',
    'Medium (24x36)',
    'Large (36x48)',
    'Extra Large (48x60)',
  ];

  final List<Color> _wallColors = [
    Colors.white,
    Colors.grey.shade200,
    Colors.grey.shade400,
    Color(0xFF4A4A4A),
    Color(0xFFE8DCC8), // Off-white
    Color(0xFF2D5F7F), // Blue-grey
    Color(0xFFF5E6D3), // Beige
  ];

  final Map<String, String> _environmentDescriptions = {
    'Modern Living Room': 'Bright, contemporary space with neutral tones',
    'Minimalist Office': 'Clean, professional environment',
    'Gallery White Wall': 'Traditional gallery setting',
    'Brick Loft': 'Industrial, rustic aesthetic',
    'Bedroom Accent Wall': 'Intimate, personal space',
    'Cafe Corner': 'Casual, social environment',
  };

  double _getArtWidth(String size) {
    switch (size) {
      case 'Small (8x10)':
        return 120;
      case 'Medium (24x36)':
        return 180;
      case 'Large (36x48)':
        return 250;
      case 'Extra Large (48x60)':
        return 320;
      default:
        return 180;
    }
  }

  Future<void> _pickArtwork() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedArtworkBytes = bytes;
        _selectedArtworkName = pickedFile.name;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load artwork: $error')),
      );
    }
  }

  Widget _buildArtworkSurface() {
    if (_selectedArtworkBytes == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade400,
              Colors.blue.shade400,
              Colors.pink.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 48,
                color: Colors.white30,
              ),
              SizedBox(height: 8),
              Text(
                'Your Artwork',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.memory(
      _selectedArtworkBytes!,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Art Mockup Viewer'),
        actions: [
          IconButton(
            tooltip: 'Checkout Plans',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPlansScreen(),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart_checkout),
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Environment Preview
                  Container(
                    width: double.infinity,
                    height: 400,
                    decoration: BoxDecoration(
                      color: _selectedWallColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Wall pattern/texture background
                        _buildEnvironmentBackground(
                          _selectedEnvironment,
                          _selectedWallColor,
                        ),

                        // Art preview
                        Transform.rotate(
                          angle: _rotationAngle,
                          child: Container(
                            width: _getArtWidth(_selectedArtSize),
                            height: _getArtWidth(_selectedArtSize) * 1.5,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.brown,
                                width: 8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                  offset: const Offset(5, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              child: _buildArtworkSurface(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedArtworkName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Loaded artwork: $_selectedArtworkName',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.green[200],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Text(
                    _environmentDescriptions[_selectedEnvironment] ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Controls Section
            Text(
              'Customize Mockup',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pickArtwork,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(
                  _selectedArtworkBytes == null
                      ? 'Upload Artwork For Preview'
                      : 'Replace Uploaded Artwork',
                ),
              ),
            ),
            if (_selectedArtworkBytes != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedArtworkBytes = null;
                      _selectedArtworkName = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Uploaded Artwork'),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Environment Selector
            Text(
              'Environment',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                children: _environments
                    .map(
                      (env) => Container(
                        margin: const EdgeInsets.all(4),
                        child: FilterChip(
                          label: Text(env),
                          selected: _selectedEnvironment == env,
                          onSelected: (selected) {
                            setState(() {
                              _selectedEnvironment = env;
                            });
                          },
                          selectedColor: Colors.deepPurple,
                          backgroundColor: Colors.grey[700],
                          labelStyle: TextStyle(
                            color: _selectedEnvironment == env
                                ? Colors.white
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Art Size Selector
            Text(
              'Art Size',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                children: _artSizes
                    .map(
                      (size) => Container(
                        margin: const EdgeInsets.all(4),
                        child: FilterChip(
                          label: Text(size),
                          selected: _selectedArtSize == size,
                          onSelected: (selected) {
                            setState(() {
                              _selectedArtSize = size;
                            });
                          },
                          selectedColor: Colors.deepPurple,
                          backgroundColor: Colors.grey[700],
                          labelStyle: TextStyle(
                            color: _selectedArtSize == size
                                ? Colors.white
                                : Colors.grey[300],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Wall Color Selector
            Text(
              'Wall Color',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _wallColors
                    .map(
                      (color) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWallColor = color;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: _selectedWallColor == color
                                  ? Colors.deepPurple
                                  : Colors.grey,
                              width: _selectedWallColor == color ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Rotation Control
            Text(
              'Frame Angle',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tilt Frame'),
                      Text(
                        '${_rotationAngle.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _rotationAngle,
                    min: -0.1,
                    max: 0.1,
                    divisions: 20,
                    onChanged: (value) {
                      setState(() {
                        _rotationAngle = value;
                      });
                    },
                    activeColor: Colors.deepPurple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedEnvironment = 'Modern Living Room';
                        _selectedArtSize = 'Medium (24x36)';
                        _selectedWallColor = Colors.grey[400]!;
                        _rotationAngle = 0;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mockup saved! (Feature coming soon)'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Tips Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade400),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Better Presentation',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade400,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Show your art in different sizes to help buyers visualize it\n'
                    '• Test multiple wall colors for different aesthetics\n'
                    '• A slight tilt can make framed art look more natural\n'
                    '• Use mockups to showcase versatility in listings\n'
                    '• Different rooms convey different moods',
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

  Widget _buildEnvironmentBackground(String environment, Color wallColor) {
    switch (environment) {
      case 'Modern Living Room':
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    wallColor,
                    Color.lerp(wallColor, Colors.black, 0.18) ?? wallColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 82,
                decoration: BoxDecoration(
                  color: const Color(0xFF25282E).withValues(alpha: 0.9),
                ),
              ),
            ),
            Positioned(
              left: 36,
              bottom: 34,
              child: Container(
                width: 120,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFB88A5D),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              right: 34,
              bottom: 30,
              child: Container(
                width: 44,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C7A5),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ],
        );
      case 'Minimalist Office':
        return Stack(
          children: [
            Container(color: Color.lerp(wallColor, Colors.blueGrey, 0.15)),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2F36).withValues(alpha: 0.95),
                ),
              ),
            ),
            Positioned(
              left: 40,
              right: 40,
              bottom: 38,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF848E9A),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Positioned(
              right: 48,
              bottom: 52,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2229),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        );
      case 'Brick Loft':
        return Stack(
          children: [
            Container(color: wallColor),
            CustomPaint(
              painter: BrickPatternPainter(
                brickColor:
                    Color.lerp(wallColor, Colors.brown, 0.45) ?? Colors.brown,
                mortarColor: Colors.black.withValues(alpha: 0.08),
              ),
              size: Size.infinite,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 86,
                color: const Color(0xFF2A2622).withValues(alpha: 0.92),
              ),
            ),
          ],
        );
      case 'Bedroom Accent Wall':
        return Stack(
          children: [
            Container(color: wallColor),
            Positioned(
              left: 18,
              right: 18,
              bottom: 34,
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFDED4C8).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 52,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8A999),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8A999),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 40,
                color: const Color(0xFF6A5E52).withValues(alpha: 0.85),
              ),
            ),
          ],
        );
      case 'Cafe Corner':
        return Stack(
          children: [
            Container(color: wallColor),
            Positioned(
              left: 24,
              bottom: 22,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: const Color(0xFF4B3621),
                  borderRadius: BorderRadius.circular(37),
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFF6E4D2F),
                  borderRadius: BorderRadius.circular(29),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 58,
                color: const Color(0xFF2F241A).withValues(alpha: 0.88),
              ),
            ),
          ],
        );
      case 'Gallery White Wall':
        return Container(
          decoration: BoxDecoration(
            color: Color.lerp(wallColor, Colors.white, 0.35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
              ),
            ],
          ),
        );
      default:
        return Container();
    }
  }
}

class BrickPatternPainter extends CustomPainter {
  const BrickPatternPainter({
    required this.brickColor,
    required this.mortarColor,
  });

  final Color brickColor;
  final Color mortarColor;

  @override
  void paint(Canvas canvas, Size size) {
    final brickPaint = Paint()..color = brickColor;
    final linePaint = Paint()
      ..color = mortarColor
      ..strokeWidth = 1;

    const brickWidth = 60.0;
    const brickHeight = 30.0;

    for (double y = 0; y < size.height; y += brickHeight) {
      for (double x = 0; x < size.width; x += brickWidth) {
        final offset = (y / brickHeight).toInt().isEven ? brickWidth / 2 : 0.0;
        final rect = Rect.fromLTWH(x + offset, y, brickWidth, brickHeight);
        canvas.drawRect(rect, brickPaint);
        canvas.drawRect(rect, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(BrickPatternPainter oldDelegate) => false;
}

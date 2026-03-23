import 'package:flutter/material.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 72,
    this.showWordmark = false,
    this.align = CrossAxisAlignment.center,
    this.titleStyle,
    this.subtitleStyle,
  });

  final double size;
  final bool showWordmark;
  final CrossAxisAlignment align;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final defaultTitle = Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        );
    final defaultSubtitle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.6),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        );

    final logo = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF15353B), Color(0xFF1F1A14)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF32C7B8).withValues(alpha: 0.75),
                width: size * 0.05,
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.45,
            child: Container(
              width: size * 0.22,
              height: size * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8B86D), Color(0xFF32C7B8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF32C7B8).withValues(alpha: 0.25),
                    blurRadius: size * 0.16,
                    offset: Offset(0, size * 0.05),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: size * 0.16,
            height: size * 0.16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0B1016),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) {
      return logo;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        logo,
        SizedBox(height: size * 0.22),
        Text('ArtConnect', style: titleStyle ?? defaultTitle),
        SizedBox(height: size * 0.06),
        Text(
          'ATELIER SOCIAL',
          style: subtitleStyle ?? defaultSubtitle,
        ),
      ],
    );
  }
}

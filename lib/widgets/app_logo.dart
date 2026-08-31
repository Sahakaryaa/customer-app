import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Official Sahakarya Sarathi Logo Widget
class AppLogo extends StatelessWidget {
  final double size;
  final bool showBadge;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 64,
    this.showBadge = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D5238).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF0D5238).withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(size * 0.08),
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            width: size * 0.84,
            height: size * 0.84,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => Image.asset(
              'assets/images/logo.png',
              width: size * 0.84,
              height: size * 0.84,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D5238),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/cloud_account.dart';

class CloudProviderIcon extends StatelessWidget {
  const CloudProviderIcon({
    super.key,
    required this.provider,
    this.size = 24,
    this.withBackground = false,
  });

  final CloudProvider provider;
  final double size;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final icon = _buildIcon();
    if (!withBackground) return icon;

    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: icon),
    );
  }

  Widget _buildIcon() {
    switch (provider) {
      case CloudProvider.google:
        return _GoogleIcon(size: size);
      case CloudProvider.microsoft:
        return _MicrosoftIcon(size: size);
      case CloudProvider.dropbox:
        return _DropboxIcon(size: size);
      case CloudProvider.terabox:
        return _TeraboxIcon(size: size);
      case CloudProvider.mega:
        return _MegaIcon(size: size);
      case CloudProvider.apple:
        return _AppleIcon(size: size);
    }
  }

  Color get _backgroundColor {
    switch (provider) {
      case CloudProvider.google: return AppColors.googleBlue;
      case CloudProvider.microsoft: return AppColors.microsoftBlue;
      case CloudProvider.dropbox: return const Color(0xFF0061FE);
      case CloudProvider.terabox: return const Color(0xFF1296DB);
      case CloudProvider.mega: return const Color(0xFFD9272E);
      case CloudProvider.apple: return const Color(0xFF555555);
    }
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Simplified Google "G" representation using colored arcs
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = size.width * 0.15;

    // Blue arc (top-right)
    paint.color = AppColors.googleBlue;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.85),
        -0.4, 1.8, false, paint);

    // Red arc (top-left to bottom-left)
    paint.color = AppColors.googleRed;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.85),
        1.4, 1.6, false, paint);

    // Yellow arc (bottom)
    paint.color = const Color(0xFFFBBC04);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.85),
        3.0, 0.7, false, paint);

    // Green arc (bottom-right)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.85),
        3.7, 0.7, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MicrosoftIcon extends StatelessWidget {
  const _MicrosoftIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final blockSize = size * 0.46;
    final gap = size * 0.08;

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: blockSize, height: blockSize, color: const Color(0xFFF25022)),
              SizedBox(width: gap),
              Container(width: blockSize, height: blockSize, color: const Color(0xFF7FBA00)),
            ],
          ),
          SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: blockSize, height: blockSize, color: const Color(0xFF00A4EF)),
              SizedBox(width: gap),
              Container(width: blockSize, height: blockSize, color: const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropboxIcon extends StatelessWidget {
  const _DropboxIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DropboxLogoPainter()),
    );
  }
}

class _DropboxLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0061FE)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Dropbox logo: 5 rhombuses, wider than tall (≈ 4:3 ratio),
    // matching the official logo geometry.
    // rw = horizontal half-width, rh = vertical half-height.
    final rw = w * 0.290;
    final rh = h * 0.210;

    void drawBox(double cx, double cy) {
      final path = Path()
        ..moveTo(cx,      cy - rh) // top
        ..lineTo(cx + rw, cy)      // right
        ..lineTo(cx,      cy + rh) // bottom
        ..lineTo(cx - rw, cy)      // left
        ..close();
      canvas.drawPath(path, paint);
    }

    // Top pair — sit high, spread left/right
    drawBox(w * 0.275, h * 0.305);
    drawBox(w * 0.725, h * 0.305);
    // Bridge — connects the two pairs, centred horizontally
    drawBox(w * 0.500, h * 0.510);
    // Bottom pair — mirror of top pair
    drawBox(w * 0.275, h * 0.715);
    drawBox(w * 0.725, h * 0.715);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TeraboxIcon extends StatelessWidget {
  const _TeraboxIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _TeraboxLogoPainter()),
    );
  }
}

class _TeraboxLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Teal/blue circle background
    final bgPaint = Paint()
      ..color = const Color(0xFF1296DB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // White "T" letter
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final strokeW = w * 0.14;
    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.25, w * 0.64, strokeW),
        Radius.circular(strokeW / 2),
      ),
      paint,
    );
    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.43, h * 0.25, strokeW, h * 0.5),
        Radius.circular(strokeW / 2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MegaIcon extends StatelessWidget {
  const _MegaIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MegaLogoPainter()),
    );
  }
}

class _MegaLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Red circle background
    final bgPaint = Paint()
      ..color = const Color(0xFFD9272E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // White "M" letter
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final path = Path();
    final left = w * 0.15;
    final right = w * 0.85;
    final top = h * 0.28;
    final bottom = h * 0.72;
    final mid = h * 0.55;
    final barW = w * 0.12;

    // Left vertical bar
    path.addRect(Rect.fromLTWH(left, top, barW, bottom - top));
    // Right vertical bar
    path.addRect(Rect.fromLTWH(right - barW, top, barW, bottom - top));
    // Left diagonal
    final cx = w / 2;
    final diag = Path()
      ..moveTo(left, top)
      ..lineTo(left + barW, top)
      ..lineTo(cx, mid)
      ..lineTo(cx - barW * 0.5, mid)
      ..close();
    canvas.drawPath(diag, paint);
    // Right diagonal
    final diag2 = Path()
      ..moveTo(right, top)
      ..lineTo(right - barW, top)
      ..lineTo(cx, mid)
      ..lineTo(cx + barW * 0.5, mid)
      ..close();
    canvas.drawPath(diag2, paint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppleLogoPainter()),
    );
  }
}

class _AppleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dark grey circle background
    final bgPaint = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // White Apple logo silhouette (simplified)
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    // Apple body — rounded rectangle slightly left of centre
    final bodyL = w * 0.26;
    final bodyT = h * 0.30;
    final bodyW = w * 0.50;
    final bodyH = h * 0.48;
    final rr = bodyW * 0.38;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyL, bodyT, bodyW, bodyH),
        Radius.circular(rr),
      ),
      paint,
    );

    // Bite — dark ellipse on the top-right of the body
    final bitePaint = Paint()
      ..color = const Color(0xFF555555)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyL + bodyW * 0.72, bodyT + bodyH * 0.07),
        width: bodyW * 0.40,
        height: bodyH * 0.28,
      ),
      bitePaint,
    );

    // Stem — small rounded rectangle at top centre
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, h * 0.18, w * 0.09, h * 0.14),
        const Radius.circular(3),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

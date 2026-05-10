import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// CloudVault brand logo — a gradient rounded square with a cloud-analytics icon.
/// Use [size] to scale; [showShadow] for the large login-screen variant.
class CloudVaultLogo extends StatelessWidget {
  const CloudVaultLogo({super.key, this.size = 40, this.showShadow = false});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandDark, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.275),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.brandDark.withValues(alpha: 0.45),
                  blurRadius: size * 0.28,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // White cloud: union of three circles + a rounded-rect base
    final cloud = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * .50, h * .37), radius: w * .22))
      ..addOval(Rect.fromCircle(center: Offset(w * .29, h * .44), radius: w * .16))
      ..addOval(Rect.fromCircle(center: Offset(w * .71, h * .43), radius: w * .15))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .12, h * .46, w * .76, h * .24),
        Radius.circular(h * .12),
      ));
    canvas.drawPath(cloud, Paint()..color = Colors.white);

    // Brand-coloured bar chart on top of the cloud — represents analytics
    final barPaint = Paint()
      ..color = AppColors.brandDark
      ..style = PaintingStyle.fill;
    const topR = Radius.circular(2);
    final barW = w * .105;
    final bottom = h * .665;
    for (final (cx, barH) in [
      (w * .30, h * .13),
      (w * .50, h * .20),
      (w * .70, h * .10),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - barW / 2, bottom - barH, barW, barH),
          topLeft: topR,
          topRight: topR,
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter _) => false;
}

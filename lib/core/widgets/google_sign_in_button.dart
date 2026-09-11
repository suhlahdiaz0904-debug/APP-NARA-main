import 'package:flutter/material.dart';

/// Custom Painter untuk menggambar logo resmi 4 warna Google "G"
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double center = w / 2;
    final double radius = w / 2;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Red (Top & Top-Left)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(center, center)
      ..lineTo(center + radius * 0.95, center - radius * 0.45)
      ..arcToPoint(
        Offset(center - radius * 0.72, center - radius * 0.72),
        radius: Radius.circular(radius),
      )
      ..close();
    canvas.drawPath(redPath, paint);

    // Yellow (Left & Bottom-Left)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(center, center)
      ..lineTo(center - radius * 0.72, center - radius * 0.72)
      ..arcToPoint(
        Offset(center - radius * 0.72, center + radius * 0.72),
        radius: Radius.circular(radius),
      )
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green (Bottom & Bottom-Right)
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(center, center)
      ..lineTo(center - radius * 0.72, center + radius * 0.72)
      ..arcToPoint(
        Offset(center + radius * 0.88, center + radius * 0.55),
        radius: Radius.circular(radius),
      )
      ..close();
    canvas.drawPath(greenPath, paint);

    // Blue (Right bar & Blue Arc)
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(center, center)
      ..lineTo(center + radius * 0.88, center + radius * 0.55)
      ..arcToPoint(
        Offset(center + radius, center),
        radius: Radius.circular(radius),
      )
      ..lineTo(center, center)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Blue Crossbar
    final Rect blueBar = Rect.fromLTWH(
      center - 1,
      center - radius * 0.28,
      radius * 1.05,
      radius * 0.56,
    );
    canvas.drawRect(blueBar, paint);

    // White Center Cutout
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center, center), radius * 0.54, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget Bar/Tombol Google Sign-In dengan desain modern, serasi dengan tema NARA
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Daftar dengan Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF202124),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Google resmi yang tajam & independen dari aset file
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CustomPaint(
                      painter: GoogleLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF202124),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.3,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

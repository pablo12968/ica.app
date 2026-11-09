import 'package:flutter/material.dart';

import 'models.dart';

const ink = Color(0xff160c34);
const violet = Color(0xff8025ff);
const canvas = Color(0xfffcfaff);
const muted = Color(0xff77738b);

String? productAsset(Product product) {
  final name = product.name.toLowerCase();
  for (final entry in {
    'fresa': 'strawberry',
    'chocolate': 'chocolate',
    'vainilla': 'vanilla',
    'mango': 'mango',
    'limón': 'lime',
    'pistacho': 'pistachio',
  }.entries) {
    if (name.contains(entry.key)) return 'assets/images/${entry.value}.png';
  }
  return null;
}

class ProductPhoto extends StatelessWidget {
  const ProductPhoto(this.product, {super.key, this.fit = BoxFit.cover});
  final Product product;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final asset = productAsset(product);
    return asset == null
        ? Center(child: IceCreamArt(flavor: product.id - 1))
        : Image.asset(
            asset,
            fit: fit,
            alignment: Alignment.topCenter,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, error, stack) =>
                Center(child: IceCreamArt(flavor: product.id - 1)),
          );
  }
}

class SoftPanel extends StatelessWidget {
  const SoftPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffeeebf5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0874409c),
          blurRadius: 22,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    ),
  );
}

/// Ilustraciones locales: también funcionan sin conexión en el APK.
class IceCreamArt extends StatelessWidget {
  const IceCreamArt({super.key, this.flavor = 0, this.size = 160});
  final int flavor;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _IceCreamPainter(flavor)),
  );
}

class _IceCreamPainter extends CustomPainter {
  _IceCreamPainter(this.flavor);
  final int flavor;
  static const colors = [
    Color(0xffff71a2),
    Color(0xff99614e),
    Color(0xffffdda0),
    Color(0xffffb335),
    Color(0xffb9db69),
    Color(0xff8ec9aa),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    final color = colors[flavor.abs() % colors.length];
    canvas.drawOval(
      const Rect.fromLTWH(48, 175, 104, 12),
      Paint()..color = ink.withValues(alpha: .08),
    );
    final cone = Path()
      ..moveTo(63, 94)
      ..lineTo(137, 94)
      ..lineTo(105, 177)
      ..quadraticBezierTo(100, 185, 95, 177)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xfff2bb77), Color(0xffd98d4b)],
        ).createShader(const Rect.fromLTWH(63, 94, 74, 88)),
    );
    canvas.save();
    canvas.clipPath(cone);
    final waffle = Paint()
      ..color = const Color(0xffb67436).withValues(alpha: .35)
      ..strokeWidth = 2;
    for (double i = -40; i < 160; i += 15) {
      canvas.drawLine(Offset(40 + i, 90), Offset(120 + i, 190), waffle);
      canvas.drawLine(Offset(160 - i, 90), Offset(80 - i, 190), waffle);
    }
    canvas.restore();
    final scoop = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.45, -.5),
        radius: 1,
        colors: [Color.lerp(color, Colors.white, .4)!, color],
      ).createShader(const Rect.fromLTWH(48, 28, 104, 94));
    canvas.drawCircle(const Offset(100, 73), 47, scoop);
    for (final point in [
      const Offset(64, 99),
      const Offset(86, 106),
      const Offset(111, 106),
      const Offset(135, 97),
    ]) {
      canvas.drawCircle(point, 15, scoop);
    }
    canvas.drawOval(
      const Rect.fromLTWH(70, 42, 30, 15),
      Paint()..color = Colors.white.withValues(alpha: .25),
    );
    final sprinkle = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const points = [
      Offset(83, 67),
      Offset(112, 51),
      Offset(121, 83),
      Offset(96, 90),
      Offset(67, 85),
    ];
    for (var i = 0; i < points.length; i++) {
      sprinkle.color = i.isEven
          ? Colors.white.withValues(alpha: .8)
          : const Color(0xff693b67);
      canvas.drawLine(points[i], points[i] + const Offset(5, 3), sprinkle);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IceCreamPainter oldDelegate) =>
      oldDelegate.flavor != flavor;
}

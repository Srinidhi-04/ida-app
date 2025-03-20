import 'dart:async';

import 'package:flutter/material.dart';

class CirclePainter extends CustomPainter {
  Color color;
  Offset location;
  CirclePainter({required this.color, required this.location});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.strokeWidth = 2;
    paint.color = color;
    paint.shader = RadialGradient(colors: [color, Colors.white]).createShader(Rect.fromCircle(center: location, radius: size.width/2));
    canvas.drawCircle(location, size.width/2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 1), () => Navigator.popAndPushNamed(context, "/home"));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(350, 350),
              painter: CirclePainter(color: Theme.of(context).primaryColorDark, location: Offset(0, MediaQuery.of(context).size.height)),
            ),
            CustomPaint(
              size: Size(350, 350),
              painter: CirclePainter(color: Theme.of(context).primaryColorLight, location: Offset(MediaQuery.of(context).size.width, 0)),
            ),
            Container(
              color: Color(0x77FFFFFF),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Center(child: Image(image: NetworkImage("https://i.imgur.com/0FHQKN4.png")),)),
          ],
        )
      ),
    );
  }
}
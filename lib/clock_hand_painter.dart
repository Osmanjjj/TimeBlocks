import 'package:flutter/material.dart';
import 'dart:math' as math;

// 時計の針を描画するカスタムペインター
class ClockHandPainter extends CustomPainter {
  final DateTime currentTime;
  
  ClockHandPainter(this.currentTime);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 24時間制での角度計算（0時が上、時計回り）
    final hour = currentTime.hour;
    final minute = currentTime.minute;
    final totalMinutes = hour * 60 + minute;
    final angle = (totalMinutes / (24 * 60)) * 2 * math.pi - math.pi / 2; // -π/2で上から開始
    
    // 針の終点を計算（円グラフの外側まで）
    final handEnd = Offset(
      center.dx + (radius - 20) * math.cos(angle), // 少し内側に
      center.dy + (radius - 20) * math.sin(angle),
    );
    
    // 針を描画
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, handEnd, paint);
    
    // 中心の円を描画
    final centerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 6, centerPaint);
  }
  
  @override
  bool shouldRepaint(ClockHandPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime;
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import 'models/task.dart';

// 完了タスクに横線を表示するCustomPainter
class CompletedTaskLinePainter extends CustomPainter {
  final List<Task> tasks;
  
  CompletedTaskLinePainter(this.tasks);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 80.0; // グラフの半径と同じ
    
    double currentAngle = -90 * (pi / 180); // 上から開始（-90度）
    const double totalMinutes = 24 * 60;
    
    double currentMinute = 0;
    
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final taskStartMinute = task.dueDate!.hour * 60.0 + task.dueDate!.minute;
      
      // 空き時間をスキップ
      if (taskStartMinute > currentMinute) {
        final freeTimeAngle = ((taskStartMinute - currentMinute) / totalMinutes) * 2 * pi;
        currentAngle += freeTimeAngle;
      }
      
      // タスクが完了している場合、横線を描画
      if (task.isCompleted) {
        final taskAngle = (task.durationMinutes / totalMinutes) * 2 * pi;
        final middleAngle = currentAngle + (taskAngle / 2);
        
        // 横線の開始点と終了点を計算
        final innerRadius = radius - 20;
        final outerRadius = radius + 20;
        
        final startPoint = Offset(
          center.dx + innerRadius * cos(middleAngle),
          center.dy + innerRadius * sin(middleAngle),
        );
        
        final endPoint = Offset(
          center.dx + outerRadius * cos(middleAngle),
          center.dy + outerRadius * sin(middleAngle),
        );
        
        canvas.drawLine(startPoint, endPoint, paint);
      }
      
      final taskAngle = (task.durationMinutes / totalMinutes) * 2 * pi;
      currentAngle += taskAngle;
      currentMinute = taskStartMinute + task.durationMinutes;
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

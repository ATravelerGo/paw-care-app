import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/weight_trend.dart';

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({required this.points, super.key});

  final List<WeightMeasurement> points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: _semanticsLabel(points),
      image: true,
      child: SizedBox(
        key: const Key('weight_trend_chart'),
        height: 240,
        width: double.infinity,
        child: CustomPaint(
          painter: _WeightTrendPainter(
            points: points,
            lineColor: colorScheme.primary,
            gridColor: colorScheme.outlineVariant,
            labelColor: colorScheme.onSurfaceVariant,
            anomalyColor: colorScheme.error,
          ),
        ),
      ),
    );
  }
}

class _WeightTrendPainter extends CustomPainter {
  const _WeightTrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.anomalyColor,
  });

  final List<WeightMeasurement> points;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final Color anomalyColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 46.0;
    const top = 16.0;
    const right = 12.0;
    const bottom = 34.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final weights = points.map((point) => point.kilograms);
    final rawMin = weights.reduce(math.min);
    final rawMax = weights.reduce(math.max);
    final padding = math.max((rawMax - rawMin) * 0.15, 0.2);
    final minWeight = math.max(0, rawMin - padding);
    final maxWeight = rawMax + padding;
    final dateSpan = math.max(
      1,
      points.last.date.difference(points.first.date).inMilliseconds,
    );

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (var index = 0; index < 4; index++) {
      final ratio = index / 3;
      final y = chart.top + chart.height * ratio;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final value = maxWeight - (maxWeight - minWeight) * ratio;
      _paintText(
        canvas,
        '${value.toStringAsFixed(1)} kg',
        Offset(0, y - 7),
        labelColor,
        fontSize: 11,
      );
    }

    Offset positionFor(WeightMeasurement point) {
      final xRatio =
          point.date.difference(points.first.date).inMilliseconds / dateSpan;
      final yRatio = (point.kilograms - minWeight) / (maxWeight - minWeight);
      return Offset(
        chart.left + chart.width * xRatio,
        chart.bottom - chart.height * yRatio,
      );
    }

    final positions = points.map(positionFor).toList(growable: false);
    final linePath = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (final position in positions.skip(1)) {
      linePath.lineTo(position.dx, position.dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(positions.last.dx, chart.bottom)
      ..lineTo(positions.first.dx, chart.bottom)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    for (var index = 0; index < positions.length; index++) {
      final point = points[index];
      canvas.drawCircle(
        positions[index],
        point.isAnomalous ? 5 : 4,
        Paint()..color = point.isAnomalous ? anomalyColor : lineColor,
      );
    }

    _paintText(
      canvas,
      _dateLabel(points.first.date),
      Offset(chart.left, chart.bottom + 10),
      labelColor,
      fontSize: 11,
    );
    final endLabel = _dateLabel(points.last.date);
    final endPainter = _textPainter(endLabel, labelColor, 11)..layout();
    endPainter.paint(
      canvas,
      Offset(chart.right - endPainter.width, chart.bottom + 10),
    );
  }

  @override
  bool shouldRepaint(covariant _WeightTrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.anomalyColor != anomalyColor;
}

void _paintText(
  Canvas canvas,
  String text,
  Offset offset,
  Color color, {
  required double fontSize,
}) {
  final painter = _textPainter(text, color, fontSize)..layout();
  painter.paint(canvas, offset);
}

TextPainter _textPainter(String text, Color color, double fontSize) =>
    TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

String _dateLabel(DateTime date) => '${date.month}/${date.day}';

String _semanticsLabel(List<WeightMeasurement> points) {
  final first = points.first;
  final last = points.last;
  return '体重趋势图，共${points.length}条记录，'
      '从${first.kilograms.toStringAsFixed(1)}公斤变化到'
      '${last.kilograms.toStringAsFixed(1)}公斤';
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/dashboard_charts_response.dart';

class FlujoBarChart extends StatelessWidget {
  final List<FlujoNetoPorMes> datos;

  const FlujoBarChart({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return const Center(
        child: Text(
          'No hay movimientos en este periodo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final intervaloEtiquetas = _calcularIntervaloEtiquetas(
          constraints.maxWidth,
        );

        final anchoBarra = constraints.maxWidth < 400 ? 9.0 : 14.0;

        final espacio = constraints.maxWidth < 400 ? 3.0 : 5.0;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,

            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) {
                return const FlLine(color: Color(0xFFE7EAF0), strokeWidth: 1);
              },
            ),

            borderData: FlBorderData(show: false),

            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),

              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: constraints.maxWidth < 400 ? 47 : 55,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatearMontoCorto(value),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                      ),
                    );
                  },
                ),
              ),

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();

                    if (index < 0 || index >= datos.length) {
                      return const SizedBox.shrink();
                    }

                    if (index % intervaloEtiquetas != 0 &&
                        index != datos.length - 1) {
                      return const SizedBox.shrink();
                    }

                    final dato = datos[index];

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_nombreMes(dato.mes)} '
                        '${dato.anio}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final dato = datos[group.x];

                  final texto = rodIndex == 0 ? 'Ingresos' : 'Egresos';

                  final monto = rodIndex == 0
                      ? dato.totalIngresos
                      : dato.totalEgresos;

                  return BarTooltipItem(
                    '$texto\n'
                    '${_formatearMoneda(monto)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),

            barGroups: List.generate(datos.length, (index) {
              final dato = datos[index];

              return BarChartGroupData(
                x: index,
                barsSpace: espacio,
                barRods: [
                  BarChartRodData(
                    toY: dato.totalIngresos,
                    width: anchoBarra,
                    color: const Color(0xFF2563EB),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),

                  BarChartRodData(
                    toY: dato.totalEgresos,
                    width: anchoBarra,
                    color: const Color(0xFFF59E0B),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  int _calcularIntervaloEtiquetas(double ancho) {
    final maximo = ancho < 350
        ? 3
        : ancho < 500
        ? 4
        : 6;

    if (datos.length <= maximo) {
      return 1;
    }

    return (datos.length / maximo).ceil();
  }

  String _nombreMes(int mes) {
    const meses = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    if (mes < 1 || mes > 12) {
      return '';
    }

    return meses[mes];
  }

  String _formatearMontoCorto(double valor) {
    if (valor >= 1000000) {
      return 'S/ ${(valor / 1000000).toStringAsFixed(1)}M';
    }

    if (valor >= 1000) {
      return 'S/ ${(valor / 1000).toStringAsFixed(1)}K';
    }

    return 'S/ ${valor.toStringAsFixed(0)}';
  }

  String _formatearMoneda(double valor) {
    if (valor < 0) {
      return '-S/ ${valor.abs().toStringAsFixed(2)}';
    }

    return 'S/ ${valor.toStringAsFixed(2)}';
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_charts_response.dart';

class VentasLineChart extends StatelessWidget {
  final List<VentaPorDia> ventas;

  const VentasLineChart({super.key, required this.ventas});

  @override
  Widget build(BuildContext context) {
    if (ventas.isEmpty) {
      return const _EmptyChart(mensaje: 'No hay ventas en este periodo.');
    }

    final spots = <FlSpot>[];

    for (var i = 0; i < ventas.length; i++) {
      spots.add(FlSpot(i.toDouble(), ventas[i].totalVendido));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final intervaloEtiquetas = _calcularIntervaloEtiquetas(
          constraints.maxWidth,
        );

        final reservedLeft = constraints.maxWidth < 400 ? 48.0 : 56.0;

        return LineChart(
          LineChartData(
            minX: 0,
            maxX: (ventas.length - 1).toDouble(),
            minY: 0,

            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _calcularIntervalo(),
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
                  reservedSize: reservedLeft,
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

                    if (index < 0 || index >= ventas.length) {
                      return const SizedBox.shrink();
                    }

                    if (index % intervaloEtiquetas != 0 &&
                        index != ventas.length - 1) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('dd/MM').format(ventas[index].fecha),
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

            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    final index = spot.x.toInt();

                    if (index < 0 || index >= ventas.length) {
                      return null;
                    }

                    final venta = ventas[index];

                    return LineTooltipItem(
                      '${DateFormat('dd/MM/yyyy').format(venta.fecha)}\n'
                      'S/ ${venta.totalVendido.toStringAsFixed(2)}\n'
                      '${venta.cantidadVentas} ventas',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.25,
                barWidth: 3,
                color: const Color(0xFF2563EB),

                dotData: FlDotData(show: ventas.length <= 20),

                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _calcularIntervaloEtiquetas(double ancho) {
    if (ventas.length <= 1) {
      return 1;
    }

    final cantidadMaxima = ancho < 350
        ? 3
        : ancho < 500
        ? 4
        : ancho < 750
        ? 6
        : 8;

    if (ventas.length <= cantidadMaxima) {
      return 1;
    }

    return (ventas.length / cantidadMaxima).ceil();
  }

  double _calcularIntervalo() {
    if (ventas.isEmpty) {
      return 100;
    }

    final maximo = ventas
        .map((venta) => venta.totalVendido)
        .reduce((a, b) => a > b ? a : b);

    if (maximo <= 100) {
      return 20;
    }

    if (maximo <= 500) {
      return 100;
    }

    if (maximo <= 1000) {
      return 200;
    }

    return maximo / 5;
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
}

class _EmptyChart extends StatelessWidget {
  final String mensaje;

  const _EmptyChart({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/dashboard_charts_response.dart';
import '../models/dashboard_rankings_response.dart';
import '../models/dashboard_response.dart';

import '../services/dashboard_service.dart';

import '../widgets/clientes_deuda_ranking.dart';
import '../widgets/flujo_bar_chart.dart';
import '../widgets/productos_ranking.dart';
import '../widgets/ventas_line_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _dashboardService = DashboardService();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  DashboardResponse? _dashboard;

  List<VentaPorDia> _ventasPorDia = [];
  List<FlujoNetoPorMes> _flujoMensual = [];

  List<ProductoMasVendido> _productosMasVendidos = [];
  List<ClienteMayorDeuda> _clientesMayorDeuda = [];

  bool _cargando = true;
  String? _error;

  late DateTime _desde;
  late DateTime _hasta;

  @override
  void initState() {
    super.initState();

    final ahora = DateTime.now();

    _desde = DateTime(ahora.year, ahora.month, 1);

    _hasta = DateTime(ahora.year, ahora.month, ahora.day);

    _cargarInformacion();
  }

  String _formatearMoneda(num valor) {
    if (valor < 0) {
      return '-S/ ${_numero.format(valor.abs())}';
    }

    return 'S/ ${_numero.format(valor)}';
  }

  Future<void> _cargarInformacion() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final resultados = await Future.wait([
        _dashboardService.obtenerDashboard(desde: _desde, hasta: _hasta),
        _dashboardService.obtenerVentasPorDia(desde: _desde, hasta: _hasta),
        _dashboardService.obtenerFlujoNetoPorMes(desde: _desde, hasta: _hasta),
        _dashboardService.obtenerProductosMasVendidos(
          desde: _desde,
          hasta: _hasta,
          limite: 5,
        ),
        _dashboardService.obtenerClientesMayorDeuda(limite: 5),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = resultados[0] as DashboardResponse;

        _ventasPorDia = resultados[1] as List<VentaPorDia>;

        _flujoMensual = resultados[2] as List<FlujoNetoPorMes>;

        _productosMasVendidos = resultados[3] as List<ProductoMasVendido>;

        _clientesMayorDeuda = resultados[4] as List<ClienteMayorDeuda>;

        _cargando = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');

        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _dashboard == null) {
      return _buildError();
    }

    return Stack(
      children: [
        ResponsivePage(
          child: SingleChildScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _buildDashboard(constraints.maxWidth);
              },
            ),
          ),
        ),

        if (_cargando)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x33FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFDC2626)),

            const SizedBox(height: 16),

            Text(_error!, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _cargarInformacion,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(double ancho) {
    final dashboard = _dashboard!;

    final pequena = ancho < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCabecera(pequena),

        SizedBox(height: pequena ? 20 : 28),

        _buildKpis(dashboard),

        const SizedBox(height: 24),

        _buildGraficos(),

        const SizedBox(height: 24),

        _buildRankings(),

        const SizedBox(height: 24),

        Text(
          'Finanzas y operaciones',
          style: TextStyle(
            fontSize: pequena ? 17 : 19,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 16),

        _buildFinanzas(dashboard),

        const SizedBox(height: 24),

        _buildResumenPeriodo(dashboard),

        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildCabecera(bool pequena) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen general',
          style: TextStyle(
            fontSize: pequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Resumen general del sistema Bencol.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );

    final periodo = _PeriodoChip(desde: _desde, hasta: _hasta);

    if (pequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titulo, const SizedBox(height: 14), periodo],
      );
    }

    return Row(
      children: [
        Expanded(child: titulo),

        const SizedBox(width: 18),

        periodo,
      ],
    );
  }

  Widget _buildKpis(DashboardResponse dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        final int columnas;

        if (ancho >= 1050) {
          columnas = 4;
        } else if (ancho >= 580) {
          columnas = 2;
        } else {
          columnas = 1;
        }

        final ratio = columnas == 1
            ? 3.3
            : columnas == 2
            ? 2.6
            : 2.15;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columnas,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ratio,
          children: [
            _InfoCard(
              titulo: 'Ventas del periodo',
              valor: _formatearMoneda(dashboard.ventas.totalVendido),
              subtitulo: '${dashboard.ventas.cantidadVentas} ventas',
              icono: Icons.point_of_sale_outlined,
            ),

            _InfoCard(
              titulo: 'Cobrado',
              valor: _formatearMoneda(dashboard.finanzas.totalCobrado),
              subtitulo: 'Ingresos registrados',
              icono: Icons.payments_outlined,
            ),

            _InfoCard(
              titulo: 'Por cobrar',
              valor: _formatearMoneda(dashboard.finanzas.totalPorCobrar),
              subtitulo: 'Deuda de clientes',
              icono: Icons.receipt_long_outlined,
            ),

            _InfoCard(
              titulo: 'Inventario',
              valor: '${dashboard.inventario.cantidadProductosInventario}',
              subtitulo:
                  '${dashboard.inventario.productosStockBajo} con stock bajo',
              icono: Icons.inventory_2_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGraficos() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 1000;

        final pequeno = constraints.maxWidth < 650;

        final altura = pequeno ? 330.0 : 370.0;

        final ventas = _ChartCard(
          altura: altura,
          titulo: 'Ventas por día',
          subtitulo: 'Comportamiento de las ventas del periodo',
          child: VentasLineChart(ventas: _ventasPorDia),
        );

        final flujo = _ChartCard(
          altura: altura,
          titulo: 'Ingresos vs egresos',
          subtitulo: 'Flujo mensual de caja',
          leyenda: const [
            _LegendItem(texto: 'Ingresos', color: Color(0xFF2563EB)),
            _LegendItem(texto: 'Egresos', color: Color(0xFFF59E0B)),
          ],
          child: FlujoBarChart(datos: _flujoMensual),
        );

        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: ventas),

              const SizedBox(width: 18),

              Expanded(flex: 2, child: flujo),
            ],
          );
        }

        return Column(children: [ventas, const SizedBox(height: 18), flujo]);
      },
    );
  }

  Widget _buildRankings() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 950;

        final pequeno = constraints.maxWidth < 600;

        final altura = pequeno ? 400.0 : 380.0;

        final productos = _RankingCard(
          altura: altura,
          titulo: 'Productos más vendidos',
          subtitulo: 'Top 5 del periodo seleccionado',
          icono: Icons.emoji_events_outlined,
          child: ProductosRanking(productos: _productosMasVendidos),
        );

        final clientes = _RankingCard(
          altura: altura,
          titulo: 'Clientes con mayor deuda',
          subtitulo: 'Top 5 con mayor deuda',
          icono: Icons.warning_amber_rounded,
          child: ClientesDeudaRanking(clientes: _clientesMayorDeuda),
        );

        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: productos),

              const SizedBox(width: 18),

              Expanded(child: clientes),
            ],
          );
        }

        return Column(
          children: [productos, const SizedBox(height: 18), clientes],
        );
      },
    );
  }

  Widget _buildFinanzas(DashboardResponse dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        final int columnas;

        if (ancho >= 1050) {
          columnas = 4;
        } else if (ancho >= 580) {
          columnas = 2;
        } else {
          columnas = 1;
        }

        final ratio = columnas == 1
            ? 3.3
            : columnas == 2
            ? 2.6
            : 2.15;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columnas,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ratio,
          children: [
            _InfoCard(
              titulo: 'Compras',
              valor: _formatearMoneda(dashboard.compras.totalComprado),
              subtitulo: '${dashboard.compras.cantidadCompras} compras',
              icono: Icons.shopping_cart_outlined,
            ),

            _InfoCard(
              titulo: 'Por pagar',
              valor: _formatearMoneda(dashboard.finanzas.totalPorPagar),
              subtitulo: 'Deuda a proveedores',
              icono: Icons.account_balance_outlined,
            ),

            _InfoCard(
              titulo: 'Pagado a proveedores',
              valor: _formatearMoneda(
                dashboard.finanzas.totalPagadoProveedores,
              ),
              subtitulo: 'Pagos del periodo',
              icono: Icons.outbox_outlined,
            ),

            _InfoCard(
              titulo: 'Caja actual',
              valor: dashboard.caja.saldoActual != null
                  ? _formatearMoneda(dashboard.caja.saldoActual!)
                  : 'Sin caja abierta',
              subtitulo: dashboard.caja.estado ?? 'CERRADA',
              icono: Icons.account_balance_wallet_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResumenPeriodo(DashboardResponse dashboard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 850;

        final cards = [
          _ResumenPeriodoCard(
            titulo: 'Ingresos del periodo',
            valor: _formatearMoneda(dashboard.caja.ingresosPeriodo),
            icono: Icons.trending_up,
          ),
          _ResumenPeriodoCard(
            titulo: 'Egresos del periodo',
            valor: _formatearMoneda(dashboard.caja.egresosPeriodo),
            icono: Icons.trending_down,
          ),
          _ResumenPeriodoCard(
            titulo: 'Flujo neto',
            valor: _formatearMoneda(
              dashboard.caja.ingresosPeriodo - dashboard.caja.egresosPeriodo,
            ),
            icono: Icons.show_chart,
          ),
        ];

        if (horizontal) {
          return Row(
            children: [
              Expanded(child: cards[0]),

              const SizedBox(width: 18),

              Expanded(child: cards[1]),

              const SizedBox(width: 18),

              Expanded(child: cards[2]),
            ],
          );
        }

        return Column(
          children: [
            cards[0],

            const SizedBox(height: 12),

            cards[1],

            const SizedBox(height: 12),

            cards[2],
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icono;

  const _InfoCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 260;

        return Container(
          padding: EdgeInsets.all(compacto ? 14 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          child: Row(
            children: [
              Container(
                width: compacto ? 40 : 46,
                height: compacto ? 40 : 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icono,
                  size: compacto ? 20 : 23,
                  color: const Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: compacto ? 11 : 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      valor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: compacto ? 15 : 18,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResumenPeriodoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _ResumenPeriodoCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: const Color(0xFF2563EB)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget child;
  final List<Widget> leyenda;
  final double altura;

  const _ChartCard({
    required this.titulo,
    required this.subtitulo,
    required this.child,
    required this.altura,
    this.leyenda = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pequena = constraints.maxWidth < 500;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: pequena ? 15 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),

              if (leyenda.isNotEmpty) ...[
                const SizedBox(height: 10),

                Wrap(spacing: 14, runSpacing: 6, children: leyenda),
              ],

              const SizedBox(height: 18),

              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Widget child;
  final double altura;

  const _RankingCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.child,
    required this.altura,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altura,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, size: 20, color: const Color(0xFF2563EB)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Expanded(child: child),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String texto;
  final Color color;

  const _LegendItem({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 6),

        Text(
          texto,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _PeriodoChip extends StatelessWidget {
  final DateTime desde;
  final DateTime hasta;

  const _PeriodoChip({required this.desde, required this.hasta});

  @override
  Widget build(BuildContext context) {
    final formato = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 17,
            color: Color(0xFF64748B),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              '${formato.format(desde)} - ${formato.format(hasta)}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

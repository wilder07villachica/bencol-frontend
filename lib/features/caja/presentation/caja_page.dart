import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/caja.dart';
import '../models/movimiento_caja.dart';
import '../models/pagina_movimientos_caja.dart';
import '../services/caja_service.dart';

import '../widgets/abrir_caja_dialog.dart';
import '../widgets/cerrar_caja_dialog.dart';
import '../widgets/movimiento_caja_dialog.dart';

class CajaPage extends StatefulWidget {
  const CajaPage({super.key});

  @override
  State<CajaPage> createState() => _CajaPageState();
}

class _CajaPageState extends State<CajaPage> {
  final _cajaService = CajaService();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  Caja? _cajaAbierta;
  PaginaMovimientosCaja? _movimientos;

  bool _cargando = true;
  String? _error;

  int _paginaMovimientos = 0;
  final int _tamanio = 20;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  String _moneda(num valor) {
    if (valor < 0) {
      return '-S/ ${_numero.format(valor.abs())}';
    }

    return 'S/ ${_numero.format(valor)}';
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final caja = await _cajaService.obtenerCajaAbierta();

      PaginaMovimientosCaja? movimientos;

      if (caja != null) {
        movimientos = await _cajaService.obtenerMovimientos(
          pagina: _paginaMovimientos,
          tamanio: _tamanio,
          cajaId: caja.id,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _cajaAbierta = caja;
        _movimientos = movimientos;
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

  Future<void> _abrirCaja() async {
    final caja = await showDialog<Caja>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AbrirCajaDialog();
      },
    );

    if (caja == null) {
      return;
    }

    _paginaMovimientos = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caja abierta correctamente.')),
    );
  }

  Future<void> _registrarMovimiento() async {
    final caja = _cajaAbierta;

    if (caja == null) {
      return;
    }

    final registrado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return MovimientoCajaDialog(caja: caja);
      },
    );

    if (registrado != true) {
      return;
    }

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movimiento registrado correctamente.')),
    );
  }

  Future<void> _cerrarCaja() async {
    final caja = _cajaAbierta;

    if (caja == null) {
      return;
    }

    final cajaCerrada = await showDialog<Caja>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CerrarCajaDialog(caja: caja);
      },
    );

    if (cajaCerrada == null) {
      return;
    }

    _paginaMovimientos = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caja cerrada correctamente.')),
    );
  }

  Future<void> _paginaAnterior() async {
    if (_movimientos == null || _movimientos!.primera) {
      return;
    }

    _paginaMovimientos--;

    await _cargar();
  }

  Future<void> _paginaSiguiente() async {
    if (_movimientos == null || _movimientos!.ultima) {
      return;
    }

    _paginaMovimientos++;

    await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _cajaAbierta == null && _movimientos == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _cajaAbierta == null && _movimientos == null) {
      return _buildError();
    }

    return Stack(
      children: [
        ResponsivePage(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (_cajaAbierta == null) {
                return _buildSinCaja();
              }

              return _buildCajaAbierta(constraints.maxWidth);
            },
          ),
        ),

        if (_cargando)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x22FFFFFF),
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

            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildSinCaja() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 600;

        return Center(
          child: Container(
            width: pequena ? double.infinity : 520,
            padding: EdgeInsets.all(pequena ? 24 : 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: pequena ? 58 : 68,
                  height: pequena ? 58 : 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: pequena ? 30 : 34,
                    color: const Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'No hay una caja abierta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: pequena ? 19 : 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Abre una caja para registrar cobros, pagos y egresos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: pequena ? double.infinity : 160,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: _abrirCaja,
                    icon: const Icon(Icons.lock_open_outlined),
                    label: const Text('Abrir caja'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCajaAbierta(double ancho) {
    final caja = _cajaAbierta!;

    final pequena = ancho < 700;
    final mediana = ancho < 1050;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCabeceraCaja(pequena: pequena, mediana: mediana),

        const SizedBox(height: 20),

        _buildResumenCaja(caja, pequena: pequena, mediana: mediana),

        const SizedBox(height: 18),

        _buildEstadoCaja(caja, pequena: pequena),

        const SizedBox(height: 18),

        const Text(
          'Movimientos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 12),

        Expanded(child: _buildMovimientos()),

        const SizedBox(height: 12),

        if (_movimientos != null) _buildPaginacion(pequena),
      ],
    );
  }

  Widget _buildCabeceraCaja({required bool pequena, required bool mediana}) {
    const titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Caja actual',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),

        SizedBox(height: 6),

        Text(
          'Control de efectivo y movimientos de la caja abierta.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );

    final nuevoMovimiento = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _registrarMovimiento,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo movimiento'),
    );

    final cerrar = OutlinedButton.icon(
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _cerrarCaja,
      icon: const Icon(Icons.lock_outline),
      label: const Text('Cerrar caja'),
    );

    if (pequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,

          const SizedBox(height: 16),

          SizedBox(width: double.infinity, child: nuevoMovimiento),

          const SizedBox(height: 10),

          SizedBox(width: double.infinity, child: cerrar),
        ],
      );
    }

    if (mediana) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: nuevoMovimiento),

              const SizedBox(width: 12),

              Expanded(child: cerrar),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(child: titulo),

        const SizedBox(width: 20),

        SizedBox(width: 190, child: nuevoMovimiento),

        const SizedBox(width: 12),

        SizedBox(width: 140, child: cerrar),
      ],
    );
  }

  Widget _buildResumenCaja(
    Caja caja, {
    required bool pequena,
    required bool mediana,
  }) {
    final cards = [
      _CajaCard(
        titulo: 'Saldo inicial',
        valor: _moneda(caja.saldoInicial),
        icono: Icons.start,
      ),
      _CajaCard(
        titulo: 'Ingresos',
        valor: _moneda(caja.totalIngresos),
        icono: Icons.trending_up,
      ),
      _CajaCard(
        titulo: 'Egresos',
        valor: _moneda(caja.totalEgresos),
        icono: Icons.trending_down,
      ),
      _CajaCard(
        titulo: 'Saldo actual',
        valor: _moneda(caja.saldoActual),
        icono: Icons.account_balance_wallet_outlined,
        destacado: true,
      ),
    ];

    if (pequena) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            SizedBox(width: double.infinity, child: cards[i]),
            if (i != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (mediana) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),

              const SizedBox(width: 12),

              Expanded(child: cards[1]),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: cards[2]),

              const SizedBox(width: 12),

              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),

        const SizedBox(width: 16),

        Expanded(child: cards[1]),

        const SizedBox(width: 16),

        Expanded(child: cards[2]),

        const SizedBox(width: 16),

        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildEstadoCaja(Caja caja, {required bool pequena}) {
    final apertura = caja.fechaApertura != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(caja.fechaApertura!)
        : '-';

    if (pequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EstadoCajaBadge(estado: caja.estado),

          const SizedBox(height: 8),

          Text(
            'Abierta por ${caja.abiertaPor ?? '-'}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 5),

          Text(apertura, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      );
    }

    return Row(
      children: [
        _EstadoCajaBadge(estado: caja.estado),

        const SizedBox(width: 12),

        Text(
          'Abierta por ${caja.abiertaPor ?? '-'}',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        Text(apertura, style: const TextStyle(color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildMovimientos() {
    final movimientos = _movimientos?.contenido ?? const <MovimientoCaja>[];

    if (movimientos.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'Esta caja todavía no tiene movimientos.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final fecha = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final reducida = constraints.maxWidth < 800;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columnSpacing: reducida ? 20 : 28,
                  columns: reducida
                      ? const [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Concepto')),
                          DataColumn(label: Text('Monto')),
                        ]
                      : const [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Tipo')),
                          DataColumn(label: Text('Concepto')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Referencia')),
                          DataColumn(label: Text('Usuario')),
                        ],
                  rows: movimientos.map((movimiento) {
                    if (reducida) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              movimiento.fechaMovimiento != null
                                  ? fecha.format(movimiento.fechaMovimiento!)
                                  : '-',
                            ),
                          ),

                          DataCell(
                            _MovimientoCajaBadge(
                              tipo: movimiento.tipoMovimiento,
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                movimiento.concepto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              _moneda(movimiento.monto),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            movimiento.fechaMovimiento != null
                                ? fecha.format(movimiento.fechaMovimiento!)
                                : '-',
                          ),
                        ),

                        DataCell(
                          _MovimientoCajaBadge(tipo: movimiento.tipoMovimiento),
                        ),

                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Text(
                              movimiento.concepto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            _moneda(movimiento.monto),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        DataCell(Text(movimiento.referencia ?? '-')),

                        DataCell(Text(movimiento.registradoPor ?? '-')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaginacion(bool pequena) {
    final pagina = _movimientos!;

    final controles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          onPressed: pagina.primera ? null : _paginaAnterior,
          icon: const Icon(Icons.chevron_left),
        ),

        Text(
          'Página ${pagina.pagina + 1} de '
          '${pagina.totalPaginas == 0 ? 1 : pagina.totalPaginas}',
          style: const TextStyle(fontSize: 12),
        ),

        IconButton(
          tooltip: 'Página siguiente',
          onPressed: pagina.ultima ? null : _paginaSiguiente,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );

    if (pequena) {
      return Column(
        children: [
          Text(
            '${pagina.totalElementos} movimientos',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 4),

          controles,
        ],
      );
    }

    return Row(
      children: [
        Text(
          '${pagina.totalElementos} movimientos',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _CajaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final bool destacado;

  const _CajaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destacado ? const Color(0xFFBFDBFE) : const Color(0xFFE7EAF0),
        ),
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

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: destacado ? const Color(0xFF2563EB) : null,
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

class _EstadoCajaBadge extends StatelessWidget {
  final String estado;

  const _EstadoCajaBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final abierta = estado == 'ABIERTA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: abierta ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: abierta ? const Color(0xFF15803D) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _MovimientoCajaBadge extends StatelessWidget {
  final String tipo;

  const _MovimientoCajaBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final ingreso = tipo == 'INGRESO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: ingreso ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ingreso ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cuenta_envases.dart';
import '../models/movimiento_envase.dart';
import '../services/envase_service.dart';

class MovimientosEnvaseDialog extends StatefulWidget {
  final CuentaEnvases cuenta;

  const MovimientosEnvaseDialog({super.key, required this.cuenta});

  @override
  State<MovimientosEnvaseDialog> createState() =>
      _MovimientosEnvaseDialogState();
}

class _MovimientosEnvaseDialogState extends State<MovimientosEnvaseDialog> {
  final _envaseService = EnvaseService();

  List<MovimientoEnvase> _movimientos = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final movimientos = await _envaseService.obtenerMovimientosPorCuenta(
        widget.cuenta.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pantallaPequena = size.width < 700;

    final dialogWidth = size.width < 1050 ? size.width * 0.94 : 980.0;

    final dialogHeight = size.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pantallaPequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(pantallaPequena ? 14 : 18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(pantallaPequena),

              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildError()
                    : _buildTabla(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Color(0xFFDC2626)),

            const SizedBox(height: 12),

            Text(_error!, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _cargar();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool pantallaPequena) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: pantallaPequena ? 16 : 24,
        vertical: pantallaPequena ? 14 : 20,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        children: [
          Container(
            width: pantallaPequena ? 38 : 42,
            height: pantallaPequena ? 38 : 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.history, color: Color(0xFF2563EB)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial de envases',
                  style: TextStyle(
                    fontSize: pantallaPequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${widget.cuenta.nombreCliente} - '
                  '${widget.cuenta.descripcionProducto}',
                  maxLines: pantallaPequena ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Cerrar',
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabla() {
    if (_movimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Esta cuenta no tiene movimientos registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE7EAF0)),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tablaReducida = constraints.maxWidth < 700;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    horizontalMargin: 16,
                    columnSpacing: tablaReducida ? 22 : 32,
                    columns: tablaReducida
                        ? const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Cantidad')),
                            DataColumn(label: Text('Referencia')),
                          ]
                        : const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Cantidad')),
                            DataColumn(label: Text('Referencia')),
                            DataColumn(label: Text('Usuario')),
                          ],
                    rows: _movimientos.map((movimiento) {
                      if (tablaReducida) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                movimiento.fechaMovimiento != null
                                    ? DateFormat(
                                        'dd/MM/yy',
                                      ).format(movimiento.fechaMovimiento!)
                                    : '-',
                              ),
                            ),

                            DataCell(
                              _TipoMovimientoBadge(
                                tipo: movimiento.tipoMovimiento,
                              ),
                            ),

                            DataCell(Text(movimiento.cantidad.toString())),

                            DataCell(
                              SizedBox(
                                width: 180,
                                child: Text(
                                  movimiento.referencia ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  ? formatoFecha.format(
                                      movimiento.fechaMovimiento!,
                                    )
                                  : '-',
                            ),
                          ),

                          DataCell(
                            _TipoMovimientoBadge(
                              tipo: movimiento.tipoMovimiento,
                            ),
                          ),

                          DataCell(Text(movimiento.cantidad.toString())),

                          DataCell(
                            SizedBox(
                              width: 250,
                              child: Text(
                                movimiento.referencia ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

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
      ),
    );
  }
}

class _TipoMovimientoBadge extends StatelessWidget {
  final String tipo;

  const _TipoMovimientoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color color;

    switch (tipo) {
      case 'PRESTAMO':
        fondo = const Color(0xFFFFF7ED);
        color = const Color(0xFFEA580C);
        break;

      case 'DEVOLUCION':
        fondo = const Color(0xFFDCFCE7);
        color = const Color(0xFF15803D);
        break;

      case 'COMPRA':
      case 'CONVERSION_COMPRA':
        fondo = const Color(0xFFEFF6FF);
        color = const Color(0xFF2563EB);
        break;

      case 'INTERCAMBIO':
        fondo = const Color(0xFFF1F5F9);
        color = const Color(0xFF475569);
        break;

      default:
        fondo = const Color(0xFFF1F5F9);
        color = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

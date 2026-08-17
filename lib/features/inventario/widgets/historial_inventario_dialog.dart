import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/inventario.dart';
import '../models/movimiento_inventario.dart';
import '../services/inventario_service.dart';

class HistorialInventarioDialog extends StatefulWidget {
  final Inventario inventario;

  const HistorialInventarioDialog({super.key, required this.inventario});

  @override
  State<HistorialInventarioDialog> createState() =>
      _HistorialInventarioDialogState();
}

class _HistorialInventarioDialogState extends State<HistorialInventarioDialog> {
  final _inventarioService = InventarioService();

  final ScrollController _scrollHorizontal = ScrollController();

  final ScrollController _scrollVertical = ScrollController();

  List<MovimientoInventario> _movimientos = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  @override
  void dispose() {
    _scrollHorizontal.dispose();
    _scrollVertical.dispose();

    super.dispose();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final movimientos = await _inventarioService
          .obtenerMovimientosPorProducto(widget.inventario.productoId);

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
    final size = MediaQuery.sizeOf(context);

    final horizontal = size.width < 700 ? 10.0 : 24.0;

    final width = size.width < 1000 ? size.width - (horizontal * 2) : 950.0;

    final maxHeight = size.height < 760 ? size.height * 0.92 : 720.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width, maxHeight: maxHeight),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildError()
                    : _buildContenido(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 550;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pequena ? 14 : 24,
            vertical: pequena ? 14 : 20,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
          ),
          child: Row(
            children: [
              Container(
                width: pequena ? 36 : 42,
                height: pequena ? 36 : 42,
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
                      'Historial de inventario',
                      style: TextStyle(
                        fontSize: pequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      widget.inventario.descripcionProducto,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
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
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );
      },
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

            const SizedBox(height: 18),

            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_movimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este producto no tiene movimientos registrados.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return _buildListaCompacta();
        }

        return _buildTabla();
      },
    );
  }

  Widget _buildTabla() {
    final fecha = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _scrollHorizontal,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _scrollHorizontal,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  controller: _scrollVertical,
                  primary: false,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Tipo')),
                      DataColumn(label: Text('Cantidad')),
                      DataColumn(label: Text('Anterior')),
                      DataColumn(label: Text('Nuevo')),
                      DataColumn(label: Text('Referencia')),
                      DataColumn(label: Text('Usuario')),
                    ],
                    rows: _movimientos.map((movimiento) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              movimiento.fechaCreacion != null
                                  ? fecha.format(movimiento.fechaCreacion!)
                                  : '-',
                            ),
                          ),

                          DataCell(
                            _MovimientoBadge(tipo: movimiento.tipoMovimiento),
                          ),

                          DataCell(Text(movimiento.cantidad.toString())),

                          DataCell(Text(movimiento.stockAnterior.toString())),

                          DataCell(Text(movimiento.stockNuevo.toString())),

                          DataCell(
                            SizedBox(
                              width: 210,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildListaCompacta() {
    final fecha = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.separated(
      primary: false,
      padding: const EdgeInsets.all(14),
      itemCount: _movimientos.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final movimiento = _movimientos[index];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MovimientoBadge(tipo: movimiento.tipoMovimiento),

                  const Spacer(),

                  Text(
                    movimiento.fechaCreacion != null
                        ? fecha.format(movimiento.fechaCreacion!)
                        : '-',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _DatoMovimiento(
                      titulo: 'Cantidad',
                      valor: movimiento.cantidad.toString(),
                    ),
                  ),

                  Expanded(
                    child: _DatoMovimiento(
                      titulo: 'Stock anterior',
                      valor: movimiento.stockAnterior.toString(),
                    ),
                  ),

                  Expanded(
                    child: _DatoMovimiento(
                      titulo: 'Stock nuevo',
                      valor: movimiento.stockNuevo.toString(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                movimiento.referencia ?? 'Sin referencia',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),

              const SizedBox(height: 6),

              Text(
                'Usuario: ${movimiento.registradoPor ?? '-'}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DatoMovimiento extends StatelessWidget {
  final String titulo;
  final String valor;

  const _DatoMovimiento({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
        ),

        const SizedBox(height: 3),

        Text(valor, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MovimientoBadge extends StatelessWidget {
  final String tipo;

  const _MovimientoBadge({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final entrada = tipo == 'ENTRADA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: entrada ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: entrada ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}

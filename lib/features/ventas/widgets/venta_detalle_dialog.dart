import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_form_grid.dart';

import '../models/venta.dart';

class VentaDetalleDialog extends StatelessWidget {
  final Venta venta;

  VentaDetalleDialog({super.key, required this.venta});

  final NumberFormat _numero = NumberFormat('#,##0.00', 'en_US');

  String _moneda(num valor) {
    if (valor < 0) {
      return '-S/ ${_numero.format(valor.abs())}';
    }

    return 'S/ ${_numero.format(valor)}';
  }

  String _fecha(DateTime? fecha) {
    if (fecha == null) {
      return '-';
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  String _textoEnum(String? valor) {
    if (valor == null || valor.isEmpty) {
      return '-';
    }

    final texto = valor.replaceAll('_', ' ').toLowerCase();

    return texto
        .split(' ')
        .map((palabra) {
          if (palabra.isEmpty) {
            return palabra;
          }

          return '${palabra[0].toUpperCase()}'
              '${palabra.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final double margin;

    if (size.width < 650) {
      margin = 10;
    } else if (size.width < 1000) {
      margin = 18;
    } else {
      margin = 28;
    }

    final double dialogWidth = size.width < 1100
        ? size.width - (margin * 2)
        : 1050;

    final double dialogHeight = size.height < 820 ? size.height * 0.92 : 760;

    final double contentPadding = size.width < 650
        ? 14
        : size.width < 1000
        ? 18
        : 24;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: margin, vertical: 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInformacionGeneral(),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Productos',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF172033),
                              ),
                            ),
                          ),

                          Text(
                            '${venta.detalles.length} producto'
                            '${venta.detalles.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _buildTablaProductos(),

                      const SizedBox(height: 22),

                      _buildResumen(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pequena ? 14 : 24,
            vertical: pequena ? 12 : 18,
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
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: const Color(0xFF2563EB),
                  size: pequena ? 19 : 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detalle de venta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: pequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      venta.codigo,
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

  Widget _buildInformacionGeneral() {
    final datos = <Widget>[
      _DatoVenta(titulo: 'Código', valor: venta.codigo),

      _DatoVenta(titulo: 'Cliente', valor: venta.nombreCliente),

      _DatoVenta(titulo: 'Estado', valor: _textoEnum(venta.estado)),

      _DatoVenta(titulo: 'Fecha', valor: _fecha(venta.fechaCreacion)),

      _DatoVenta(titulo: 'Creado por', valor: venta.creadoPor ?? '-'),
    ];

    if (venta.actualizadoPor != null && venta.actualizadoPor!.isNotEmpty) {
      datos.add(
        _DatoVenta(titulo: 'Actualizado por', valor: venta.actualizadoPor!),
      );
    }

    if (venta.fechaActualizacion != null) {
      datos.add(
        _DatoVenta(
          titulo: 'Fecha actualización',
          valor: _fecha(venta.fechaActualizacion),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información general',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),

        ResponsiveFormGrid(
          largeColumns: 4,
          mediumColumns: 2,
          smallColumns: 1,
          spacing: 10,
          runSpacing: 10,
          children: datos,
        ),
      ],
    );
  }

  Widget _buildTablaProductos() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                columnSpacing: 24,
                horizontalMargin: 18,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 68,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Producto',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Cantidad',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Precio',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Subtotal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Modalidad',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Envases devueltos',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                rows: venta.detalles.map((detalle) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 210,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detalle.descripcionProducto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF172033),
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                detalle.codigoProducto,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      DataCell(Text(detalle.cantidad.toString())),

                      DataCell(Text(_moneda(detalle.precioUnitario))),

                      DataCell(
                        Text(
                          _moneda(detalle.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      DataCell(Text(_textoEnum(detalle.modalidadEnvase))),

                      DataCell(
                        Text(detalle.envasesDevueltos?.toString() ?? '-'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResumen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 600;

        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: pequena ? constraints.maxWidth : 310,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Subtotal',
                          style: TextStyle(color: Color(0xFF475569)),
                        ),
                      ),

                      Text(
                        _moneda(venta.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Divider(height: 1, color: Color(0xFFDDE3EA)),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ),

                      Text(
                        _moneda(venta.total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatoVenta extends StatelessWidget {
  final String titulo;
  final String valor;

  const _DatoVenta({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),

          const SizedBox(height: 4),

          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172033),
            ),
          ),
        ],
      ),
    );
  }
}

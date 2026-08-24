import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_form_grid.dart';

import '../models/cotizacion.dart';

class CotizacionDetalleDialog extends StatelessWidget {
  final Cotizacion cotizacion;

  const CotizacionDetalleDialog({super.key, required this.cotizacion});

  String _moneda(num valor) {
    final numero = NumberFormat('#,##0.00', 'en_US');

    return 'S/ ${numero.format(valor)}';
  }

  String _fecha(DateTime? fecha) {
    if (fecha == null) {
      return '-';
    }

    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final double horizontalMargin;

    if (size.width < 650) {
      horizontalMargin = 10;
    } else if (size.width < 1000) {
      horizontalMargin = 18;
    } else {
      horizontalMargin = 24;
    }

    final double dialogWidth;

    if (size.width < 650) {
      dialogWidth = size.width - (horizontalMargin * 2);
    } else if (size.width < 1000) {
      dialogWidth = size.width * 0.90;
    } else {
      dialogWidth = 880;
    }

    final double maxDialogHeight;

    if (size.height < 700) {
      maxDialogHeight = size.height * 0.94;
    } else if (size.height < 850) {
      maxDialogHeight = size.height * 0.90;
    } else {
      maxDialogHeight = 620;
    }

    final double contentPadding;

    if (size.width < 650) {
      contentPadding = 12;
    } else if (size.width < 1000) {
      contentPadding = 16;
    } else {
      contentPadding = 20;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: 14,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCabecera(context),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding,
                    16,
                    contentPadding,
                    20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatosGenerales(),

                      const SizedBox(height: 18),

                      _buildProductos(),

                      const SizedBox(height: 18),

                      _buildCondiciones(),

                      const SizedBox(height: 18),

                      _buildTotales(),
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

  Widget _buildCabecera(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pequena ? 14 : 18,
            vertical: pequena ? 10 : 12,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
          ),
          child: Row(
            children: [
              Container(
                width: pequena ? 34 : 38,
                height: pequena ? 34 : 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.request_quote_outlined,
                  color: const Color(0xFF2563EB),
                  size: pequena ? 18 : 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cotizacion.codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: pequena ? 15 : 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      cotizacion.nombreCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _EstadoCotizacionBadge(estado: cotizacion.estado),

              const SizedBox(width: 4),

              IconButton(
                tooltip: 'Cerrar',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDatosGenerales() {
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
          children: [
            _DatoCotizacion(
              titulo: 'Cliente',
              valor: cotizacion.nombreCliente,
              icono: Icons.person_outline,
            ),

            _DatoCotizacion(
              titulo: 'Empresa emisora',
              valor:
                  cotizacion.nombreComercialEmpresa ??
                  cotizacion.razonSocialEmpresa,
              icono: Icons.business_outlined,
            ),

            _DatoCotizacion(
              titulo: 'Fecha de creación',
              valor: _fecha(cotizacion.fechaCreacion),
              icono: Icons.calendar_today_outlined,
            ),

            _DatoCotizacion(
              titulo: 'Vencimiento',
              valor: _fecha(cotizacion.fechaVencimiento),
              icono: Icons.event_outlined,
            ),

            _DatoCotizacion(
              titulo: 'Tipo de precio',
              valor: cotizacion.tipoPrecio == 'CON_IGV'
                  ? 'Incluye IGV'
                  : 'Precio + IGV',
              icono: Icons.percent,
            ),

            _DatoCotizacion(
              titulo: 'Creado por',
              valor: cotizacion.creadoPor ?? '-',
              icono: Icons.badge_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos cotizados',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 9),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7EAF0)),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final pequeno = constraints.maxWidth < 700;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: pequeno ? 12 : 14,
                    horizontalMargin: pequeno ? 10 : 12,
                    headingRowHeight: 42,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 60,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(
                        label: SizedBox(width: 170, child: Text('Producto')),
                      ),
                      DataColumn(
                        label: SizedBox(width: 65, child: Text('Contenido')),
                      ),
                      DataColumn(
                        label: SizedBox(width: 58, child: Text('Cantidad')),
                      ),
                      DataColumn(
                        label: SizedBox(width: 78, child: Text('Frecuencia')),
                      ),
                      DataColumn(
                        label: SizedBox(width: 76, child: Text('P. unitario')),
                      ),
                      DataColumn(
                        label: SizedBox(width: 84, child: Text('Importe')),
                      ),
                      DataColumn(
                        label: SizedBox(width: 68, child: Text('Imagen')),
                      ),
                    ],
                    rows: cotizacion.detalles.map((detalle) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 170,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detalle.descripcionProducto,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  if (detalle.descripcionAdicional != null &&
                                      detalle.descripcionAdicional!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        detalle.descripcionAdicional!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              '${_formatearContenido(detalle.contenidoProducto)} '
                              '${_formatearUnidad(detalle.unidadMedidaProducto)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),

                          DataCell(
                            Text(
                              detalle.cantidad.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              detalle.frecuenciaAbastecimiento ?? '-',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),

                          DataCell(
                            Text(
                              _moneda(detalle.precioUnitario),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),

                          DataCell(
                            Text(
                              _moneda(detalle.subtotal),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          DataCell(
                            _ImagenBadge(tieneImagen: detalle.tieneImagen),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCondiciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Condiciones comerciales',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 10),

        ResponsiveFormGrid(
          largeColumns: 3,
          mediumColumns: 2,
          smallColumns: 1,
          spacing: 10,
          runSpacing: 10,
          children: [
            _SeccionTexto(
              titulo: 'Condiciones de pago',
              valor: cotizacion.condicionesPago ?? '-',
              icono: Icons.payments_outlined,
            ),

            _SeccionTexto(
              titulo: 'Entrega',
              valor: cotizacion.plazoEntrega ?? '-',
              icono: Icons.local_shipping_outlined,
            ),

            _SeccionTexto(
              titulo: 'Observaciones',
              valor: cotizacion.observacion ?? '-',
              icono: Icons.notes_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotales() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequeno = constraints.maxWidth < 600;

        final anchoTotal = pequeno ? constraints.maxWidth : 310.0;

        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: anchoTotal,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE7EAF0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FilaTotal(
                    titulo: cotizacion.tipoPrecio == 'CON_IGV'
                        ? 'Valor de venta'
                        : 'Subtotal',
                    valor: _moneda(cotizacion.subtotal),
                  ),

                  _FilaTotal(
                    titulo: cotizacion.tipoPrecio == 'CON_IGV'
                        ? 'IGV incluido '
                              '${cotizacion.porcentajeImpuesto.toStringAsFixed(2)}%'
                        : 'IGV '
                              '${cotizacion.porcentajeImpuesto.toStringAsFixed(2)}%',
                    valor: _moneda(cotizacion.montoImpuesto),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: const Color(0xFFEFF6FF),
                    child: Row(
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),

                        const Spacer(),

                        Text(
                          _moneda(cotizacion.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatearUnidad(String unidad) {
    switch (unidad) {
      case 'MILILITRO':
        return 'ml';

      case 'LITRO':
        return 'L';

      default:
        return unidad;
    }
  }

  String _formatearContenido(double contenido) {
    if (contenido == contenido.roundToDouble()) {
      return contenido.toInt().toString();
    }

    return contenido.toString();
  }
}

class _DatoCotizacion extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _DatoCotizacion({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 17, color: const Color(0xFF64748B)),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 2),

                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _SeccionTexto extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _SeccionTexto({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 15, color: const Color(0xFF64748B)),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Expanded(
            child: Text(
              valor,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF475569),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaTotal extends StatelessWidget {
  final String titulo;
  final String valor;

  const _FilaTotal({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            valor,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ImagenBadge extends StatelessWidget {
  final bool tieneImagen;

  const _ImagenBadge({required this.tieneImagen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: tieneImagen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tieneImagen ? 'CARGADA' : 'SIN IMAGEN',
        style: TextStyle(
          fontSize: 7,
          fontWeight: FontWeight.w600,
          color: tieneImagen
              ? const Color(0xFF15803D)
              : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _EstadoCotizacionBadge extends StatelessWidget {
  final String estado;

  const _EstadoCotizacionBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color color;

    switch (estado) {
      case 'BORRADOR':
        fondo = const Color(0xFFF1F5F9);
        color = const Color(0xFF475569);
        break;

      case 'EMITIDA':
        fondo = const Color(0xFFDCFCE7);
        color = const Color(0xFF15803D);
        break;

      case 'ANULADA':
        fondo = const Color(0xFFFEE2E2);
        color = const Color(0xFFB91C1C);
        break;

      default:
        fondo = const Color(0xFFF1F5F9);
        color = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

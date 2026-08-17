import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cuenta_pagar.dart';

class DetalleCuentaPagarDialog extends StatelessWidget {
  final CuentaPagar cuenta;

  const DetalleCuentaPagarDialog({super.key, required this.cuenta});

  String _moneda(double valor) {
    final numero = NumberFormat('#,##0.00', 'en_US');

    return 'S/ ${numero.format(valor)}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pantallaPequena = size.width < 650;

    final dialogWidth = size.width < 950 ? size.width * 0.94 : 900.0;

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
              _buildHeader(context, pantallaPequena),

              Padding(
                padding: EdgeInsets.all(pantallaPequena ? 16 : 24),
                child: _buildResumen(pantallaPequena),
              ),

              const Divider(height: 1),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  pantallaPequena ? 16 : 24,
                  18,
                  pantallaPequena ? 16 : 24,
                  10,
                ),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Historial de pagos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              Expanded(child: _buildPagos()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool pantallaPequena) {
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
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: Color(0xFFEA580C),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle de cuenta por pagar',
                  style: TextStyle(
                    fontSize: pantallaPequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${cuenta.razonSocialProveedor} • '
                  '${cuenta.codigoCompra}',
                  maxLines: 2,
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

  Widget _buildResumen(bool pantallaPequena) {
    final cards = [
      _DatoProveedor(titulo: 'Total', valor: _moneda(cuenta.montoTotal)),
      _DatoProveedor(titulo: 'Pagado', valor: _moneda(cuenta.montoPagado)),
      _DatoProveedor(
        titulo: 'Pendiente',
        valor: _moneda(cuenta.saldoPendiente),
        destacado: true,
      ),
    ];

    if (pantallaPequena) {
      return Column(
        children: [
          cards[0],

          const SizedBox(height: 10),

          cards[1],

          const SizedBox(height: 10),

          cards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),

        const SizedBox(width: 12),

        Expanded(child: cards[1]),

        const SizedBox(width: 12),

        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildPagos() {
    if (cuenta.pagos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Esta cuenta todavía no tiene pagos registrados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final fecha = DateFormat('dd/MM/yyyy HH:mm');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE7EAF0)),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final reducida = constraints.maxWidth < 700;

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
                    columnSpacing: reducida ? 22 : 30,
                    columns: reducida
                        ? const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Monto')),
                            DataColumn(label: Text('Método')),
                            DataColumn(label: Text('Referencia')),
                          ]
                        : const [
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Monto')),
                            DataColumn(label: Text('Método')),
                            DataColumn(label: Text('Referencia')),
                            DataColumn(label: Text('Usuario')),
                          ],
                    rows: cuenta.pagos.map((pago) {
                      final cells = <DataCell>[
                        DataCell(
                          Text(
                            pago.fechaPago != null
                                ? fecha.format(pago.fechaPago!)
                                : '-',
                          ),
                        ),

                        DataCell(
                          Text(
                            _moneda(pago.monto),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        DataCell(Text(pago.metodoPago)),

                        DataCell(
                          SizedBox(
                            width: reducida ? 150 : 220,
                            child: Text(
                              pago.referencia ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ];

                      if (!reducida) {
                        cells.add(DataCell(Text(pago.registradoPor ?? '-')));
                      }

                      return DataRow(cells: cells);
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

class _DatoProveedor extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool destacado;

  const _DatoProveedor({
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: destacado ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 5),

          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: destacado ? const Color(0xFFEA580C) : null,
            ),
          ),
        ],
      ),
    );
  }
}

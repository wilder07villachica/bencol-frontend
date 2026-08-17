import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cuenta_pagar.dart';
import '../models/pago_proveedor_request.dart';
import '../services/cuenta_pagar_service.dart';

class RegistrarPagoProveedorDialog extends StatefulWidget {
  final CuentaPagar cuenta;

  const RegistrarPagoProveedorDialog({super.key, required this.cuenta});

  @override
  State<RegistrarPagoProveedorDialog> createState() =>
      _RegistrarPagoProveedorDialogState();
}

class _RegistrarPagoProveedorDialogState
    extends State<RegistrarPagoProveedorDialog> {
  final _formKey = GlobalKey<FormState>();

  final _cuentaService = CuentaPagarService();

  final _montoController = TextEditingController();

  final _referenciaController = TextEditingController();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  String _metodoPago = 'EFECTIVO';

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _montoController.text = widget.cuenta.saldoPendiente.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _montoController.dispose();
    _referenciaController.dispose();

    super.dispose();
  }

  String _moneda(num valor) {
    return 'S/ ${_numero.format(valor)}';
  }

  double get _monto {
    return double.tryParse(_montoController.text.trim()) ?? 0;
  }

  double get _saldoDespues {
    return widget.cuenta.saldoPendiente - _monto;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_monto > widget.cuenta.saldoPendiente) {
      _mostrarMensaje(
        'El pago no puede superar el saldo pendiente de '
        '${_moneda(widget.cuenta.saldoPendiente)}.',
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final cuenta = await _cuentaService.registrarPago(
        PagoProveedorRequest(
          cuentaPagarId: widget.cuenta.id,
          monto: _monto,
          metodoPago: _metodoPago,
          referencia: _referenciaController.text.trim().isEmpty
              ? null
              : _referenciaController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(cuenta);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pantallaPequena = size.width < 600;

    final dialogWidth = pantallaPequena ? size.width * 0.94 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pantallaPequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.90,
        ),
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(pantallaPequena ? 14 : 18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(pantallaPequena),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pantallaPequena ? 18 : 24),
                  child: _buildForm(),
                ),
              ),

              _buildActions(pantallaPequena),
            ],
          ),
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
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.outbox_outlined, color: Color(0xFFEA580C)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago a proveedor',
                  style: TextStyle(
                    fontSize: pantallaPequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${widget.cuenta.razonSocialProveedor} • '
                  '${widget.cuenta.codigoCompra}',
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
            onPressed: _guardando
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildResumen(),

          const SizedBox(height: 20),

          TextFormField(
            controller: _montoController,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto del pago',
              prefixText: 'S/ ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            onChanged: (_) {
              setState(() {});
            },
            validator: (value) {
              final numero = double.tryParse(value?.trim() ?? '');

              if (numero == null || numero <= 0) {
                return 'El monto debe ser mayor que cero.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _metodoPago,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Método de pago',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'EFECTIVO', child: Text('Efectivo')),
              DropdownMenuItem(
                value: 'TRANSFERENCIA',
                child: Text('Transferencia'),
              ),
              DropdownMenuItem(value: 'YAPE', child: Text('Yape')),
              DropdownMenuItem(value: 'PLIN', child: Text('Plin')),
              DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
            ],
            onChanged: _guardando
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _metodoPago = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _referenciaController,
            enabled: !_guardando,
            maxLength: 100,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Referencia',
              hintText: 'Ej. operación, voucher u observación...',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
          ),

          if (_monto > 0) ...[
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _saldoDespues < 0
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Saldo por pagar después'),

                  Text(
                    _moneda(_saldoDespues),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _saldoDespues < 0
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline,
                  size: 17,
                  color: Color(0xFF64748B),
                ),
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'El pago generará automáticamente un egreso en la caja abierta.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 440;

        final total = _ProveedorDato(
          titulo: 'Total',
          valor: _moneda(widget.cuenta.montoTotal),
        );

        final pagado = _ProveedorDato(
          titulo: 'Pagado',
          valor: _moneda(widget.cuenta.montoPagado),
        );

        final pendiente = _ProveedorDato(
          titulo: 'Pendiente',
          valor: _moneda(widget.cuenta.saldoPendiente),
          destacado: true,
        );

        if (compacto) {
          return Column(
            children: [
              total,

              const SizedBox(height: 10),

              pagado,

              const SizedBox(height: 10),

              pendiente,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: total),

            const SizedBox(width: 12),

            Expanded(child: pagado),

            const SizedBox(width: 12),

            Expanded(child: pendiente),
          ],
        );
      },
    );
  }

  Widget _buildActions(bool pantallaPequena) {
    final cancelar = OutlinedButton(
      onPressed: _guardando
          ? null
          : () {
              Navigator.of(context).pop();
            },
      child: const Text('Cancelar'),
    );

    final registrar = ElevatedButton(
      onPressed: _guardando ? null : _guardar,
      child: _guardando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Registrar pago'),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pantallaPequena ? 16 : 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: pantallaPequena
          ? Column(
              children: [
                SizedBox(width: double.infinity, height: 44, child: registrar),

                const SizedBox(height: 10),

                SizedBox(width: double.infinity, height: 44, child: cancelar),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: 110, height: 44, child: cancelar),

                const SizedBox(width: 12),

                SizedBox(width: 160, height: 44, child: registrar),
              ],
            ),
    );
  }
}

class _ProveedorDato extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool destacado;

  const _ProveedorDato({
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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

          const SizedBox(height: 4),

          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: destacado ? const Color(0xFFEA580C) : null,
            ),
          ),
        ],
      ),
    );
  }
}

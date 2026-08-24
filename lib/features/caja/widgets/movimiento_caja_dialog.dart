import 'package:flutter/material.dart';

import '../models/caja.dart';
import '../models/movimiento_caja_request.dart';
import '../services/caja_service.dart';

class MovimientoCajaDialog extends StatefulWidget {
  final Caja caja;

  const MovimientoCajaDialog({super.key, required this.caja});

  @override
  State<MovimientoCajaDialog> createState() => _MovimientoCajaDialogState();
}

class _MovimientoCajaDialogState extends State<MovimientoCajaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cajaService = CajaService();

  final _montoController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _referenciaController = TextEditingController();

  String _tipoMovimiento = 'INGRESO';

  bool _guardando = false;

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    _referenciaController.dispose();

    super.dispose();
  }

  double get _monto {
    return double.tryParse(_montoController.text.trim()) ?? 0;
  }

  double get _saldoEstimado {
    if (_tipoMovimiento == 'INGRESO') {
      return widget.caja.saldoActual + _monto;
    }

    return widget.caja.saldoActual - _monto;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoMovimiento == 'EGRESO' && _monto > widget.caja.saldoActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo insuficiente. Disponible: '
            'S/ ${widget.caja.saldoActual.toStringAsFixed(2)}.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _cajaService.registrarMovimiento(
        MovimientoCajaRequest(
          cajaId: widget.caja.id,
          tipoMovimiento: _tipoMovimiento,
          monto: _monto,
          concepto: _conceptoController.text.trim(),
          referencia: _referenciaController.text.trim().isEmpty
              ? null
              : _referenciaController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pequena = size.width < 650;

    final ancho = pequena ? size.width * 0.92 : 620.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ancho,
          maxHeight: size.height * 0.92,
        ),
        child: Container(
          width: ancho,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(pequena),

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pequena ? 18 : 24),
                  child: _buildForm(pequena),
                ),
              ),

              _buildActions(pequena),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool pequena) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: pequena ? 16 : 24,
        vertical: pequena ? 14 : 20,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        children: [
          Container(
            width: pequena ? 38 : 42,
            height: pequena ? 38 : 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.swap_vert, color: Color(0xFF2563EB)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movimiento de caja',
                  style: TextStyle(
                    fontSize: pequena ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Registra un ingreso o egreso manual.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: _guardando
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool pequena) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSaldoActual(pequena),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: _tipoMovimiento,
            decoration: const InputDecoration(
              labelText: 'Tipo de movimiento',
              prefixIcon: Icon(Icons.swap_vert),
            ),
            items: const [
              DropdownMenuItem(value: 'INGRESO', child: Text('Ingreso')),
              DropdownMenuItem(value: 'EGRESO', child: Text('Egreso')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _tipoMovimiento = value;
              });
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _montoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: 'S/ ',
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

          TextFormField(
            controller: _conceptoController,
            maxLength: 255,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              hintText: 'Ej. Ingreso extraordinario',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El concepto es obligatorio.';
              }

              return null;
            },
          ),

          const SizedBox(height: 4),

          TextFormField(
            controller: _referenciaController,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Referencia',
              hintText: 'Opcional',
            ),
          ),

          if (_monto > 0) ...[
            const SizedBox(height: 10),

            _buildSaldoEstimado(pequena),
          ],
        ],
      ),
    );
  }

  Widget _buildSaldoActual(bool pequena) {
    final valor = 'S/ ${widget.caja.saldoActual.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: pequena
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo actual',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 6),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Text(
                  'Saldo actual',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),

                const Spacer(),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSaldoEstimado(bool pequena) {
    final valor = 'S/ ${_saldoEstimado.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _saldoEstimado < 0
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: pequena
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo después del movimiento'),

                const SizedBox(height: 6),

                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _saldoEstimado < 0
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Text('Saldo después del movimiento'),

                const Spacer(),

                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _saldoEstimado < 0
                        ? const Color(0xFFB91C1C)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActions(bool pequena) {
    return Container(
      padding: EdgeInsets.all(pequena ? 16 : 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: pequena
          ? Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
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
                        : const Text('Registrar movimiento'),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _guardando
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: _guardando
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    child: const Text('Cancelar'),
                  ),
                ),

                const SizedBox(width: 12),

                SizedBox(
                  width: 170,
                  child: ElevatedButton(
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
                        : const Text('Registrar movimiento'),
                  ),
                ),
              ],
            ),
    );
  }
}

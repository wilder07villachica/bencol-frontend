import 'package:flutter/material.dart';

import '../models/caja.dart';
import '../models/cierre_caja_request.dart';
import '../services/caja_service.dart';

class CerrarCajaDialog extends StatefulWidget {
  final Caja caja;

  const CerrarCajaDialog({super.key, required this.caja});

  @override
  State<CerrarCajaDialog> createState() => _CerrarCajaDialogState();
}

class _CerrarCajaDialogState extends State<CerrarCajaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cajaService = CajaService();

  final _saldoRealController = TextEditingController();

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    _saldoRealController.text = widget.caja.saldoActual.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _saldoRealController.dispose();

    super.dispose();
  }

  double get _saldoReal {
    return double.tryParse(_saldoRealController.text.trim()) ?? 0;
  }

  double get _saldoEsperado {
    return widget.caja.saldoInicial +
        widget.caja.totalIngresos -
        widget.caja.totalEgresos;
  }

  double get _diferencia {
    return _saldoReal - _saldoEsperado;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final caja = await _cajaService.cerrarCaja(
        cajaId: widget.caja.id,
        request: CierreCajaRequest(saldoReal: _saldoReal),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(caja);
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

    final ancho = pequena ? size.width * 0.92 : 600.0;

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
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFFDC2626)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cerrar caja',
                  style: TextStyle(
                    fontSize: pequena ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Ingresa el efectivo real contado al finalizar.',
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
          if (pequena)
            Column(
              children: [
                _ResumenCierre(
                  titulo: 'Saldo inicial',
                  valor: widget.caja.saldoInicial,
                ),

                const SizedBox(height: 10),

                _ResumenCierre(
                  titulo: 'Ingresos',
                  valor: widget.caja.totalIngresos,
                ),

                const SizedBox(height: 10),

                _ResumenCierre(
                  titulo: 'Egresos',
                  valor: widget.caja.totalEgresos,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _ResumenCierre(
                    titulo: 'Saldo inicial',
                    valor: widget.caja.saldoInicial,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _ResumenCierre(
                    titulo: 'Ingresos',
                    valor: widget.caja.totalIngresos,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _ResumenCierre(
                    titulo: 'Egresos',
                    valor: widget.caja.totalEgresos,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 18),

          _buildSaldoEsperado(pequena),

          const SizedBox(height: 18),

          TextFormField(
            controller: _saldoRealController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Saldo real contado',
              prefixText: 'S/ ',
            ),
            onChanged: (_) {
              setState(() {});
            },
            validator: (value) {
              final numero = double.tryParse(value?.trim() ?? '');

              if (numero == null) {
                return 'Ingresa un saldo válido.';
              }

              if (numero < 0) {
                return 'El saldo real no puede ser negativo.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          _buildDiferencia(pequena),
        ],
      ),
    );
  }

  Widget _buildSaldoEsperado(bool pequena) {
    final valor = 'S/ ${_saldoEsperado.toStringAsFixed(2)}';

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
                const Text('Saldo esperado'),

                const SizedBox(height: 6),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Text('Saldo esperado'),

                const Spacer(),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDiferencia(bool pequena) {
    final titulo = _diferencia == 0
        ? 'Caja cuadrada'
        : _diferencia > 0
        ? 'Sobrante'
        : 'Faltante';

    final valor = 'S/ ${_diferencia.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _diferencia == 0
            ? const Color(0xFFDCFCE7)
            : _diferencia > 0
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: pequena
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                        : const Text('Cerrar caja'),
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
                  width: 140,
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
                        : const Text('Cerrar caja'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ResumenCierre extends StatelessWidget {
  final String titulo;
  final double valor;

  const _ResumenCierre({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
            'S/ ${valor.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

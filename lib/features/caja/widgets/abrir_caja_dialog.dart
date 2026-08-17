import 'package:flutter/material.dart';

import '../models/caja_request.dart';
import '../services/caja_service.dart';

class AbrirCajaDialog extends StatefulWidget {
  const AbrirCajaDialog({super.key});

  @override
  State<AbrirCajaDialog> createState() => _AbrirCajaDialogState();
}

class _AbrirCajaDialogState extends State<AbrirCajaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cajaService = CajaService();

  final _saldoInicialController = TextEditingController(text: '0');

  bool _guardando = false;

  @override
  void dispose() {
    _saldoInicialController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final saldoInicial = double.parse(_saldoInicialController.text.trim());

    setState(() {
      _guardando = true;
    });

    try {
      final caja = await _cajaService.abrirCaja(
        CajaRequest(saldoInicial: saldoInicial),
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

    final pequena = size.width < 600;

    final ancho = pequena ? size.width * 0.92 : 520.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ancho,
          maxHeight: size.height * 0.90,
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
                  child: Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _saldoInicialController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Saldo inicial',
                        prefixText: 'S/ ',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (value) {
                        final numero = double.tryParse(value?.trim() ?? '');

                        if (numero == null) {
                          return 'Ingresa un saldo válido.';
                        }

                        if (numero < 0) {
                          return 'El saldo inicial no puede ser negativo.';
                        }

                        return null;
                      },
                    ),
                  ),
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
            child: const Icon(
              Icons.lock_open_outlined,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Abrir caja',
                  style: TextStyle(
                    fontSize: pequena ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Registra el efectivo disponible al inicio de la jornada.',
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
                        : const Text('Abrir caja'),
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
                  width: 105,
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
                  width: 130,
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
                        : const Text('Abrir caja'),
                  ),
                ),
              ],
            ),
    );
  }
}

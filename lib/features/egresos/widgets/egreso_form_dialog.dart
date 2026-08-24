import 'package:flutter/material.dart';

import '../models/egreso_request.dart';
import '../services/egreso_service.dart';

class EgresoFormDialog extends StatefulWidget {
  const EgresoFormDialog({super.key});

  @override
  State<EgresoFormDialog> createState() => _EgresoFormDialogState();
}

class _EgresoFormDialogState extends State<EgresoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _egresoService = EgresoService();

  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  final _referenciaController = TextEditingController();

  String _categoria = 'OTRO';

  bool _guardando = false;

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _referenciaController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final monto = double.parse(
      _montoController.text.trim().replaceAll(',', '.'),
    );

    setState(() {
      _guardando = true;
    });

    try {
      final egreso = await _egresoService.crear(
        EgresoRequest(
          categoria: _categoria,
          concepto: _conceptoController.text.trim(),
          monto: monto,
          referencia: _referenciaController.text.trim().isEmpty
              ? null
              : _referenciaController.text.trim(),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(egreso);
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

    final pantallaPequena = size.width < 600;

    final dialogWidth = pantallaPequena ? size.width * 0.94 : 620.0;

    final maxDialogHeight = size.height * 0.90;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pantallaPequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
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
        horizontal: pantallaPequena ? 18 : 24,
        vertical: pantallaPequena ? 15 : 20,
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
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.trending_down,
              size: pantallaPequena ? 20 : 24,
              color: const Color(0xFFDC2626),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo egreso',
                  style: TextStyle(
                    fontSize: pantallaPequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Registra un gasto operativo de Bencol.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
          DropdownButtonFormField<String>(
            initialValue: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: 'COMBUSTIBLE',
                child: Text('Combustible'),
              ),
              DropdownMenuItem(value: 'MOVILIDAD', child: Text('Movilidad')),
              DropdownMenuItem(value: 'SERVICIOS', child: Text('Servicios')),
              DropdownMenuItem(
                value: 'MANTENIMIENTO',
                child: Text('Mantenimiento'),
              ),
              DropdownMenuItem(value: 'INSUMOS', child: Text('Insumos')),
              DropdownMenuItem(value: 'PERSONAL', child: Text('Personal')),
              DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
            ],
            onChanged: _guardando
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _categoria = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _conceptoController,
            enabled: !_guardando,
            maxLength: 255,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Concepto',
              hintText: 'Ej. combustible para reparto',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El concepto es obligatorio.';
              }

              return null;
            },
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _montoController,
            enabled: !_guardando,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: 'S/ ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (value) {
              final numero = double.tryParse(
                (value ?? '').trim().replaceAll(',', '.'),
              );

              if (numero == null || numero <= 0) {
                return 'El monto debe ser mayor que cero.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _referenciaController,
            enabled: !_guardando,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Referencia',
              hintText: 'Factura, recibo u observación...',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
          ),

          const SizedBox(height: 6),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 17, color: Color(0xFF64748B)),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Este egreso se descontará automáticamente '
                    'de la caja abierta.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

    final guardar = ElevatedButton(
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
          : const Text('Registrar egreso'),
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
                SizedBox(width: double.infinity, height: 44, child: guardar),

                const SizedBox(height: 10),

                SizedBox(width: double.infinity, height: 44, child: cancelar),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: 110, height: 44, child: cancelar),

                const SizedBox(width: 12),

                SizedBox(width: 150, height: 44, child: guardar),
              ],
            ),
    );
  }
}

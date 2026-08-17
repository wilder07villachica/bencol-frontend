import 'package:flutter/material.dart';

import '../models/inventario.dart';
import '../models/movimiento_inventario_request.dart';
import '../services/inventario_service.dart';

class MovimientoInventarioDialog extends StatefulWidget {
  final Inventario inventario;

  const MovimientoInventarioDialog({super.key, required this.inventario});

  @override
  State<MovimientoInventarioDialog> createState() =>
      _MovimientoInventarioDialogState();
}

class _MovimientoInventarioDialogState
    extends State<MovimientoInventarioDialog> {
  final _formKey = GlobalKey<FormState>();

  final _inventarioService = InventarioService();

  final _cantidadController = TextEditingController();

  final _referenciaController = TextEditingController();

  String _tipoMovimiento = 'ENTRADA';

  bool _guardando = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    _referenciaController.dispose();

    super.dispose();
  }

  int get _cantidad {
    return int.tryParse(_cantidadController.text.trim()) ?? 0;
  }

  int get _stockEstimado {
    if (_tipoMovimiento == 'ENTRADA') {
      return widget.inventario.stockActual + _cantidad;
    }

    return widget.inventario.stockActual - _cantidad;
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoMovimiento == 'SALIDA' &&
        _cantidad > widget.inventario.stockActual) {
      _mostrarMensaje(
        'Stock insuficiente. Disponible: '
        '${widget.inventario.stockActual}.',
      );

      return;
    }

    if (_tipoMovimiento == 'ENTRADA' &&
        widget.inventario.stockMaximo != null &&
        _stockEstimado > widget.inventario.stockMaximo!) {
      _mostrarMensaje(
        'El movimiento superaría el stock máximo '
        '(${widget.inventario.stockMaximo}).',
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _inventarioService.registrarMovimiento(
        MovimientoInventarioRequest(
          productoId: widget.inventario.productoId,
          tipoMovimiento: _tipoMovimiento,
          cantidad: _cantidad,
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
    final size = MediaQuery.sizeOf(context);

    final margen = size.width < 650 ? 10.0 : 24.0;

    final width = size.width < 650 ? size.width - (margen * 2) : 600.0;

    final maxHeight = size.height < 720 ? size.height * 0.92 : 690.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: margen, vertical: 14),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(),
                ),
              ),

              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 500;

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
                child: const Icon(Icons.swap_vert, color: Color(0xFF2563EB)),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Movimiento de inventario',
                      style: TextStyle(
                        fontSize: pequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${widget.inventario.codigoProducto} - '
                      '${widget.inventario.descripcionProducto}',
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
      },
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildResumenStock(),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: _tipoMovimiento,
            decoration: const InputDecoration(
              labelText: 'Tipo de movimiento',
              prefixIcon: Icon(Icons.swap_vert),
            ),
            items: const [
              DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
              DropdownMenuItem(value: 'SALIDA', child: Text('Salida')),
            ],
            onChanged: _guardando
                ? null
                : (value) {
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
            controller: _cantidadController,
            enabled: !_guardando,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad'),
            onChanged: (_) {
              setState(() {});
            },
            validator: (value) {
              final numero = int.tryParse(value?.trim() ?? '');

              if (numero == null || numero <= 0) {
                return 'La cantidad debe ser mayor que cero.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _referenciaController,
            enabled: !_guardando,
            maxLength: 255,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Referencia',
              hintText: 'Ej. Compra proveedor, ajuste manual...',
            ),
          ),

          if (_cantidad > 0) ...[
            const SizedBox(height: 10),

            _buildStockEstimado(),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenStock() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            children: [
              _DatoStockCard(
                titulo: 'Stock actual',
                valor: widget.inventario.stockActual,
              ),

              const SizedBox(height: 8),

              _DatoStockCard(
                titulo: 'Stock mínimo',
                valor: widget.inventario.stockMinimo,
              ),

              const SizedBox(height: 8),

              _DatoStockCard(
                titulo: 'Stock máximo',
                valor: widget.inventario.stockMaximo,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _DatoStockCard(
                titulo: 'Stock actual',
                valor: widget.inventario.stockActual,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _DatoStockCard(
                titulo: 'Stock mínimo',
                valor: widget.inventario.stockMinimo,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _DatoStockCard(
                titulo: 'Stock máximo',
                valor: widget.inventario.stockMaximo,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockEstimado() {
    final negativo = _stockEstimado < 0;

    final superaMaximo =
        _tipoMovimiento == 'ENTRADA' &&
        widget.inventario.stockMaximo != null &&
        _stockEstimado > widget.inventario.stockMaximo!;

    final advertencia = negativo || superaMaximo;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: advertencia ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Stock estimado después del movimiento',
              style: TextStyle(
                fontSize: 12,
                color: advertencia
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF475569),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            _stockEstimado.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: advertencia
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 500;

        if (pequena) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
            ),
            child: Column(
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

                const SizedBox(height: 8),

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
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
          ),
          child: Row(
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
                width: 160,
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
      },
    );
  }
}

class _DatoStockCard extends StatelessWidget {
  final String titulo;
  final int? valor;

  const _DatoStockCard({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),

          const SizedBox(height: 4),

          Text(
            valor?.toString() ?? '-',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

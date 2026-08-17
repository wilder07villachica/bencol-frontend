import 'package:flutter/material.dart';

import '../models/cuenta_envases.dart';
import '../models/movimiento_envase_request.dart';
import '../services/envase_service.dart';

class MovimientoEnvaseDialog extends StatefulWidget {
  final CuentaEnvases cuenta;

  const MovimientoEnvaseDialog({super.key, required this.cuenta});

  @override
  State<MovimientoEnvaseDialog> createState() => _MovimientoEnvaseDialogState();
}

class _MovimientoEnvaseDialogState extends State<MovimientoEnvaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _envaseService = EnvaseService();

  final _cantidadController = TextEditingController();
  final _referenciaController = TextEditingController();

  String _tipoMovimiento = 'DEVOLUCION';

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

  int get _propiosDespues {
    switch (_tipoMovimiento) {
      case 'CONVERSION_COMPRA':
        return widget.cuenta.cantidadPropios + _cantidad;

      default:
        return widget.cuenta.cantidadPropios;
    }
  }

  int get _prestadosDespues {
    switch (_tipoMovimiento) {
      case 'DEVOLUCION':
      case 'CONVERSION_COMPRA':
        return widget.cuenta.cantidadPrestados - _cantidad;

      default:
        return widget.cuenta.cantidadPrestados;
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_cantidad > widget.cuenta.cantidadPrestados) {
      _mostrarMensaje(
        'La cantidad no puede superar los '
        '${widget.cuenta.cantidadPrestados} '
        'envases prestados.',
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _envaseService.registrarMovimiento(
        MovimientoEnvaseRequest(
          clienteId: widget.cuenta.clienteId,
          productoId: widget.cuenta.productoId,
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
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestionar envases',
                  style: TextStyle(
                    fontSize: pantallaPequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${widget.cuenta.nombreCliente} - '
                  '${widget.cuenta.descripcionProducto}',
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
          _buildSaldoActual(),

          const SizedBox(height: 18),

          DropdownButtonFormField<String>(
            initialValue: _tipoMovimiento,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Operación',
              prefixIcon: Icon(Icons.swap_horiz),
            ),
            items: const [
              DropdownMenuItem(value: 'DEVOLUCION', child: Text('Devolución')),
              DropdownMenuItem(
                value: 'CONVERSION_COMPRA',
                child: Text('Convertir préstamo a compra'),
              ),
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
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              prefixIcon: Icon(Icons.numbers),
            ),
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
              hintText: 'Ej. Devolución física de cliente',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
          ),

          if (_cantidad > 0) ...[
            const SizedBox(height: 10),

            _buildSaldoProyectado(),
          ],
        ],
      ),
    );
  }

  Widget _buildSaldoActual() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 440;

        final cards = [
          _SaldoDato(titulo: 'Propios', valor: widget.cuenta.cantidadPropios),
          _SaldoDato(
            titulo: 'Prestados',
            valor: widget.cuenta.cantidadPrestados,
          ),
          _SaldoDato(titulo: 'Total', valor: widget.cuenta.cantidadTotal),
        ];

        if (compacto) {
          return Column(
            children: [
              _SaldoContainer(child: cards[0]),

              const SizedBox(height: 8),

              _SaldoContainer(child: cards[1]),

              const SizedBox(height: 8),

              _SaldoContainer(child: cards[2]),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: cards[0]),

              const SizedBox(width: 12),

              Expanded(child: cards[1]),

              const SizedBox(width: 12),

              Expanded(child: cards[2]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaldoProyectado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 440;

          final propios = _SaldoDato(
            titulo: 'Propios después',
            valor: _propiosDespues,
          );

          final prestados = _SaldoDato(
            titulo: 'Prestados después',
            valor: _prestadosDespues,
          );

          final total = _SaldoDato(
            titulo: 'Total después',
            valor: _propiosDespues + _prestadosDespues,
          );

          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                propios,

                const SizedBox(height: 12),

                prestados,

                const SizedBox(height: 12),

                total,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: propios),

              const SizedBox(width: 12),

              Expanded(child: prestados),

              const SizedBox(width: 12),

              Expanded(child: total),
            ],
          );
        },
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
          : const Text('Registrar operación'),
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

                SizedBox(width: 170, height: 44, child: registrar),
              ],
            ),
    );
  }
}

class _SaldoContainer extends StatelessWidget {
  final Widget child;

  const _SaldoContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _SaldoDato extends StatelessWidget {
  final String titulo;
  final int valor;

  const _SaldoDato({required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          valor.toString(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

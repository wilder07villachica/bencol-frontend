import 'package:flutter/material.dart';

import '../../productos/models/producto.dart';
import '../../productos/services/producto_service.dart';

import '../models/inventario_request.dart';
import '../services/inventario_service.dart';

class InventarioFormDialog extends StatefulWidget {
  const InventarioFormDialog({super.key});

  @override
  State<InventarioFormDialog> createState() => _InventarioFormDialogState();
}

class _InventarioFormDialogState extends State<InventarioFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _productoService = ProductoService();
  final _inventarioService = InventarioService();

  final _stockActualController = TextEditingController(text: '0');

  final _stockMinimoController = TextEditingController(text: '0');

  final _stockMaximoController = TextEditingController();

  List<Producto> _productos = [];

  int? _productoId;

  bool _cargando = true;
  bool _guardando = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _cargarProductos();
  }

  @override
  void dispose() {
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    _stockMaximoController.dispose();

    super.dispose();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final paginaProductos = await _productoService.obtenerProductos(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
      );

      final paginaInventarios = await _inventarioService.obtenerInventarios(
        pagina: 0,
        tamanio: 100,
      );

      if (!mounted) {
        return;
      }

      final productosConInventario = paginaInventarios.contenido
          .map((inventario) => inventario.productoId)
          .toSet();

      final productosDisponibles = paginaProductos.contenido
          .where((producto) => !productosConInventario.contains(producto.id))
          .toList();

      setState(() {
        _productos = productosDisponibles;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');

        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productoId == null) {
      return;
    }

    final stockActual = int.parse(_stockActualController.text.trim());

    final stockMinimo = int.parse(_stockMinimoController.text.trim());

    final stockMaximo = _stockMaximoController.text.trim().isEmpty
        ? null
        : int.parse(_stockMaximoController.text.trim());

    if (stockMaximo != null && stockMaximo < stockMinimo) {
      _mostrarMensaje(
        'El stock máximo no puede ser menor que el stock mínimo.',
      );

      return;
    }

    if (stockMaximo != null && stockActual > stockMaximo) {
      _mostrarMensaje('El stock actual no puede superar el stock máximo.');

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _inventarioService.crear(
        InventarioRequest(
          productoId: _productoId!,
          stockActual: stockActual,
          stockMinimo: stockMinimo,
          stockMaximo: stockMaximo,
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

    final width = size.width < 680 ? size.width - (margen * 2) : 620.0;

    final maxHeight = size.height < 680 ? size.height * 0.92 : 650.0;

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

              Flexible(child: _buildContenido()),

              if (!_cargando && _error == null) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenido() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: Color(0xFFDC2626),
              ),

              const SizedBox(height: 12),

              Text(_error!, textAlign: TextAlign.center),

              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _cargarProductos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildForm(),
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
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nuevo inventario',
                      style: TextStyle(
                        fontSize: pequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Registra el stock inicial de un producto.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
    if (_productos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: Color(0xFF94A3B8),
            ),

            SizedBox(height: 12),

            Text(
              'Todos los productos activos ya tienen inventario registrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            initialValue: _productoId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Producto',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: _productos.map((producto) {
              return DropdownMenuItem<int>(
                value: producto.id,
                child: Text(
                  '${producto.codigo} - '
                  '${producto.descripcion}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            validator: (value) {
              if (value == null) {
                return 'Selecciona un producto.';
              }

              return null;
            },
            onChanged: _guardando
                ? null
                : (value) {
                    setState(() {
                      _productoId = value;
                    });
                  },
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 540) {
                return Column(
                  children: [
                    _buildStockActual(),

                    const SizedBox(height: 14),

                    _buildStockMinimo(),

                    const SizedBox(height: 14),

                    _buildStockMaximo(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildStockActual()),

                  const SizedBox(width: 14),

                  Expanded(child: _buildStockMinimo()),

                  const SizedBox(width: 14),

                  Expanded(child: _buildStockMaximo()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockActual() {
    return TextFormField(
      controller: _stockActualController,
      enabled: !_guardando,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Stock actual'),
      validator: _validarEnteroNoNegativo,
    );
  }

  Widget _buildStockMinimo() {
    return TextFormField(
      controller: _stockMinimoController,
      enabled: !_guardando,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(labelText: 'Stock mínimo'),
      validator: _validarEnteroNoNegativo,
    );
  }

  Widget _buildStockMaximo() {
    return TextFormField(
      controller: _stockMaximoController,
      enabled: !_guardando,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Stock máximo',
        hintText: 'Opcional',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }

        return _validarEnteroNoNegativo(value);
      },
    );
  }

  String? _validarEnteroNoNegativo(String? value) {
    final numero = int.tryParse(value?.trim() ?? '');

    if (numero == null) {
      return 'Número inválido.';
    }

    if (numero < 0) {
      return 'No puede ser negativo.';
    }

    return null;
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 500;

        if (pequena) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando || _productos.isEmpty
                        ? null
                        : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Crear inventario'),
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
                width: 150,
                child: ElevatedButton(
                  onPressed: _guardando || _productos.isEmpty ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Crear inventario'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

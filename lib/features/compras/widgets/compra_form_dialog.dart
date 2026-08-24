import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../productos/models/producto.dart';
import '../../productos/services/producto_service.dart';

import '../../proveedores/models/proveedor.dart';
import '../../proveedores/services/proveedor_service.dart';

import '../models/compra_request.dart';
import '../models/detalle_compra_request.dart';
import '../services/compra_service.dart';

class CompraFormDialog extends StatefulWidget {
  const CompraFormDialog({super.key});

  @override
  State<CompraFormDialog> createState() => _CompraFormDialogState();
}

class _CompraFormDialogState extends State<CompraFormDialog> {
  final _proveedorService = ProveedorService();
  final _productoService = ProductoService();
  final _compraService = CompraService();

  final ScrollController _detallesScrollController = ScrollController();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  List<Proveedor> _proveedores = [];
  List<Producto> _productos = [];

  final List<_DetalleCompraTemporal> _detalles = [];

  int? _proveedorId;

  bool _cargando = true;
  bool _guardando = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _cargarCatalogos();
  }

  @override
  void dispose() {
    _detallesScrollController.dispose();

    super.dispose();
  }

  double get _total {
    return _detalles.fold<double>(
      0,
      (total, detalle) => total + detalle.subtotal,
    );
  }

  String _moneda(num valor) {
    return 'S/ ${_numero.format(valor)}';
  }

  Future<void> _cargarCatalogos() async {
    try {
      final proveedores = await _proveedorService.obtenerProveedores(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
      );

      final productos = await _productoService.obtenerProductos(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _proveedores = proveedores.contenido;
        _productos = productos.contenido;

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

  Future<void> _agregarProducto() async {
    final disponibles = _productos
        .where(
          (producto) =>
              !_detalles.any((detalle) => detalle.producto.id == producto.id),
        )
        .toList();

    if (disponibles.isEmpty) {
      _mostrarMensaje('No hay más productos disponibles para agregar.');

      return;
    }

    final detalle = await showDialog<_DetalleCompraTemporal>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AgregarDetalleCompraDialog(productos: disponibles);
      },
    );

    if (detalle == null) {
      return;
    }

    setState(() {
      _detalles.add(detalle);
    });
  }

  Future<void> _editarDetalle(int indice) async {
    final actual = _detalles[indice];

    final productosDisponibles = _productos
        .where(
          (producto) =>
              producto.id == actual.producto.id ||
              !_detalles.any((detalle) => detalle.producto.id == producto.id),
        )
        .toList();

    final resultado = await showDialog<_DetalleCompraTemporal>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AgregarDetalleCompraDialog(
          productos: productosDisponibles,
          detalleInicial: actual,
        );
      },
    );

    if (resultado == null) {
      return;
    }

    setState(() {
      _detalles[indice] = resultado;
    });
  }

  void _eliminarDetalle(int indice) {
    setState(() {
      _detalles.removeAt(indice);
    });
  }

  Future<void> _guardar() async {
    if (_proveedorId == null) {
      _mostrarMensaje('Selecciona un proveedor.');

      return;
    }

    if (_detalles.isEmpty) {
      _mostrarMensaje('La compra debe contener al menos un producto.');

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final compra = await _compraService.crear(
        CompraRequest(
          proveedorId: _proveedorId!,
          detalles: _detalles
              .map(
                (detalle) => DetalleCompraRequest(
                  productoId: detalle.producto.id,
                  cantidad: detalle.cantidad,
                  costoUnitario: detalle.costoUnitario,
                ),
              )
              .toList(),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(compra);
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

    final pequena = size.width < 720;

    final ancho = size.width < 1100 ? size.width * 0.92 : 1000.0;

    final maxHeight = size.height * 0.92;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho, maxHeight: maxHeight),
        child: Container(
          width: ancho,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(pequena),

              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    : _buildContenido(pequena),
              ),

              if (!_cargando && _error == null) _buildActions(pequena),
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
              Icons.shopping_cart_outlined,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva compra',
                  style: TextStyle(
                    fontSize: pequena ? 18 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Registra productos adquiridos a un proveedor.',
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

  Widget _buildContenido(bool pequena) {
    return SingleChildScrollView(
      primary: false,
      padding: EdgeInsets.all(pequena ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _proveedorId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Proveedor',
              prefixIcon: Icon(Icons.local_shipping_outlined),
            ),
            items: _proveedores.map((proveedor) {
              return DropdownMenuItem<int>(
                value: proveedor.id,
                child: Text(
                  '${proveedor.razonSocial} - '
                  '${proveedor.ruc}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _proveedorId = value;
              });
            },
          ),

          const SizedBox(height: 24),

          _buildTituloProductos(pequena),

          const SizedBox(height: 14),

          _buildDetalles(),

          const SizedBox(height: 22),

          _buildTotal(pequena),
        ],
      ),
    );
  }

  Widget _buildTituloProductos(bool pequena) {
    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _agregarProducto,
      icon: const Icon(Icons.add),
      label: const Text('Agregar producto'),
    );

    if (pequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          SizedBox(width: double.infinity, child: boton),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Text(
            'Productos',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),

        SizedBox(width: 170, child: boton),
      ],
    );
  }

  Widget _buildDetalles() {
    if (_detalles.isEmpty) {
      return Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Agrega al menos un producto a la compra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EAF0)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _detallesScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _detallesScrollController,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Cantidad')),
                    DataColumn(label: Text('Costo unitario')),
                    DataColumn(label: Text('Subtotal')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: List.generate(_detalles.length, (indice) {
                    final detalle = _detalles[indice];

                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 230,
                            child: Text(
                              '${detalle.producto.codigo} - '
                              '${detalle.producto.descripcion}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(Text(detalle.cantidad.toString())),

                        DataCell(Text(_moneda(detalle.costoUnitario))),

                        DataCell(
                          Text(
                            _moneda(detalle.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),

                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () {
                                  _editarDetalle(indice);
                                },
                                icon: const Icon(Icons.edit_outlined, size: 20),
                              ),

                              IconButton(
                                tooltip: 'Eliminar',
                                onPressed: () {
                                  _eliminarDetalle(indice);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotal(bool pequena) {
    return Align(
      alignment: pequena ? Alignment.center : Alignment.centerRight,
      child: SizedBox(
        width: pequena ? double.infinity : 300,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('Total', style: TextStyle(color: Color(0xFF64748B))),

              const Spacer(),

              Text(
                _moneda(_total),
                style: TextStyle(
                  fontSize: pequena ? 18 : 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(bool pequena) {
    return Container(
      width: double.infinity,
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
                        : const Text('Registrar compra'),
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
                  width: 160,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
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
                        : const Text('Registrar compra'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DetalleCompraTemporal {
  final Producto producto;
  final int cantidad;
  final double costoUnitario;

  const _DetalleCompraTemporal({
    required this.producto,
    required this.cantidad,
    required this.costoUnitario,
  });

  double get subtotal {
    return cantidad * costoUnitario;
  }
}

class _AgregarDetalleCompraDialog extends StatefulWidget {
  final List<Producto> productos;
  final _DetalleCompraTemporal? detalleInicial;

  const _AgregarDetalleCompraDialog({
    required this.productos,
    this.detalleInicial,
  });

  @override
  State<_AgregarDetalleCompraDialog> createState() {
    return _AgregarDetalleCompraDialogState();
  }
}

class _AgregarDetalleCompraDialogState
    extends State<_AgregarDetalleCompraDialog> {
  final _formKey = GlobalKey<FormState>();

  final _cantidadController = TextEditingController();
  final _costoController = TextEditingController();

  int? _productoId;

  @override
  void initState() {
    super.initState();

    final inicial = widget.detalleInicial;

    if (inicial != null) {
      _productoId = inicial.producto.id;

      _cantidadController.text = inicial.cantidad.toString();

      _costoController.text = inicial.costoUnitario.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _costoController.dispose();

    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_productoId == null) {
      return;
    }

    final producto = widget.productos.firstWhere(
      (producto) => producto.id == _productoId,
    );

    Navigator.of(context).pop(
      _DetalleCompraTemporal(
        producto: producto,
        cantidad: int.parse(_cantidadController.text.trim()),
        costoUnitario: double.parse(_costoController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pequena = size.width < 600;

    final ancho = pequena ? size.width * 0.90 : 520.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ancho,
          maxHeight: size.height * 0.88,
        ),
        child: Container(
          width: ancho,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, pequena),

              Flexible(
                child: SingleChildScrollView(
                  primary: false,
                  padding: EdgeInsets.all(pequena ? 16 : 22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _productoId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Producto',
                          ),
                          items: widget.productos
                              .map(
                                (producto) => DropdownMenuItem<int>(
                                  value: producto.id,
                                  child: Text(
                                    '${producto.codigo} - '
                                    '${producto.descripcion}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          validator: (value) {
                            if (value == null) {
                              return 'Selecciona un producto.';
                            }

                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _productoId = value;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _cantidadController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad física',
                            helperText:
                                'Cantidad que ingresará directamente al inventario.',
                          ),
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
                          controller: _costoController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Costo unitario',
                            prefixText: 'S/ ',
                          ),
                          validator: (value) {
                            final numero = double.tryParse(value?.trim() ?? '');

                            if (numero == null || numero <= 0) {
                              return 'El costo debe ser mayor que cero.';
                            }

                            return null;
                          },
                        ),
                      ],
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

  Widget _buildHeader(BuildContext context, bool pequena) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: pequena ? 16 : 22,
        vertical: pequena ? 14 : 18,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.detalleInicial == null
                  ? 'Agregar producto'
                  : 'Editar producto',
              style: TextStyle(
                fontSize: pequena ? 17 : 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          IconButton(
            onPressed: () {
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
      width: double.infinity,
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
                    onPressed: _guardar,
                    child: const Text('Aceptar'),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
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
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  width: 110,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
    );
  }
}

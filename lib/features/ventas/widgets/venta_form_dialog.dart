import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_form_grid.dart';

import '../../auth/models/auth_user.dart';

import '../../clientes/models/cliente.dart';
import '../../clientes/models/pagina_clientes.dart';
import '../../clientes/services/cliente_service.dart';

import '../../productos/models/pagina_productos.dart';
import '../../productos/models/producto.dart';
import '../../productos/services/producto_service.dart';

import '../../inventario/models/inventario.dart';
import '../../inventario/services/inventario_service.dart';

import '../../envases/models/cuenta_envases.dart';
import '../../envases/services/envase_service.dart';

import '../../precios_clientes/services/cliente_precio_service.dart';

import '../models/detalle_venta_request.dart';
import '../models/venta_request.dart';
import '../services/venta_service.dart';

class VentaFormDialog extends StatefulWidget {
  final AuthUser usuario;

  const VentaFormDialog({super.key, required this.usuario});

  @override
  State<VentaFormDialog> createState() => _VentaFormDialogState();
}

class _VentaFormDialogState extends State<VentaFormDialog> {
  final _clienteService = ClienteService();
  final _productoService = ProductoService();
  final _ventaService = VentaService();

  final _inventarioService = InventarioService();
  final _envaseService = EnvaseService();
  final _clientePrecioService = ClientePrecioService();

  final _cantidadController = TextEditingController(text: '1');

  final _precioManualController = TextEditingController();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  List<Cliente> _clientes = [];
  List<Producto> _productos = [];

  final List<_DetalleTemporal> _detalles = [];

  int? _clienteId;
  int? _productoId;

  String? _modalidadEnvase;

  int _envasesDevueltos = 0;

  Inventario? _inventarioProducto;
  CuentaEnvases? _cuentaEnvases;

  double? _precioEspecial;

  bool _cargando = true;
  bool _guardando = false;
  bool _consultandoProducto = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioManualController.dispose();

    super.dispose();
  }

  Producto? get _productoSeleccionado {
    if (_productoId == null) {
      return null;
    }

    for (final producto in _productos) {
      if (producto.id == _productoId) {
        return producto;
      }
    }

    return null;
  }

  bool get _esBidon {
    return _productoSeleccionado?.categoria == 'BIDON';
  }

  bool get _esAdmin {
    return widget.usuario.rol == 'ADMIN';
  }

  bool get _esCompraBidon {
    return _esBidon && _modalidadEnvase == 'COMPRA';
  }

  String _moneda(num valor) {
    return 'S/ ${_numero.format(valor)}';
  }

  Future<void> _cargarCatalogos() async {
    try {
      final resultados = await Future.wait([
        _clienteService.obtenerClientes(
          pagina: 0,
          tamanio: 100,
          estado: 'ACTIVO',
        ),
        _productoService.obtenerProductos(
          pagina: 0,
          tamanio: 100,
          estado: 'ACTIVO',
        ),
      ]);

      if (!mounted) {
        return;
      }

      final clientes = resultados[0] as PaginaClientes;

      final productos = resultados[1] as PaginaProductos;

      setState(() {
        _clientes = clientes.contenido;
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

  void _seleccionarCliente(int? clienteId) {
    setState(() {
      _clienteId = clienteId;
      _productoId = null;

      _inventarioProducto = null;
      _cuentaEnvases = null;
      _precioEspecial = null;

      _modalidadEnvase = null;
      _envasesDevueltos = 0;

      _cantidadController.text = '1';
      _precioManualController.clear();
    });
  }

  Future<void> _seleccionarProducto(int? productoId) async {
    setState(() {
      _productoId = productoId;

      _modalidadEnvase = null;
      _envasesDevueltos = 0;

      _precioManualController.clear();

      _inventarioProducto = null;
      _cuentaEnvases = null;
      _precioEspecial = null;

      _cantidadController.text = '1';

      _consultandoProducto = productoId != null;
    });

    if (productoId == null) {
      return;
    }

    final producto = _productoSeleccionado;

    if (producto == null) {
      return;
    }

    try {
      final inventario = await _inventarioService.obtenerPorProducto(
        producto.id,
      );

      CuentaEnvases? cuentaEnvases;

      if (producto.categoria == 'BIDON' && _clienteId != null) {
        cuentaEnvases = await _envaseService.obtenerCuenta(
          clienteId: _clienteId!,
          productoId: producto.id,
        );
      }

      double? precioEspecial;

      if (_clienteId != null) {
        final paginaPrecios = await _clientePrecioService.obtenerPrecios(
          pagina: 0,
          tamanio: 1,
          clienteId: _clienteId,
          productoId: producto.id,
        );

        if (paginaPrecios.contenido.isNotEmpty) {
          precioEspecial = paginaPrecios.contenido.first.precio;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _inventarioProducto = inventario;
        _cuentaEnvases = cuentaEnvases;
        _precioEspecial = precioEspecial;

        _consultandoProducto = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _consultandoProducto = false;
      });

      _mostrarMensaje(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _seleccionarModalidad(String? modalidad) {
    setState(() {
      _modalidadEnvase = modalidad;

      if (modalidad == 'INTERCAMBIO') {
        _envasesDevueltos = int.tryParse(_cantidadController.text) ?? 0;
      } else {
        _envasesDevueltos = 0;
      }

      if (modalidad != 'COMPRA') {
        _precioManualController.clear();
      }
    });
  }

  void _actualizarCantidad(String value) {
    setState(() {
      if (_modalidadEnvase == 'INTERCAMBIO') {
        _envasesDevueltos = int.tryParse(value) ?? 0;
      }
    });
  }

  double _obtenerPrecioEstimado(Producto producto, double? precioManual) {
    if (producto.categoria == 'BIDON' && _modalidadEnvase == 'COMPRA') {
      return precioManual ?? producto.precioBase;
    }

    return _precioEspecial ?? producto.precioBase;
  }

  void _agregarProducto() {
    if (_consultandoProducto) {
      _mostrarMensaje(
        'Espera mientras se consulta la información del producto.',
      );
      return;
    }

    if (_clienteId == null) {
      _mostrarMensaje('Selecciona primero un cliente.');
      return;
    }

    final producto = _productoSeleccionado;

    if (producto == null) {
      _mostrarMensaje('Selecciona un producto.');
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text.trim());

    if (cantidad == null || cantidad <= 0) {
      _mostrarMensaje('La cantidad debe ser mayor que cero.');
      return;
    }

    final duplicado = _detalles.any(
      (detalle) => detalle.producto.id == producto.id,
    );

    if (duplicado) {
      _mostrarMensaje('El producto ya fue agregado a la venta.');
      return;
    }

    String? modalidad;
    int? envasesDevueltos;
    double? precioManual;

    if (producto.categoria != 'BIDON') {
      if (_inventarioProducto == null) {
        _mostrarMensaje(
          'Este producto no tiene inventario registrado y no puede venderse.',
        );
        return;
      }

      final unidadesFisicas = cantidad * producto.unidadesPorPaquete;

      if (unidadesFisicas > _inventarioProducto!.stockActual) {
        _mostrarMensaje(
          'Stock insuficiente. '
          'La venta necesita $unidadesFisicas unidades físicas '
          'y solo hay ${_inventarioProducto!.stockActual} disponibles.',
        );
        return;
      }
    }

    if (producto.categoria == 'BIDON') {
      if (_modalidadEnvase == null) {
        _mostrarMensaje('Selecciona la modalidad del bidón.');
        return;
      }

      modalidad = _modalidadEnvase;

      if (modalidad == 'INTERCAMBIO') {
        final disponible = _cuentaEnvases?.cantidadTotal ?? 0;

        if (cantidad > disponible) {
          if (disponible == 0) {
            _mostrarMensaje(
              'El cliente no tiene envases registrados para realizar un intercambio.',
            );
          } else {
            _mostrarMensaje(
              'El cliente solo tiene $disponible envases disponibles para intercambio.',
            );
          }

          return;
        }

        envasesDevueltos = cantidad;
      }

      if (modalidad == 'PRESTAMO' || modalidad == 'COMPRA') {
        envasesDevueltos = 0;

        if (_inventarioProducto == null) {
          _mostrarMensaje('Este bidón no tiene inventario registrado.');
          return;
        }

        if (cantidad > _inventarioProducto!.stockActual) {
          _mostrarMensaje(
            'Stock insuficiente de bidones. '
            'Disponible: ${_inventarioProducto!.stockActual}.',
          );
          return;
        }
      }

      if (modalidad == 'COMPRA' &&
          _precioManualController.text.trim().isNotEmpty) {
        if (!_esAdmin) {
          _mostrarMensaje(
            'Solo un administrador puede modificar el precio de compra de un bidón.',
          );
          return;
        }

        precioManual = double.tryParse(_precioManualController.text.trim());

        if (precioManual == null || precioManual <= 0) {
          _mostrarMensaje('El precio manual debe ser mayor que cero.');
          return;
        }

        if (precioManual > producto.precioBase) {
          _mostrarMensaje(
            'El precio manual no puede superar el precio base del bidón.',
          );
          return;
        }
      }
    }

    final precioEstimado = _obtenerPrecioEstimado(producto, precioManual);

    final subtotalEstimado = precioEstimado * cantidad;

    setState(() {
      _detalles.add(
        _DetalleTemporal(
          producto: producto,
          cantidad: cantidad,
          modalidadEnvase: modalidad,
          envasesDevueltos: envasesDevueltos,
          precioManual: precioManual,
          precioEstimado: precioEstimado,
          subtotalEstimado: subtotalEstimado,
        ),
      );

      _productoId = null;
      _modalidadEnvase = null;
      _envasesDevueltos = 0;

      _inventarioProducto = null;
      _cuentaEnvases = null;
      _precioEspecial = null;

      _cantidadController.text = '1';
      _precioManualController.clear();
    });
  }

  void _eliminarDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  double get _totalEstimado {
    return _detalles.fold(
      0,
      (total, detalle) => total + detalle.subtotalEstimado,
    );
  }

  Future<void> _guardarVenta() async {
    if (_clienteId == null) {
      _mostrarMensaje('Selecciona un cliente.');
      return;
    }

    if (_detalles.isEmpty) {
      _mostrarMensaje('Agrega al menos un producto.');
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final request = VentaRequest(
        clienteId: _clienteId!,
        detalles: _detalles.map((detalle) {
          return DetalleVentaRequest(
            productoId: detalle.producto.id,
            cantidad: detalle.cantidad,
            envasesDevueltos: detalle.envasesDevueltos,
            modalidadEnvase: detalle.modalidadEnvase,
            precioManual: detalle.precioManual,
          );
        }).toList(),
      );

      final venta = await _ventaService.crear(request);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(venta);
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

    final double margin = size.width < 650
        ? 10
        : size.width < 1000
        ? 18
        : 28;

    final double dialogWidth = size.width < 1160
        ? size.width - (margin * 2)
        : 1100;

    final double dialogHeight = size.height < 860 ? size.height * 0.92 : 820;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: margin, vertical: 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Container(
          width: dialogWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildError()
                    : _buildContenido(),
              ),

              if (!_cargando && _error == null) _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 650;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pequena ? 14 : 24,
            vertical: pequena ? 12 : 18,
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
                  Icons.point_of_sale_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva venta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Registra los productos y condiciones de la venta.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Color(0xFFDC2626)),

            const SizedBox(height: 14),

            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 650
            ? 14.0
            : constraints.maxWidth < 1000
            ? 18.0
            : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                initialValue: _clienteId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Selecciona un cliente',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: _clientes.map((cliente) {
                  return DropdownMenuItem<int>(
                    value: cliente.id,
                    child: Text(
                      cliente.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _detalles.isNotEmpty ? null : _seleccionarCliente,
              ),

              const SizedBox(height: 24),

              const Text(
                'Agregar producto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 12),

              _buildSelectorProducto(),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle de la venta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  Text(
                    '${_detalles.length} producto'
                    '${_detalles.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildTablaDetalles(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectorProducto() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveFormGrid(
            largeColumns: 2,
            mediumColumns: 2,
            smallColumns: 1,
            spacing: 14,
            runSpacing: 12,
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
                      '${producto.codigo} - ${producto.descripcion}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _clienteId == null ? null : _seleccionarProducto,
              ),

              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                onChanged: _actualizarCantidad,
              ),
            ],
          ),

          if (_clienteId == null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Selecciona primero un cliente para consultar precios, inventario y envases.',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),

          if (_consultandoProducto)
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: LinearProgressIndicator(),
            ),

          if (_productoSeleccionado != null && !_consultandoProducto) ...[
            const SizedBox(height: 16),

            _buildDatosProducto(),

            if (_esBidon && _cuentaEnvases != null) ...[
              const SizedBox(height: 10),
              _buildResumenEnvases(),
            ],

            if (_esBidon &&
                _cuentaEnvases != null &&
                _modalidadEnvase != null) ...[
              const SizedBox(height: 10),
              _buildProyeccionEnvases(),
            ],

            if (_esBidon && _cuentaEnvases == null) ...[
              const SizedBox(height: 10),
              _buildAdvertenciaEnvases(),
            ],

            if (_esBidon) ...[
              const SizedBox(height: 16),
              _buildModalidadBidon(),
            ],

            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: constraints.maxWidth < 600
                        ? constraints.maxWidth
                        : 180,
                    child: ElevatedButton.icon(
                      onPressed: _consultandoProducto ? null : _agregarProducto,
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar producto'),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatosProducto() {
    final producto = _productoSeleccionado!;

    final unidad = producto.unidadMedida == 'LITRO' ? 'L' : 'ml';

    final precioAplicable = _esCompraBidon
        ? producto.precioBase
        : _precioEspecial ?? producto.precioBase;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;

          final double itemWidth;

          if (ancho < 500) {
            itemWidth = ancho;
          } else if (ancho < 800) {
            itemWidth = (ancho - 14) / 2;
          } else {
            itemWidth = (ancho - 42) / 4;
          }

          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _MiniDato(
                ancho: itemWidth,
                titulo: 'Categoría',
                valor: _formatearCategoria(producto.categoria),
              ),

              _MiniDato(
                ancho: itemWidth,
                titulo: 'Contenido',
                valor: '${_formatearContenido(producto.contenido)} $unidad',
              ),

              _MiniDato(
                ancho: itemWidth,
                titulo: 'Unidades por paquete',
                valor: producto.unidadesPorPaquete.toString(),
              ),

              _MiniDato(
                ancho: itemWidth,
                titulo: 'Precio base',
                valor: _moneda(producto.precioBase),
              ),

              if (_precioEspecial != null && !_esCompraBidon)
                _MiniDato(
                  ancho: itemWidth,
                  titulo: 'Precio especial',
                  valor: _moneda(_precioEspecial!),
                  destacado: true,
                ),

              _MiniDato(
                ancho: itemWidth,
                titulo: 'Precio aplicable',
                valor: _moneda(precioAplicable),
                destacado: true,
              ),

              if (_inventarioProducto != null)
                _MiniDato(
                  ancho: itemWidth,
                  titulo: 'Stock disponible',
                  valor: '${_inventarioProducto!.stockActual}',
                )
              else
                _MiniDato(
                  ancho: itemWidth,
                  titulo: 'Inventario',
                  valor: 'No registrado',
                  advertencia: true,
                ),

              if (producto.categoria == 'BIDON')
                _MiniDato(
                  ancho: itemWidth,
                  titulo: 'Envases del cliente',
                  valor: '${_cuentaEnvases?.cantidadTotal ?? 0}',
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResumenEnvases() {
    final cuenta = _cuentaEnvases!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Envases propios: ${cuenta.cantidadPropios}   •   '
              'Prestados: ${cuenta.cantidadPrestados}   •   '
              'Total disponible: ${cuenta.cantidadTotal}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertenciaEnvases() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFFEA580C)),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'El cliente todavía no tiene una cuenta de envases para este bidón. '
              'No podrá realizar intercambio, pero sí préstamo o compra si existe stock.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalidadBidon() {
    final campos = <Widget>[
      DropdownButtonFormField<String>(
        initialValue: _modalidadEnvase,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Modalidad de envase',
          prefixIcon: Icon(Icons.water_drop_outlined),
        ),
        items: const [
          DropdownMenuItem(value: 'INTERCAMBIO', child: Text('Intercambio')),
          DropdownMenuItem(value: 'PRESTAMO', child: Text('Préstamo')),
          DropdownMenuItem(value: 'COMPRA', child: Text('Compra')),
        ],
        onChanged: _seleccionarModalidad,
      ),
    ];

    if (_modalidadEnvase == 'INTERCAMBIO') {
      campos.add(
        InputDecorator(
          decoration: const InputDecoration(labelText: 'Envases devueltos'),
          child: Text(_envasesDevueltos.toString()),
        ),
      );
    }

    if (_esCompraBidon && _esAdmin) {
      campos.add(
        TextFormField(
          controller: _precioManualController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Precio manual',
            prefixText: 'S/ ',
            helperText: 'Máximo ${_moneda(_productoSeleccionado!.precioBase)}',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveFormGrid(
          largeColumns: 3,
          mediumColumns: 2,
          smallColumns: 1,
          spacing: 14,
          runSpacing: 12,
          children: campos,
        ),

        if (_esCompraBidon && !_esAdmin)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'La compra de bidones utilizará el precio base. '
              'Solo ADMIN puede modificarlo.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
      ],
    );
  }

  Widget _buildProyeccionEnvases() {
    final cuenta = _cuentaEnvases!;

    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;

    int propiosDespues = cuenta.cantidadPropios;

    int prestadosDespues = cuenta.cantidadPrestados;

    switch (_modalidadEnvase) {
      case 'COMPRA':
        propiosDespues += cantidad;
        break;

      case 'PRESTAMO':
        prestadosDespues += cantidad;
        break;

      case 'INTERCAMBIO':
        break;
    }

    final totalDespues = propiosDespues + prestadosDespues;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proyección de envases',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final pequena = constraints.maxWidth < 600;

              if (pequena) {
                return Column(
                  children: [
                    _SaldoEnvasesBloque(
                      titulo: 'Saldo actual',
                      propios: cuenta.cantidadPropios,
                      prestados: cuenta.cantidadPrestados,
                      total: cuenta.cantidadTotal,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Icon(
                        Icons.arrow_downward,
                        color: Color(0xFF94A3B8),
                      ),
                    ),

                    _SaldoEnvasesBloque(
                      titulo: 'Después de la operación',
                      propios: propiosDespues,
                      prestados: prestadosDespues,
                      total: totalDespues,
                      destacado: true,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _SaldoEnvasesBloque(
                      titulo: 'Saldo actual',
                      propios: cuenta.cantidadPropios,
                      prestados: cuenta.cantidadPrestados,
                      total: cuenta.cantidadTotal,
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Icon(Icons.arrow_forward, color: Color(0xFF94A3B8)),
                  ),

                  Expanded(
                    child: _SaldoEnvasesBloque(
                      titulo: 'Después de la operación',
                      propios: propiosDespues,
                      prestados: prestadosDespues,
                      total: totalDespues,
                      destacado: true,
                    ),
                  ),
                ],
              );
            },
          ),

          if (_modalidadEnvase == 'INTERCAMBIO') ...[
            const SizedBox(height: 10),

            const Text(
              'El intercambio no modifica el saldo de envases; '
              'el cliente entrega la misma cantidad que recibe.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTablaDetalles() {
    if (_detalles.isEmpty) {
      return Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Todavía no has agregado productos.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Producto')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Modalidad')),
                  DataColumn(label: Text('Precio estimado')),
                  DataColumn(label: Text('Subtotal estimado')),
                  DataColumn(label: Text('Acción')),
                ],
                rows: List.generate(_detalles.length, (index) {
                  final detalle = _detalles[index];

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 210,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detalle.producto.descripcion,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              Text(
                                detalle.producto.codigo,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      DataCell(Text(detalle.cantidad.toString())),

                      DataCell(
                        Text(_formatearModalidad(detalle.modalidadEnvase)),
                      ),

                      DataCell(Text(_moneda(detalle.precioEstimado))),

                      DataCell(
                        Text(
                          _moneda(detalle.subtotalEstimado),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      DataCell(
                        IconButton(
                          tooltip: 'Quitar producto',
                          onPressed: () {
                            _eliminarDetalle(index);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 700;

        if (pequena) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Total estimado',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 3),

                Text(
                  _moneda(_totalEstimado),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(height: 2),

                const Text(
                  'El backend validará nuevamente precios, stock y envases.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _guardando ? null : _guardarVenta,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Registrar venta'),
                ),

                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: _guardando
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: const Text('Cancelar'),
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
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total estimado',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _moneda(_totalEstimado),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),

                    const Text(
                      'El backend validará nuevamente precios, stock y envases.',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

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
                  onPressed: _guardando ? null : _guardarVenta,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Registrar venta'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatearCategoria(String categoria) {
    switch (categoria) {
      case 'BIDON':
        return 'Bidón';

      case 'BOTELLA':
        return 'Botella';

      case 'PAQUETE':
        return 'Paquete';

      default:
        return categoria;
    }
  }

  String _formatearModalidad(String? modalidad) {
    switch (modalidad) {
      case 'INTERCAMBIO':
        return 'Intercambio';

      case 'PRESTAMO':
        return 'Préstamo';

      case 'COMPRA':
        return 'Compra';

      default:
        return '-';
    }
  }

  String _formatearContenido(double contenido) {
    if (contenido == contenido.roundToDouble()) {
      return contenido.toInt().toString();
    }

    return contenido.toString();
  }
}

class _DetalleTemporal {
  final Producto producto;
  final int cantidad;

  final String? modalidadEnvase;
  final int? envasesDevueltos;

  final double? precioManual;

  final double precioEstimado;
  final double subtotalEstimado;

  const _DetalleTemporal({
    required this.producto,
    required this.cantidad,
    required this.modalidadEnvase,
    required this.envasesDevueltos,
    required this.precioManual,
    required this.precioEstimado,
    required this.subtotalEstimado,
  });
}

class _MiniDato extends StatelessWidget {
  final double ancho;

  final String titulo;
  final String valor;

  final bool destacado;
  final bool advertencia;

  const _MiniDato({
    required this.ancho,
    required this.titulo,
    required this.valor,
    this.destacado = false,
    this.advertencia = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),

          const SizedBox(height: 3),

          Text(
            valor,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: advertencia
                  ? const Color(0xFFDC2626)
                  : destacado
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaldoEnvasesBloque extends StatelessWidget {
  final String titulo;

  final int propios;
  final int prestados;
  final int total;

  final bool destacado;

  const _SaldoEnvasesBloque({
    required this.titulo,
    required this.propios,
    required this.prestados,
    required this.total,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destacado ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: destacado ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: destacado
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 10),

          _SaldoLinea(label: 'Propios', valor: propios),

          const SizedBox(height: 5),

          _SaldoLinea(label: 'Prestados', valor: prestados),

          const SizedBox(height: 8),

          const Divider(height: 1),

          const SizedBox(height: 8),

          _SaldoLinea(label: 'Total', valor: total, destacado: true),
        ],
      ),
    );
  }
}

class _SaldoLinea extends StatelessWidget {
  final String label;
  final int valor;
  final bool destacado;

  const _SaldoLinea({
    required this.label,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: destacado ? 12 : 11,
              fontWeight: destacado ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF475569),
            ),
          ),
        ),

        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: destacado ? 14 : 12,
            fontWeight: destacado ? FontWeight.w700 : FontWeight.w600,
            color: destacado
                ? const Color(0xFF2563EB)
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../clientes/models/cliente.dart';
import '../../clientes/models/pagina_clientes.dart';
import '../../clientes/services/cliente_service.dart';

import '../../productos/models/pagina_productos.dart';
import '../../productos/models/producto.dart';
import '../../productos/services/producto_service.dart';

import '../models/cliente_precio.dart';
import '../models/cliente_precio_request.dart';
import '../services/cliente_precio_service.dart';

class ClientePrecioFormDialog extends StatefulWidget {
  final ClientePrecio? precio;

  const ClientePrecioFormDialog({super.key, this.precio});

  bool get esEdicion => precio != null;

  @override
  State<ClientePrecioFormDialog> createState() =>
      _ClientePrecioFormDialogState();
}

class _ClientePrecioFormDialogState extends State<ClientePrecioFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _clienteService = ClienteService();
  final _productoService = ProductoService();
  final _precioService = ClientePrecioService();

  final _precioController = TextEditingController();

  List<Cliente> _clientes = [];
  List<Producto> _productos = [];

  int? _clienteId;
  int? _productoId;

  bool _cargando = true;
  bool _guardando = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _clienteId = widget.precio?.clienteId;
    _productoId = widget.precio?.productoId;

    if (widget.precio != null) {
      _precioController.text = widget.precio!.precio.toStringAsFixed(2);
    }

    _cargarCatalogos();
  }

  @override
  void dispose() {
    _precioController.dispose();

    super.dispose();
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

      final clientesPagina = resultados[0] as PaginaClientes;

      final productosPagina = resultados[1] as PaginaProductos;

      setState(() {
        _clientes = clientesPagina.contenido;
        _productos = productosPagina.contenido;

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

    if (_clienteId == null || _productoId == null) {
      return;
    }

    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    if (precio == null || precio <= 0) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final request = ClientePrecioRequest(
        clienteId: _clienteId!,
        productoId: _productoId!,
        precio: precio,
      );

      if (widget.esEdicion) {
        await _precioService.actualizar(widget.precio!.id, request);
      } else {
        await _precioService.crear(request);
      }

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
    final size = MediaQuery.sizeOf(context);

    final double margen;

    if (size.width < 650) {
      margen = 10;
    } else if (size.width < 900) {
      margen = 18;
    } else {
      margen = 28;
    }

    final double dialogWidth = size.width < 680
        ? size.width - (margen * 2)
        : 620;

    final double dialogHeight = size.height < 650 ? size.height * 0.92 : 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: margen, vertical: 14),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),

              Flexible(child: _buildContenido(size.width < 650)),

              if (!_cargando && _error == null) _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenido(bool pantallaPequena) {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
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
                onPressed: () {
                  setState(() {
                    _cargando = true;
                    _error = null;
                  });

                  _cargarCatalogos();
                },
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(pantallaPequena ? 14 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _clienteId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Cliente',
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
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un cliente.';
                }

                return null;
              },
              onChanged: _guardando
                  ? null
                  : (value) {
                      setState(() {
                        _clienteId = value;
                      });
                    },
            ),

            const SizedBox(height: 16),

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

            const SizedBox(height: 16),

            TextFormField(
              controller: _precioController,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Precio especial',
                prefixText: 'S/ ',
                prefixIcon: Icon(Icons.sell_outlined),
              ),
              validator: (value) {
                final precio = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );

                if (precio == null || precio <= 0) {
                  return 'El precio debe ser mayor que cero.';
                }

                return null;
              },
            ),

            const SizedBox(height: 14),

            _buildResumenSeleccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenSeleccion() {
    final cliente = _buscarCliente(_clienteId);

    final producto = _buscarProducto(_productoId);

    if (cliente == null && producto == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 19, color: Color(0xFF64748B)),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cliente != null)
                  Text(
                    'Cliente: ${cliente.nombre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                if (cliente != null && producto != null)
                  const SizedBox(height: 4),

                if (producto != null)
                  Text(
                    'Precio base actual: '
                    'S/ ${producto.precioBase.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Cliente? _buscarCliente(int? id) {
    if (id == null) {
      return null;
    }

    for (final cliente in _clientes) {
      if (cliente.id == id) {
        return cliente;
      }
    }

    return null;
  }

  Producto? _buscarProducto(int? id) {
    if (id == null) {
      return null;
    }

    for (final producto in _productos) {
      if (producto.id == id) {
        return producto;
      }
    }

    return null;
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequena = constraints.maxWidth < 500;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pequena ? 14 : 24,
            vertical: pequena ? 12 : 20,
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
                child: Icon(
                  widget.esEdicion ? Icons.edit_outlined : Icons.sell_outlined,
                  color: const Color(0xFF2563EB),
                  size: pequena ? 20 : 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.esEdicion
                          ? 'Editar precio especial'
                          : 'Nuevo precio especial',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: pequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Asigna un precio especial a un cliente para un producto.',
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
                        Navigator.of(context).pop(false);
                      },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );
      },
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
                        : Text(
                            widget.esEdicion
                                ? 'Guardar cambios'
                                : 'Registrar precio',
                          ),
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _guardando
                        ? null
                        : () {
                            Navigator.of(context).pop(false);
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
                          Navigator.of(context).pop(false);
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
                      : Text(
                          widget.esEdicion
                              ? 'Guardar cambios'
                              : 'Registrar precio',
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_form_grid.dart';

import '../../clientes/models/cliente.dart';
import '../../clientes/services/cliente_service.dart';
import '../../productos/models/producto.dart';
import '../../productos/services/producto_service.dart';

import '../models/cotizacion.dart';
import '../services/cotizacion_service.dart';

class CotizacionFormDialog extends StatefulWidget {
  final Cotizacion? cotizacion;

  const CotizacionFormDialog({super.key, this.cotizacion});

  @override
  State<CotizacionFormDialog> createState() => _CotizacionFormDialogState();
}

class _CotizacionFormDialogState extends State<CotizacionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _clienteService = ClienteService();
  final _productoService = ProductoService();
  final _cotizacionService = CotizacionService();

  final _porcentajeImpuestoController = TextEditingController(text: '18.00');

  final _condicionesPagoController = TextEditingController();
  final _plazoEntregaController = TextEditingController();
  final _observacionController = TextEditingController();

  List<Cliente> _clientes = [];
  List<Producto> _productos = [];

  final List<_DetalleCotizacionForm> _detalles = [];

  int? _clienteId;

  String _tipoPrecio = 'SIN_IGV';

  DateTime? _fechaVencimiento;

  bool _cargando = true;
  bool _guardando = false;

  String? _error;

  bool get _editando => widget.cotizacion != null;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _porcentajeImpuestoController.dispose();
    _condicionesPagoController.dispose();
    _plazoEntregaController.dispose();
    _observacionController.dispose();

    for (final detalle in _detalles) {
      detalle.dispose();
    }

    super.dispose();
  }

  Future<void> _inicializar() async {
    try {
      final paginaClientes = await _clienteService.obtenerClientes(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
      );

      final paginaProductos = await _productoService.obtenerProductos(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
      );

      if (!mounted) {
        return;
      }

      _clientes = paginaClientes.contenido;
      _productos = paginaProductos.contenido;

      if (_editando) {
        _cargarCotizacionExistente();
      } else {
        _detalles.add(_DetalleCotizacionForm());
      }

      setState(() {
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

  void _cargarCotizacionExistente() {
    final cotizacion = widget.cotizacion!;

    _clienteId = cotizacion.clienteId;
    _tipoPrecio = cotizacion.tipoPrecio;
    _fechaVencimiento = cotizacion.fechaVencimiento;

    _porcentajeImpuestoController.text = cotizacion.porcentajeImpuesto
        .toStringAsFixed(2);

    _condicionesPagoController.text = cotizacion.condicionesPago ?? '';

    _plazoEntregaController.text = cotizacion.plazoEntrega ?? '';

    _observacionController.text = cotizacion.observacion ?? '';

    for (final detalle in cotizacion.detalles) {
      final formulario = _DetalleCotizacionForm();

      formulario.productoId = detalle.productoId;

      formulario.cantidadController.text = detalle.cantidad.toString();

      formulario.precioController.text = detalle.precioUnitario.toStringAsFixed(
        2,
      );

      formulario.frecuenciaController.text =
          detalle.frecuenciaAbastecimiento ?? '';

      formulario.descripcionController.text =
          detalle.descripcionAdicional ?? '';

      formulario.tieneImagenActual = detalle.tieneImagen;

      formulario.detalleIdActual = detalle.id;

      _detalles.add(formulario);
    }

    if (_detalles.isEmpty) {
      _detalles.add(_DetalleCotizacionForm());
    }
  }

  void _agregarDetalle() {
    setState(() {
      _detalles.add(_DetalleCotizacionForm());
    });
  }

  void _eliminarDetalle(int index) {
    if (_detalles.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cotización debe contener al menos un producto.'),
        ),
      );

      return;
    }

    final detalle = _detalles.removeAt(index);

    detalle.dispose();

    setState(() {});
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();

    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaVencimiento ?? ahora.add(const Duration(days: 15)),
      firstDate: DateTime(ahora.year, ahora.month, ahora.day),
      lastDate: DateTime(ahora.year + 5),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _fechaVencimiento = fecha;
    });
  }

  Future<void> _seleccionarImagen(int index) async {
    final archivo = await FilePicker.pickFile(type: FileType.image);

    if (archivo == null) {
      return;
    }

    final bytes = await archivo.readAsBytes();

    if (!mounted) {
      return;
    }

    setState(() {
      _detalles[index].imagenBytes = bytes;

      _detalles[index].imagenNombre = archivo.name;
    });
  }

  void _quitarImagenSeleccionada(int index) {
    setState(() {
      _detalles[index].imagenBytes = null;
      _detalles[index].imagenNombre = null;
    });
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteId == null) {
      _mostrarError('Debe seleccionar un cliente.');

      return;
    }

    if (_fechaVencimiento == null) {
      _mostrarError('Debe seleccionar una fecha de vencimiento.');

      return;
    }

    if (_detalles.isEmpty) {
      _mostrarError('Debe agregar al menos un producto.');

      return;
    }

    final productosSeleccionados = <int>{};

    for (final detalle in _detalles) {
      if (detalle.productoId == null) {
        _mostrarError('Todos los detalles deben tener un producto.');

        return;
      }

      if (!productosSeleccionados.add(detalle.productoId!)) {
        _mostrarError('No puede agregar el mismo producto más de una vez.');

        return;
      }
    }

    setState(() {
      _guardando = true;
    });

    try {
      final request = <String, dynamic>{
        'clienteId': _clienteId,
        'porcentajeImpuesto': double.parse(
          _porcentajeImpuestoController.text.trim().replaceAll(',', '.'),
        ),
        'tipoPrecio': _tipoPrecio,
        'fechaVencimiento': _formatearFecha(_fechaVencimiento!),
        'condicionesPago': _textoONull(_condicionesPagoController.text),
        'plazoEntrega': _textoONull(_plazoEntregaController.text),
        'observacion': _textoONull(_observacionController.text),
        'detalles': _detalles.map((detalle) {
          return <String, dynamic>{
            'productoId': detalle.productoId,
            'cantidad': int.parse(detalle.cantidadController.text.trim()),
            'precioUnitario': double.parse(
              detalle.precioController.text.trim().replaceAll(',', '.'),
            ),
            'frecuenciaAbastecimiento': _textoONull(
              detalle.frecuenciaController.text,
            ),
            'descripcionAdicional': _textoONull(
              detalle.descripcionController.text,
            ),
          };
        }).toList(),
      };

      Cotizacion cotizacionGuardada;

      if (_editando) {
        cotizacionGuardada = await _cotizacionService.actualizar(
          widget.cotizacion!.id,
          request,
        );
      } else {
        cotizacionGuardada = await _cotizacionService.crear(request);
      }

      await _subirImagenes(cotizacionGuardada);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
      });

      _mostrarError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _subirImagenes(Cotizacion cotizacion) async {
    for (final formulario in _detalles) {
      if (formulario.imagenBytes == null ||
          formulario.imagenNombre == null ||
          formulario.productoId == null) {
        continue;
      }

      final coincidencias = cotizacion.detalles.where(
        (detalle) => detalle.productoId == formulario.productoId,
      );

      if (coincidencias.isEmpty) {
        continue;
      }

      final detalleGuardado = coincidencias.first;

      await _cotizacionService.subirImagenDetalle(
        cotizacionId: cotizacion.id,
        detalleId: detalleGuardado.id,
        bytes: formulario.imagenBytes!,
        nombreArchivo: formulario.imagenNombre!,
      );
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _formatearFecha(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');

    final mes = fecha.month.toString().padLeft(2, '0');

    final dia = fecha.day.toString().padLeft(2, '0');

    return '$anio-$mes-$dia';
  }

  String? _textoONull(String texto) {
    final valor = texto.trim();

    return valor.isEmpty ? null : valor;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final double horizontalMargin;

    if (size.width < 650) {
      horizontalMargin = 10;
    } else if (size.width < 1000) {
      horizontalMargin = 18;
    } else {
      horizontalMargin = 28;
    }

    final double dialogWidth = size.width < 1200
        ? size.width - (horizontalMargin * 2)
        : 1120;

    final double dialogHeight = size.height < 850 ? size.height * 0.92 : 820;

    final double contentPadding;

    if (size.width < 650) {
      contentPadding = 14;
    } else if (size.width < 1000) {
      contentPadding = 18;
    } else {
      contentPadding = 24;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: 16,
      ),
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
          child: _cargando
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _error != null
              ? _buildError()
              : Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildCabecera(),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(contentPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDatosPrincipales(),

                              const SizedBox(height: 24),

                              _buildCondiciones(),

                              const SizedBox(height: 26),

                              _buildTituloProductos(),

                              const SizedBox(height: 12),

                              ...List.generate(_detalles.length, _buildDetalle),

                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),

                      _buildAcciones(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),

            const SizedBox(height: 14),

            Text(_error!, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _cargando = true;
                  _error = null;
                });

                _inicializar();
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecera() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequeno = constraints.maxWidth < 650;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pequeno ? 14 : 24,
            vertical: pequeno ? 14 : 18,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
          ),
          child: Row(
            children: [
              Container(
                width: pequeno ? 38 : 44,
                height: pequeno ? 38 : 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.request_quote_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editando ? 'Editar cotización' : 'Nueva cotización',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: pequeno ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _editando
                          ? widget.cotizacion!.codigo
                          : 'Completa los datos de la propuesta comercial.',
                      maxLines: pequeno ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

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

  Widget _buildDatosPrincipales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos de la cotización',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 14),

        ResponsiveFormGrid(
          largeColumns: 4,
          mediumColumns: 2,
          smallColumns: 1,
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
              onChanged: _guardando
                  ? null
                  : (value) {
                      setState(() {
                        _clienteId = value;
                      });
                    },
              validator: (value) {
                if (value == null) {
                  return 'Seleccione un cliente.';
                }

                return null;
              },
            ),

            DropdownButtonFormField<String>(
              initialValue: _tipoPrecio,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de precio',
                prefixIcon: Icon(Icons.percent),
              ),
              items: const [
                DropdownMenuItem(value: 'SIN_IGV', child: Text('Precio + IGV')),
                DropdownMenuItem(
                  value: 'CON_IGV',
                  child: Text('Precio incluye IGV'),
                ),
              ],
              onChanged: _guardando
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _tipoPrecio = value;
                      });
                    },
            ),

            TextFormField(
              controller: _porcentajeImpuestoController,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'IGV %',
                prefixIcon: Icon(Icons.calculate_outlined),
              ),
              validator: (value) {
                final numero = double.tryParse(
                  (value ?? '').replaceAll(',', '.'),
                );

                if (numero == null || numero < 0) {
                  return 'IGV inválido.';
                }

                return null;
              },
            ),

            InkWell(
              onTap: _guardando ? null : _seleccionarFecha,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Vencimiento',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(
                  _fechaVencimiento != null
                      ? DateFormat('dd/MM/yyyy').format(_fechaVencimiento!)
                      : 'Seleccionar fecha',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _fechaVencimiento != null
                        ? null
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

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
              Icon(Icons.business_outlined, size: 19, color: Color(0xFF64748B)),

              SizedBox(width: 9),

              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Empresa emisora: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      TextSpan(
                        text:
                            'se completará automáticamente con la empresa activa.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCondiciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Condiciones comerciales',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 14),

        ResponsiveFormGrid(
          largeColumns: 3,
          mediumColumns: 2,
          smallColumns: 1,
          children: [
            TextFormField(
              controller: _condicionesPagoController,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Condiciones de pago',
                hintText: 'Ej. Crédito a 30 días',
              ),
              minLines: 2,
              maxLines: 3,
            ),

            TextFormField(
              controller: _plazoEntregaController,
              enabled: !_guardando,
              decoration: const InputDecoration(
                labelText: 'Plazo / abastecimiento',
                hintText: 'Ej. Abastecimiento semanal previa coordinación',
              ),
              minLines: 2,
              maxLines: 3,
            ),

            TextFormField(
              controller: _observacionController,
              enabled: !_guardando,
              decoration: const InputDecoration(labelText: 'Observaciones'),
              minLines: 2,
              maxLines: 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTituloProductos() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequeno = constraints.maxWidth < 650;

        final titulo = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos cotizados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),

            SizedBox(height: 3),

            Text(
              'Puedes agregar uno o varios productos con precios independientes.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        );

        final boton = OutlinedButton.icon(
          onPressed: _guardando ? null : _agregarDetalle,
          icon: const Icon(Icons.add),
          label: const Text('Agregar producto'),
        );

        if (pequeno) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titulo,

              const SizedBox(height: 12),

              SizedBox(width: double.infinity, child: boton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titulo),

            const SizedBox(width: 16),

            SizedBox(width: 170, child: boton),
          ],
        );
      },
    );
  }

  Widget _buildDetalle(int index) {
    final detalle = _detalles[index];

    final producto = _buscarProducto(detalle.productoId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  producto != null
                      ? producto.descripcion
                      : 'Producto sin seleccionar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              IconButton(
                tooltip: 'Eliminar producto',
                onPressed: _guardando
                    ? null
                    : () {
                        _eliminarDetalle(index);
                      },
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ResponsiveFormGrid(
            largeColumns: 4,
            mediumColumns: 2,
            smallColumns: 1,
            children: [
              DropdownButtonFormField<int>(
                initialValue: detalle.productoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Producto'),
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
                onChanged: _guardando
                    ? null
                    : (value) {
                        setState(() {
                          detalle.productoId = value;
                        });
                      },
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione un producto.';
                  }

                  return null;
                },
              ),

              TextFormField(
                controller: detalle.cantidadController,
                enabled: !_guardando,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
                validator: (value) {
                  final cantidad = int.tryParse(value ?? '');

                  if (cantidad == null || cantidad <= 0) {
                    return 'Cantidad inválida.';
                  }

                  return null;
                },
              ),

              TextFormField(
                controller: detalle.precioController,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Precio unitario',
                  prefixText: 'S/ ',
                  helperText: _tipoPrecio == 'CON_IGV'
                      ? 'Incluye IGV'
                      : '+ IGV',
                ),
                validator: (value) {
                  final precio = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );

                  if (precio == null || precio <= 0) {
                    return 'Precio inválido.';
                  }

                  return null;
                },
              ),

              TextFormField(
                controller: detalle.frecuenciaController,
                enabled: !_guardando,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  hintText: 'Ej. Semanal',
                ),
              ),
            ],
          ),

          if (producto != null) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Contenido: '
                '${_formatearContenido(producto.contenido)} '
                '${_formatearUnidad(producto.unidadMedida)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ),
          ],

          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final pequeno = constraints.maxWidth < 700;

              if (pequeno) {
                return Column(
                  children: [
                    TextFormField(
                      controller: detalle.descripcionController,
                      enabled: !_guardando,
                      decoration: const InputDecoration(
                        labelText: 'Descripción adicional',
                        hintText: 'Descripción que aparecerá en la cotización',
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: _buildSelectorImagen(index, detalle),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: detalle.descripcionController,
                      enabled: !_guardando,
                      decoration: const InputDecoration(
                        labelText: 'Descripción adicional',
                        hintText: 'Descripción que aparecerá en la cotización',
                      ),
                      minLines: 2,
                      maxLines: 3,
                    ),
                  ),

                  const SizedBox(width: 14),

                  SizedBox(
                    width: constraints.maxWidth < 950 ? 260 : 300,
                    child: _buildSelectorImagen(index, detalle),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorImagen(int index, _DetalleCotizacionForm detalle) {
    final tieneNueva = detalle.imagenBytes != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Imagen para el PDF',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 9),

          if (tieneNueva)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.memory(
                    detalle.imagenBytes!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    detalle.imagenNombre ?? 'Imagen seleccionada',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),

                IconButton(
                  tooltip: 'Quitar selección',
                  onPressed: _guardando
                      ? null
                      : () {
                          _quitarImagenSeleccionada(index);
                        },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            )
          else if (detalle.tieneImagenActual)
            const Row(
              children: [
                Icon(Icons.image_outlined, color: Color(0xFF15803D)),

                SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Este producto ya tiene una imagen cargada.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            )
          else
            const Text(
              'Sin imagen seleccionada.',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),

          const SizedBox(height: 9),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _guardando
                  ? null
                  : () {
                      _seleccionarImagen(index);
                    },
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                detalle.tieneImagenActual || tieneNueva
                    ? 'Cambiar imagen'
                    : 'Seleccionar imagen',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pequeno = constraints.maxWidth < 650;

        if (pequeno) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_editando) ...[
                  Text(
                    'Estado: ${widget.cotizacion!.estado}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],

                ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : _editando
                        ? 'Guardar cambios'
                        : 'Crear cotización',
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _guardando
                      ? null
                      : () {
                          Navigator.of(context).pop(false);
                        },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
          ),
          child: Row(
            children: [
              if (_editando)
                Text(
                  'Estado: ${widget.cotizacion!.estado}',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),

              const Spacer(),

              TextButton(
                onPressed: _guardando
                    ? null
                    : () {
                        Navigator.of(context).pop(false);
                      },
                child: const Text('Cancelar'),
              ),

              const SizedBox(width: 10),

              SizedBox(
                width: 175,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : _editando
                        ? 'Guardar cambios'
                        : 'Crear cotización',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatearUnidad(String unidad) {
    switch (unidad) {
      case 'MILILITRO':
        return 'ml';

      case 'LITRO':
        return 'L';

      default:
        return unidad;
    }
  }

  String _formatearContenido(double contenido) {
    if (contenido == contenido.roundToDouble()) {
      return contenido.toInt().toString();
    }

    return contenido.toString();
  }
}

class _DetalleCotizacionForm {
  int? productoId;

  final cantidadController = TextEditingController();

  final precioController = TextEditingController();

  final frecuenciaController = TextEditingController();

  final descripcionController = TextEditingController();

  Uint8List? imagenBytes;
  String? imagenNombre;

  bool tieneImagenActual = false;

  int? detalleIdActual;

  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
    frecuenciaController.dispose();
    descripcionController.dispose();
  }
}

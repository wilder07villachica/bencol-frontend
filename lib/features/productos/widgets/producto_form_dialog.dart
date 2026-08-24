import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_form_grid.dart';

import '../models/producto.dart';
import '../models/producto_request.dart';
import '../services/producto_service.dart';

class ProductoFormDialog extends StatefulWidget {
  final Producto? producto;

  const ProductoFormDialog({super.key, this.producto});

  bool get esEdicion => producto != null;

  @override
  State<ProductoFormDialog> createState() => _ProductoFormDialogState();
}

class _ProductoFormDialogState extends State<ProductoFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _productoService = ProductoService();

  late final TextEditingController _codigoController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _contenidoController;
  late final TextEditingController _unidadesController;
  late final TextEditingController _precioController;

  String _categoria = 'BIDON';
  String _unidadMedida = 'LITRO';
  String _estado = 'ACTIVO';

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    final producto = widget.producto;

    _codigoController = TextEditingController(text: producto?.codigo ?? '');

    _descripcionController = TextEditingController(
      text: producto?.descripcion ?? '',
    );

    _contenidoController = TextEditingController(
      text: producto != null ? producto.contenido.toString() : '',
    );

    _unidadesController = TextEditingController(
      text: producto != null ? producto.unidadesPorPaquete.toString() : '1',
    );

    _precioController = TextEditingController(
      text: producto != null ? producto.precioBase.toStringAsFixed(2) : '',
    );

    _categoria = producto?.categoria ?? 'BIDON';

    _unidadMedida = producto?.unidadMedida ?? 'LITRO';

    _estado = producto?.estado ?? 'ACTIVO';
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    _contenidoController.dispose();
    _unidadesController.dispose();
    _precioController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final contenido = double.tryParse(
      _contenidoController.text.trim().replaceAll(',', '.'),
    );

    final unidades = int.tryParse(_unidadesController.text.trim());

    final precio = double.tryParse(
      _precioController.text.trim().replaceAll(',', '.'),
    );

    if (contenido == null || unidades == null || precio == null) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final request = ProductoRequest(
        codigo: _codigoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoria: _categoria,
        contenido: contenido,
        unidadMedida: _unidadMedida,
        unidadesPorPaquete: unidades,
        precioBase: precio,
        estado: _estado,
      );

      if (widget.esEdicion) {
        await _productoService.actualizar(widget.producto!.id, request);
      } else {
        await _productoService.crear(request);
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

    final double dialogWidth = size.width < 710
        ? size.width - (margen * 2)
        : 650;

    final double dialogHeight = size.height < 800 ? size.height * 0.92 : 760;

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

              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(size.width < 650 ? 14 : 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ResponsiveFormGrid(
                          largeColumns: 2,
                          mediumColumns: 2,
                          smallColumns: 1,
                          spacing: 14,
                          runSpacing: 16,
                          children: [
                            TextFormField(
                              controller: _codigoController,
                              enabled: !_guardando,
                              decoration: const InputDecoration(
                                labelText: 'Código',
                                prefixIcon: Icon(Icons.qr_code_outlined),
                              ),
                              validator: (value) {
                                final texto = value?.trim() ?? '';

                                if (texto.isEmpty) {
                                  return 'El código es obligatorio.';
                                }

                                if (texto.length > 20) {
                                  return 'Máximo 20 caracteres.';
                                }

                                return null;
                              },
                            ),

                            DropdownButtonFormField<String>(
                              initialValue: _categoria,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'BIDON',
                                  child: Text('Bidón'),
                                ),
                                DropdownMenuItem(
                                  value: 'BOTELLA',
                                  child: Text('Botella'),
                                ),
                                DropdownMenuItem(
                                  value: 'PAQUETE',
                                  child: Text('Paquete'),
                                ),
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
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descripcionController,
                          enabled: !_guardando,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (value) {
                            final texto = value?.trim() ?? '';

                            if (texto.isEmpty) {
                              return 'La descripción es obligatoria.';
                            }

                            if (texto.length > 255) {
                              return 'Máximo 255 caracteres.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        ResponsiveFormGrid(
                          largeColumns: 2,
                          mediumColumns: 2,
                          smallColumns: 1,
                          spacing: 14,
                          runSpacing: 16,
                          children: [
                            TextFormField(
                              controller: _contenidoController,
                              enabled: !_guardando,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Contenido',
                                prefixIcon: Icon(Icons.water_drop_outlined),
                              ),
                              validator: (value) {
                                final numero = double.tryParse(
                                  (value ?? '').trim().replaceAll(',', '.'),
                                );

                                if (numero == null || numero <= 0) {
                                  return 'Debe ser mayor que 0.';
                                }

                                return null;
                              },
                            ),

                            DropdownButtonFormField<String>(
                              initialValue: _unidadMedida,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Unidad de medida',
                                prefixIcon: Icon(Icons.straighten_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'MILILITRO',
                                  child: Text('Mililitro'),
                                ),
                                DropdownMenuItem(
                                  value: 'LITRO',
                                  child: Text('Litro'),
                                ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        _unidadMedida = value;
                                      });
                                    },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        ResponsiveFormGrid(
                          largeColumns: 2,
                          mediumColumns: 2,
                          smallColumns: 1,
                          spacing: 14,
                          runSpacing: 16,
                          children: [
                            TextFormField(
                              controller: _unidadesController,
                              enabled: !_guardando,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Unidades por paquete',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: (value) {
                                final numero = int.tryParse(
                                  value?.trim() ?? '',
                                );

                                if (numero == null || numero < 1) {
                                  return 'Debe ser como mínimo 1.';
                                }

                                return null;
                              },
                            ),

                            TextFormField(
                              controller: _precioController,
                              enabled: !_guardando,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Precio base',
                                prefixText: 'S/ ',
                              ),
                              validator: (value) {
                                final numero = double.tryParse(
                                  (value ?? '').trim().replaceAll(',', '.'),
                                );

                                if (numero == null || numero <= 0) {
                                  return 'Debe ser mayor que 0.';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        ResponsiveFormGrid(
                          largeColumns: 2,
                          mediumColumns: 2,
                          smallColumns: 1,
                          spacing: 14,
                          runSpacing: 16,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _estado,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                prefixIcon: Icon(Icons.toggle_on_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ACTIVO',
                                  child: Text('Activo'),
                                ),
                                DropdownMenuItem(
                                  value: 'INACTIVO',
                                  child: Text('Inactivo'),
                                ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        _estado = value;
                                      });
                                    },
                            ),

                            _buildResumenProducto(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenProducto() {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 19, color: Color(0xFF64748B)),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              _categoria == 'BIDON'
                  ? 'Producto administrado como bidón.'
                  : _categoria == 'PAQUETE'
                  ? 'El stock se descontará según sus unidades por paquete.'
                  : 'Producto administrado por unidades físicas.',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ),
        ],
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
                  widget.esEdicion
                      ? Icons.edit_outlined
                      : Icons.add_box_outlined,
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
                      widget.esEdicion ? 'Editar producto' : 'Nuevo producto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: pequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      widget.esEdicion
                          ? 'Actualiza la información del producto.'
                          : 'Registra un nuevo producto en Bencol.',
                      maxLines: 2,
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
                            widget.esEdicion ? 'Guardar cambios' : 'Registrar',
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
                width: 150,
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
                          widget.esEdicion ? 'Guardar cambios' : 'Registrar',
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

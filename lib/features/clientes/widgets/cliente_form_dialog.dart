import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_form_grid.dart';

import '../models/cliente.dart';
import '../models/cliente_request.dart';
import '../services/cliente_service.dart';

class ClienteFormDialog extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormDialog({super.key, this.cliente});

  bool get esEdicion => cliente != null;

  @override
  State<ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _clienteService = ClienteService();

  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;

  String? _categoria;
  String? _estado;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();

    final cliente = widget.cliente;

    _nombreController = TextEditingController(text: cliente?.nombre ?? '');

    _direccionController = TextEditingController(
      text: cliente?.direccion ?? '',
    );

    _telefonoController = TextEditingController(text: cliente?.telefono ?? '');

    _emailController = TextEditingController(text: cliente?.email ?? '');

    _categoria = cliente?.categoria ?? 'CONSUMIDOR_FINAL';

    _estado = cliente?.estado ?? 'ACTIVO';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final request = ClienteRequest(
        nombre: _nombreController.text.trim(),
        direccion: _direccionController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        categoria: _categoria,
        estado: _estado,
      );

      if (widget.esEdicion) {
        await _clienteService.actualizar(widget.cliente!.id, request);
      } else {
        await _clienteService.crear(request);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
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

    final double dialogHeight = size.height < 760 ? size.height * 0.92 : 720;

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
                      children: [
                        TextFormField(
                          controller: _nombreController,
                          enabled: !_guardando,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es obligatorio.';
                            }

                            if (value.trim().length > 50) {
                              return 'El nombre no debe superar los 50 caracteres.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _direccionController,
                          enabled: !_guardando,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La dirección es obligatoria.';
                            }

                            if (value.trim().length > 200) {
                              return 'La dirección no debe superar los 200 caracteres.';
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
                              controller: _telefonoController,
                              enabled: !_guardando,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) {
                                final telefono = value?.trim() ?? '';

                                if (telefono.isEmpty) {
                                  return 'El teléfono es obligatorio.';
                                }

                                if (!RegExp(r'^\d{9}$').hasMatch(telefono)) {
                                  return 'Debe tener 9 dígitos.';
                                }

                                return null;
                              },
                            ),

                            TextFormField(
                              controller: _emailController,
                              enabled: !_guardando,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'El correo es obligatorio.';
                                }

                                final regex = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                );

                                if (!regex.hasMatch(email)) {
                                  return 'Correo electrónico no válido.';
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
                              initialValue: _categoria,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'DISTRIBUIDOR',
                                  child: Text('Distribuidor'),
                                ),
                                DropdownMenuItem(
                                  value: 'CONSUMIDOR_FINAL',
                                  child: Text('Consumidor final'),
                                ),
                                DropdownMenuItem(
                                  value: 'CORPORATIVO',
                                  child: Text('Corporativo'),
                                ),
                              ],
                              onChanged: _guardando
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _categoria = value;
                                      });
                                    },
                            ),

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
                                      setState(() {
                                        _estado = value;
                                      });
                                    },
                            ),
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
                      : Icons.person_add_alt_outlined,
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
                      widget.esEdicion ? 'Editar cliente' : 'Nuevo cliente',
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
                          ? 'Actualiza la información del cliente.'
                          : 'Registra un nuevo cliente en Bencol.',
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

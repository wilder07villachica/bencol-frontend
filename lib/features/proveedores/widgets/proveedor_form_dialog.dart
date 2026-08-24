import 'package:flutter/material.dart';

import '../models/proveedor.dart';
import '../models/proveedor_request.dart';
import '../services/proveedor_service.dart';

class ProveedorFormDialog extends StatefulWidget {
  final Proveedor? proveedor;

  const ProveedorFormDialog({super.key, this.proveedor});

  @override
  State<ProveedorFormDialog> createState() => _ProveedorFormDialogState();
}

class _ProveedorFormDialogState extends State<ProveedorFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _proveedorService = ProveedorService();

  late final TextEditingController _razonSocialController;

  late final TextEditingController _rucController;

  late final TextEditingController _contactoController;

  late final TextEditingController _telefonoController;

  late final TextEditingController _emailController;

  late final TextEditingController _direccionController;

  String _estado = 'ACTIVO';

  bool _guardando = false;

  bool get _editando => widget.proveedor != null;

  @override
  void initState() {
    super.initState();

    final proveedor = widget.proveedor;

    _razonSocialController = TextEditingController(
      text: proveedor?.razonSocial ?? '',
    );

    _rucController = TextEditingController(text: proveedor?.ruc ?? '');

    _contactoController = TextEditingController(
      text: proveedor?.contacto ?? '',
    );

    _telefonoController = TextEditingController(
      text: proveedor?.telefono ?? '',
    );

    _emailController = TextEditingController(text: proveedor?.email ?? '');

    _direccionController = TextEditingController(
      text: proveedor?.direccion ?? '',
    );

    _estado = proveedor?.estado ?? 'ACTIVO';
  }

  @override
  void dispose() {
    _razonSocialController.dispose();
    _rucController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();

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
      final request = ProveedorRequest(
        razonSocial: _razonSocialController.text.trim(),
        ruc: _rucController.text.trim(),
        contacto: _contactoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        direccion: _direccionController.text.trim(),
        estado: _estado,
      );

      Proveedor proveedor;

      if (_editando) {
        proveedor = await _proveedorService.actualizar(
          id: widget.proveedor!.id,
          request: request,
        );
      } else {
        proveedor = await _proveedorService.crear(request);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(proveedor);
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

    final margen = size.width < 750 ? 10.0 : 24.0;

    final width = size.width < 750 ? size.width - (margen * 2) : 700.0;

    final maxHeight = size.height < 780 ? size.height * 0.92 : 760.0;

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
        final pantallaPequena = constraints.maxWidth < 500;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: pantallaPequena ? 14 : 24,
            vertical: pantallaPequena ? 14 : 20,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
          ),
          child: Row(
            children: [
              Container(
                width: pantallaPequena ? 36 : 42,
                height: pantallaPequena ? 36 : 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _editando
                      ? Icons.edit_outlined
                      : Icons.local_shipping_outlined,
                  color: const Color(0xFF2563EB),
                  size: pantallaPequena ? 20 : 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editando ? 'Editar proveedor' : 'Nuevo proveedor',
                      style: TextStyle(
                        fontSize: pantallaPequena ? 17 : 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      _editando
                          ? 'Actualiza la información del proveedor.'
                          : 'Registra un nuevo proveedor.',
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
          TextFormField(
            controller: _razonSocialController,
            enabled: !_guardando,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'Razón social',
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              final texto = value?.trim() ?? '';

              if (texto.isEmpty) {
                return 'La razón social es obligatoria.';
              }

              return null;
            },
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _rucController,
            enabled: !_guardando,
            maxLength: 11,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'RUC',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) {
              final texto = value?.trim() ?? '';

              if (!RegExp(r'^\d{11}$').hasMatch(texto)) {
                return 'El RUC debe tener exactamente 11 dígitos.';
              }

              return null;
            },
          ),

          const SizedBox(height: 8),

          LayoutBuilder(
            builder: (context, constraints) {
              final columna = constraints.maxWidth < 560;

              if (columna) {
                return Column(
                  children: [
                    _buildContacto(),

                    const SizedBox(height: 8),

                    _buildTelefono(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildContacto()),

                  const SizedBox(width: 14),

                  Expanded(child: _buildTelefono()),
                ],
              );
            },
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            enabled: !_guardando,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final texto = value?.trim() ?? '';

              if (texto.isEmpty) {
                return null;
              }

              final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

              if (!regex.hasMatch(texto)) {
                return 'El correo electrónico no es válido.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _direccionController,
            enabled: !_guardando,
            maxLength: 255,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: _estado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Icons.toggle_on_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
              DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
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
        ],
      ),
    );
  }

  Widget _buildContacto() {
    return TextFormField(
      controller: _contactoController,
      enabled: !_guardando,
      maxLength: 100,
      decoration: const InputDecoration(
        labelText: 'Persona de contacto',
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildTelefono() {
    return TextFormField(
      controller: _telefonoController,
      enabled: !_guardando,
      maxLength: 20,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Teléfono',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    );
  }

  Widget _buildActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pantallaPequena = constraints.maxWidth < 500;

        if (pantallaPequena) {
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
                        : Text(
                            _editando ? 'Guardar cambios' : 'Crear proveedor',
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
          width: double.infinity,
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
                      : Text(_editando ? 'Guardar cambios' : 'Crear proveedor'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

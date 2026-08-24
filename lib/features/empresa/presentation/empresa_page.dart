import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/empresa.dart';
import '../models/empresa_request.dart';
import '../services/empresa_service.dart';

class EmpresaPage extends StatefulWidget {
  const EmpresaPage({super.key});

  @override
  State<EmpresaPage> createState() => _EmpresaPageState();
}

class _EmpresaPageState extends State<EmpresaPage> {
  final _formKey = GlobalKey<FormState>();

  final _empresaService = EmpresaService();

  final _rucController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _nombreComercialController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();

  Empresa? _empresa;

  Uint8List? _logoBytes;

  bool _cargando = true;
  bool _guardando = false;
  bool _procesandoLogo = false;

  String? _error;

  bool get _empresaRegistrada => _empresa != null;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  @override
  void dispose() {
    _rucController.dispose();
    _razonSocialController.dispose();
    _nombreComercialController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final empresa = await _empresaService.obtenerActiva();

      Uint8List? logo;

      if (empresa != null) {
        _llenarFormulario(empresa);

        if (empresa.tieneLogo) {
          try {
            logo = await _empresaService.obtenerLogo(empresa.id);
          } catch (_) {
            logo = null;
          }
        }
      } else {
        _limpiarFormulario();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _empresa = empresa;
        _logoBytes = logo;
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

  void _llenarFormulario(Empresa empresa) {
    _rucController.text = empresa.ruc;
    _razonSocialController.text = empresa.razonSocial;
    _nombreComercialController.text = empresa.nombreComercial ?? '';
    _direccionController.text = empresa.direccion ?? '';
    _telefonoController.text = empresa.telefono ?? '';
    _emailController.text = empresa.email ?? '';
  }

  void _limpiarFormulario() {
    _rucController.clear();
    _razonSocialController.clear();
    _nombreComercialController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _emailController.clear();
  }

  EmpresaRequest _crearRequest() {
    return EmpresaRequest(
      ruc: _rucController.text.trim(),
      razonSocial: _razonSocialController.text.trim(),
      nombreComercial: _valorOpcional(_nombreComercialController.text),
      direccion: _valorOpcional(_direccionController.text),
      telefono: _valorOpcional(_telefonoController.text),
      email: _valorOpcional(_emailController.text),
    );
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
      final request = _crearRequest();

      Empresa guardada;

      if (_empresa == null) {
        guardada = await _empresaService.crear(request);
      } else {
        guardada = await _empresaService.actualizar(
          id: _empresa!.id,
          request: request,
        );
      }

      if (!mounted) {
        return;
      }

      final eraNueva = _empresa == null;

      setState(() {
        _empresa = guardada;
      });

      if (eraNueva) {
        _mostrarMensaje(
          'Empresa registrada correctamente. Ya puedes configurar el logo.',
        );
      } else {
        _mostrarMensaje('Datos de la empresa actualizados correctamente.');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  Future<void> _seleccionarLogo() async {
    final empresa = _empresa;

    if (empresa == null) {
      _mostrarMensaje('Primero debes registrar los datos de la empresa.');

      return;
    }

    if (_procesandoLogo) {
      return;
    }

    try {
      final archivo = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );

      if (archivo == null) {
        return;
      }

      final bytes = await archivo.xFile.readAsBytes();

      if (bytes.isEmpty) {
        _mostrarMensaje('No fue posible leer la imagen seleccionada.');

        return;
      }

      if (bytes.length > 5 * 1024 * 1024) {
        _mostrarMensaje('El logo no debe superar los 5 MB.');

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _procesandoLogo = true;
      });

      final actualizada = await _empresaService.subirLogo(
        empresaId: empresa.id,
        bytes: bytes,
        nombreArchivo: archivo.name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _empresa = actualizada;
        _logoBytes = bytes;
      });

      _mostrarMensaje('Logo actualizado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    } finally {
      if (mounted) {
        setState(() {
          _procesandoLogo = false;
        });
      }
    }
  }

  Future<void> _eliminarLogo() async {
    final empresa = _empresa;

    if (empresa == null || !empresa.tieneLogo || _procesandoLogo) {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar logo'),
          content: const Text('¿Deseas eliminar el logo actual de la empresa?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    setState(() {
      _procesandoLogo = true;
    });

    try {
      final actualizada = await _empresaService.eliminarLogo(empresa.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _empresa = actualizada;
        _logoBytes = null;
      });

      _mostrarMensaje('Logo eliminado correctamente.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    } finally {
      if (mounted) {
        setState(() {
          _procesandoLogo = false;
        });
      }
    }
  }

  String? _valorOpcional(String valor) {
    final texto = valor.trim();

    return texto.isEmpty ? null : texto;
  }

  void _mostrarError(Object error) {
    _mostrarMensaje(error.toString().replaceFirst('Exception: ', ''));
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    return ResponsivePage(
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 850;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _empresaRegistrada ? 'Configuración' : 'Configurar empresa',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _empresaRegistrada
                      ? 'Administra la información institucional de la empresa.'
                      : 'Registra los datos institucionales para comenzar a utilizar el sistema.',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),

                if (!_empresaRegistrada) ...[
                  const SizedBox(height: 18),

                  _buildAvisoConfiguracionInicial(),
                ],

                const SizedBox(height: 24),

                if (compacto)
                  Column(
                    children: [
                      _buildLogoCard(),

                      const SizedBox(height: 18),

                      _buildDatosCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 300, child: _buildLogoCard()),

                      const SizedBox(width: 20),

                      Expanded(child: _buildDatosCard()),
                    ],
                  ),

                const SizedBox(height: 30),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvisoConfiguracionInicial() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 21, color: Color(0xFF2563EB)),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Todavía no existe una empresa configurada. Completa los datos obligatorios y registra la empresa. Después podrás agregar su logo.',
              style: TextStyle(color: Color(0xFF1E3A5F), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Color(0xFFDC2626)),

            const SizedBox(height: 16),

            Text(
              _error ?? 'No fue posible cargar la configuración.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    final empresa = _empresa;

    final tieneLogo = empresa?.tieneLogo ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logo de la empresa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 5),

          Text(
            _empresaRegistrada
                ? 'Se utiliza en documentos y elementos institucionales.'
                : 'Podrás configurar el logo después de registrar la empresa.',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 22),

          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7EAF0)),
            ),
            child: _procesandoLogo
                ? const Center(child: CircularProgressIndicator())
                : _logoBytes != null
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Image.memory(
                      _logoBytes!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 46,
                            color: Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _empresaRegistrada
                            ? Icons.business_outlined
                            : Icons.lock_outline,
                        size: 46,
                        color: const Color(0xFF94A3B8),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _empresaRegistrada
                            ? 'Sin logo'
                            : 'Registra primero la empresa',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
          ),

          if (empresa?.logoNombre != null &&
              empresa!.logoNombre!.isNotEmpty) ...[
            const SizedBox(height: 10),

            Text(
              empresa.logoNombre!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !_empresaRegistrada || _procesandoLogo
                  ? null
                  : _seleccionarLogo,
              icon: const Icon(Icons.upload_outlined),
              label: Text(tieneLogo ? 'Cambiar logo' : 'Subir logo'),
            ),
          ),

          if (tieneLogo) ...[
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _procesandoLogo ? null : _eliminarLogo,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar logo'),
              ),
            ),
          ],

          const SizedBox(height: 12),

          const Text(
            'PNG, JPG, JPEG o WEBP. Máximo 5 MB.',
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compacto = constraints.maxWidth < 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _empresaRegistrada
                      ? 'Datos de la empresa'
                      : 'Registrar empresa',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  _empresaRegistrada
                      ? 'Mantén actualizada la información comercial de Bencol.'
                      : 'Completa los datos para realizar la configuración inicial.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 24),

                if (compacto) ...[
                  _buildRuc(),

                  const SizedBox(height: 16),

                  _buildRazonSocial(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRuc()),

                      const SizedBox(width: 14),

                      Expanded(flex: 2, child: _buildRazonSocial()),
                    ],
                  ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _nombreComercialController,
                  maxLength: 225,
                  decoration: const InputDecoration(
                    labelText: 'Nombre comercial',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _direccionController,
                  maxLength: 255,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),

                const SizedBox(height: 8),

                if (compacto) ...[
                  _buildTelefono(),

                  const SizedBox(height: 16),

                  _buildEmail(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTelefono()),

                      const SizedBox(width: 14),

                      Expanded(child: _buildEmail()),
                    ],
                  ),

                const SizedBox(height: 26),

                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: compacto
                        ? double.infinity
                        : _empresaRegistrada
                        ? 175
                        : 190,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _empresaRegistrada
                                  ? Icons.save_outlined
                                  : Icons.add_business_outlined,
                            ),
                      label: Text(
                        _guardando
                            ? _empresaRegistrada
                                  ? 'Guardando...'
                                  : 'Registrando...'
                            : _empresaRegistrada
                            ? 'Guardar cambios'
                            : 'Registrar empresa',
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRuc() {
    return TextFormField(
      controller: _rucController,
      keyboardType: TextInputType.number,
      maxLength: 11,
      decoration: const InputDecoration(
        labelText: 'RUC',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      validator: (value) {
        final texto = value?.trim() ?? '';

        if (!RegExp(r'^\d{11}$').hasMatch(texto)) {
          return 'Debe tener 11 dígitos.';
        }

        return null;
      },
    );
  }

  Widget _buildRazonSocial() {
    return TextFormField(
      controller: _razonSocialController,
      maxLength: 225,
      decoration: const InputDecoration(
        labelText: 'Razón social',
        prefixIcon: Icon(Icons.business_outlined),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La razón social es obligatoria.';
        }

        return null;
      },
    );
  }

  Widget _buildTelefono() {
    return TextFormField(
      controller: _telefonoController,
      maxLength: 20,
      decoration: const InputDecoration(
        labelText: 'Teléfono',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
    );
  }

  Widget _buildEmail() {
    return TextFormField(
      controller: _emailController,
      maxLength: 100,
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
          return 'Correo electrónico inválido.';
        }

        return null;
      },
    );
  }
}

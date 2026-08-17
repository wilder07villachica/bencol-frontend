import 'package:flutter/material.dart';

import '../../clientes/models/cliente.dart';
import '../../clientes/services/cliente_service.dart';

import '../../productos/models/producto.dart';
import '../../productos/services/producto_service.dart';

import '../models/saldo_inicial_envase_request.dart';
import '../services/envase_service.dart';

class SaldoInicialEnvaseDialog extends StatefulWidget {
  const SaldoInicialEnvaseDialog({super.key});

  @override
  State<SaldoInicialEnvaseDialog> createState() =>
      _SaldoInicialEnvaseDialogState();
}

class _SaldoInicialEnvaseDialogState extends State<SaldoInicialEnvaseDialog> {
  final _formKey = GlobalKey<FormState>();

  final _clienteService = ClienteService();
  final _productoService = ProductoService();
  final _envaseService = EnvaseService();

  final _propiosController = TextEditingController(text: '0');

  final _prestadosController = TextEditingController(text: '0');

  final _referenciaController = TextEditingController();

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

    _cargarCatalogos();
  }

  @override
  void dispose() {
    _propiosController.dispose();
    _prestadosController.dispose();
    _referenciaController.dispose();

    super.dispose();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final clientes = await _clienteService.obtenerClientes(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
      );

      final productos = await _productoService.obtenerProductos(
        pagina: 0,
        tamanio: 100,
        estado: 'ACTIVO',
        categoria: 'BIDON',
      );

      if (!mounted) {
        return;
      }

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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_clienteId == null || _productoId == null) {
      return;
    }

    final propios = int.parse(_propiosController.text.trim());

    final prestados = int.parse(_prestadosController.text.trim());

    if (propios == 0 && prestados == 0) {
      _mostrarMensaje(
        'El saldo inicial debe contener '
        'al menos un envase.',
      );

      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      await _envaseService.registrarSaldoInicial(
        SaldoInicialEnvaseRequest(
          clienteId: _clienteId!,
          productoId: _productoId!,
          cantidadPropios: propios,
          cantidadPrestados: prestados,
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

  String? _validarEntero(String? value) {
    final numero = int.tryParse(value?.trim() ?? '');

    if (numero == null) {
      return 'Número inválido.';
    }

    if (numero < 0) {
      return 'No puede ser negativo.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pantallaPequena = size.width < 600;

    final dialogWidth = pantallaPequena ? size.width * 0.94 : 650.0;

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

              Flexible(child: _buildContenido(pantallaPequena)),

              if (!_cargando && _error == null) _buildActions(pantallaPequena),
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
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
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
      padding: EdgeInsets.all(pantallaPequena ? 18 : 24),
      child: _buildForm(),
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
              Icons.water_drop_outlined,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo inicial de envases',
                  style: TextStyle(
                    fontSize: pantallaPequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Registra los envases que el cliente ya tenía '
                  'antes de usar el sistema.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
          DropdownButtonFormField<int>(
            initialValue: _clienteId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cliente',
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: _clientes
                .map(
                  (cliente) => DropdownMenuItem<int>(
                    value: cliente.id,
                    child: Text(
                      cliente.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
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
              labelText: 'Bidón',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: _productos
                .map(
                  (producto) => DropdownMenuItem<int>(
                    value: producto.id,
                    child: Text(
                      '${producto.codigo} - '
                      '${producto.descripcion}',
                      maxLines: 1,
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
            onChanged: _guardando
                ? null
                : (value) {
                    setState(() {
                      _productoId = value;
                    });
                  },
          ),

          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final compacto = constraints.maxWidth < 450;

              final propios = TextFormField(
                controller: _propiosController,
                enabled: !_guardando,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Envases propios',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: _validarEntero,
              );

              final prestados = TextFormField(
                controller: _prestadosController,
                enabled: !_guardando,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Envases prestados',
                  prefixIcon: Icon(Icons.handshake_outlined),
                ),
                validator: _validarEntero,
              );

              if (compacto) {
                return Column(
                  children: [propios, const SizedBox(height: 16), prestados],
                );
              }

              return Row(
                children: [
                  Expanded(child: propios),

                  const SizedBox(width: 14),

                  Expanded(child: prestados),
                ],
              );
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
              hintText: 'Ej. Carga inicial de envases',
              prefixIcon: Icon(Icons.description_outlined),
              alignLabelWithHint: true,
            ),
          ),
        ],
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
          : const Text('Registrar saldo'),
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

                SizedBox(width: 155, height: 44, child: registrar),
              ],
            ),
    );
  }
}

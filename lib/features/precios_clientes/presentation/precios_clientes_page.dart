import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/services/auth_service.dart';

import '../models/cliente_precio.dart';
import '../models/pagina_precios_clientes.dart';
import '../services/cliente_precio_service.dart';
import '../widgets/cliente_precio_form_dialog.dart';

class PreciosClientesPage extends StatefulWidget {
  const PreciosClientesPage({super.key});

  @override
  State<PreciosClientesPage> createState() => _PreciosClientesPageState();
}

class _PreciosClientesPageState extends State<PreciosClientesPage> {
  final _authService = AuthService();
  final _precioService = ClientePrecioService();

  final ScrollController _tablaScrollController = ScrollController();

  final _numero = NumberFormat('#,##0.00', 'en_US');
  final _fechaFormato = DateFormat('dd/MM/yyyy HH:mm');

  AuthUser? _usuario;
  PaginaPreciosClientes? _pagina;

  bool _cargando = true;
  String? _error;

  int _paginaActual = 0;

  final int _tamanio = 20;

  @override
  void initState() {
    super.initState();

    _cargarInformacion();
  }

  @override
  void dispose() {
    _tablaScrollController.dispose();

    super.dispose();
  }

  Future<void> _cargarInformacion() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final resultados = await Future.wait([
        _authService.obtenerUsuarioActual(),

        _precioService.obtenerPrecios(pagina: _paginaActual, tamanio: _tamanio),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _usuario = resultados[0] as AuthUser;
        _pagina = resultados[1] as PaginaPreciosClientes;
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

  Future<void> _nuevoPrecio() async {
    final creado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const ClientePrecioFormDialog();
      },
    );

    if (creado != true) {
      return;
    }

    _paginaActual = 0;

    await _cargarInformacion();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Precio especial registrado correctamente.'),
      ),
    );
  }

  Future<void> _editarPrecio(ClientePrecio precio) async {
    final actualizado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ClientePrecioFormDialog(precio: precio);
      },
    );

    if (actualizado != true) {
      return;
    }

    await _cargarInformacion();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Precio especial actualizado correctamente.'),
      ),
    );
  }

  Future<void> _eliminarPrecio(ClientePrecio precio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar precio especial'),
          content: Text(
            '¿Deseas eliminar el precio especial de '
            '${precio.nombreCliente} para '
            '${precio.descripcionProducto}?',
          ),
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

    try {
      await _precioService.eliminar(precio.id);

      if (_pagina!.contenido.length == 1 && _paginaActual > 0) {
        _paginaActual--;
      }

      await _cargarInformacion();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precio especial eliminado correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _paginaAnterior() async {
    if (_pagina == null || _pagina!.primera) {
      return;
    }

    _paginaActual--;

    await _cargarInformacion();
  }

  Future<void> _paginaSiguiente() async {
    if (_pagina == null || _pagina!.ultima) {
      return;
    }

    _paginaActual++;

    await _cargarInformacion();
  }

  void _mostrarError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  String _formatearMoneda(num valor) {
    return 'S/ ${_numero.format(valor)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _pagina == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _pagina == null) {
      return _buildError();
    }

    return Stack(
      children: [
        ResponsivePage(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;

              final pantallaPequena = ancho < 750;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecera(pantallaPequena),

                  const SizedBox(height: 20),

                  Expanded(child: _buildTabla()),

                  const SizedBox(height: 12),

                  _buildPaginacion(pantallaPequena),
                ],
              );
            },
          ),
        ),

        if (_cargando)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Color(0x22FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
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

            Text(_error!, textAlign: TextAlign.center),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _cargarInformacion,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecera(bool pantallaPequena) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios especiales',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Asigna precios personalizados a clientes específicos.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevoPrecio,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo precio'),
    );

    if (pantallaPequena) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titulo,

          const SizedBox(height: 14),

          SizedBox(width: double.infinity, child: boton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: titulo),

        const SizedBox(width: 20),

        SizedBox(width: 185, child: boton),
      ],
    );
  }

  Widget _buildTabla() {
    final precios = _pagina!.contenido;

    if (precios.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No existen precios especiales registrados.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tablaReducida = constraints.maxWidth < 800;

          return Scrollbar(
            controller: _tablaScrollController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _tablaScrollController,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  primary: false,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columnSpacing: tablaReducida ? 22 : 32,
                    columns: tablaReducida
                        ? const [
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Precio')),
                            DataColumn(label: Text('Acciones')),
                          ]
                        : const [
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Precio')),
                            DataColumn(label: Text('Fecha de registro')),
                            DataColumn(label: Text('Acciones')),
                          ],
                    rows: precios.map((precio) {
                      if (tablaReducida) {
                        return _crearFilaReducida(precio);
                      }

                      return _crearFila(precio);
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _crearFilaReducida(ClientePrecio precio) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 145,
            child: Text(
              precio.nombreCliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 170,
            child: Text(
              precio.descripcionProducto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(
          Text(
            _formatearMoneda(precio.precio),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ),

        DataCell(_buildMenuAcciones(precio)),
      ],
    );
  }

  DataRow _crearFila(ClientePrecio precio) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 170,
            child: Text(
              precio.nombreCliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 220,
            child: Text(
              precio.descripcionProducto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(
          Text(
            _formatearMoneda(precio.precio),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ),

        DataCell(
          Text(
            precio.fechaCreacion != null
                ? _fechaFormato.format(precio.fechaCreacion!)
                : '-',
          ),
        ),

        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Editar precio',
                onPressed: () {
                  _editarPrecio(precio);
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),

              if (_usuario?.rol == 'ADMIN')
                IconButton(
                  tooltip: 'Eliminar precio',
                  onPressed: () {
                    _eliminarPrecio(precio);
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
  }

  Widget _buildMenuAcciones(ClientePrecio precio) {
    return PopupMenuButton<String>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (accion) {
        switch (accion) {
          case 'editar':
            _editarPrecio(precio);
            break;

          case 'eliminar':
            _eliminarPrecio(precio);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          const PopupMenuItem<String>(
            value: 'editar',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.edit_outlined),
              title: Text('Editar precio'),
            ),
          ),

          if (_usuario?.rol == 'ADMIN')
            const PopupMenuItem<String>(
              value: 'eliminar',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                title: Text(
                  'Eliminar precio',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            ),
        ];
      },
    );
  }

  Widget _buildPaginacion(bool pantallaPequena) {
    final pagina = _pagina!;

    final controles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          onPressed: pagina.primera ? null : _paginaAnterior,
          icon: const Icon(Icons.chevron_left),
        ),

        Text(
          'Página ${pagina.pagina + 1} de '
          '${pagina.totalPaginas == 0 ? 1 : pagina.totalPaginas}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),

        IconButton(
          tooltip: 'Página siguiente',
          onPressed: pagina.ultima ? null : _paginaSiguiente,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );

    if (pantallaPequena) {
      return Column(
        children: [
          Text(
            '${pagina.totalElementos} precios especiales',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 4),

          controles,
        ],
      );
    }

    return Row(
      children: [
        Text(
          '${pagina.totalElementos} precios especiales',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

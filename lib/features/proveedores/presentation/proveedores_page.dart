import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/pagina_proveedores.dart';
import '../models/proveedor.dart';
import '../services/proveedor_service.dart';
import '../widgets/proveedor_form_dialog.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  final _proveedorService = ProveedorService();

  final _buscarController = TextEditingController();
  final _tablaScrollController = ScrollController();

  PaginaProveedores? _pagina;

  Timer? _debounce;

  bool _cargando = true;
  String? _error;

  int _paginaActual = 0;
  final int _tamanio = 20;

  String? _estado;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _buscarController.dispose();
    _tablaScrollController.dispose();

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
      final pagina = await _proveedorService.obtenerProveedores(
        pagina: _paginaActual,
        tamanio: _tamanio,
        texto: _buscarController.text.trim(),
        estado: _estado,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pagina = pagina;
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

  void _buscar(String texto) {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _paginaActual = 0;

      _cargar();
    });
  }

  Future<void> _nuevoProveedor() async {
    final proveedor = await showDialog<Proveedor>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const ProveedorFormDialog();
      },
    );

    if (proveedor == null) {
      return;
    }

    _paginaActual = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proveedor registrado correctamente.')),
    );
  }

  Future<void> _editarProveedor(Proveedor proveedor) async {
    final actualizado = await showDialog<Proveedor>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ProveedorFormDialog(proveedor: proveedor);
      },
    );

    if (actualizado == null) {
      return;
    }

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Proveedor actualizado correctamente.')),
    );
  }

  Future<void> _paginaAnterior() async {
    if (_pagina == null || _pagina!.primera) {
      return;
    }

    _paginaActual--;

    await _cargar();
  }

  Future<void> _paginaSiguiente() async {
    if (_pagina == null || _pagina!.ultima) {
      return;
    }

    _paginaActual++;

    await _cargar();
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

                  _buildFiltros(pantallaPequena),

                  const SizedBox(height: 16),

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

            ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
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
          'Proveedores',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Gestiona proveedores para las compras de Bencol.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevoProveedor,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo proveedor'),
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

        SizedBox(width: 170, child: boton),
      ],
    );
  }

  Widget _buildFiltros(bool pantallaPequena) {
    final buscar = TextField(
      controller: _buscarController,
      onChanged: _buscar,
      decoration: const InputDecoration(
        hintText: 'Buscar por razón social o RUC...',
        prefixIcon: Icon(Icons.search),
      ),
    );

    final estado = DropdownButtonFormField<String?>(
      initialValue: _estado,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'ACTIVO', child: Text('Activo')),
        DropdownMenuItem(value: 'INACTIVO', child: Text('Inactivo')),
      ],
      onChanged: (value) {
        setState(() {
          _estado = value;
        });

        _paginaActual = 0;

        _cargar();
      },
    );

    if (pantallaPequena) {
      return Column(children: [buscar, const SizedBox(height: 10), estado]);
    }

    return Row(
      children: [
        Expanded(child: buscar),

        const SizedBox(width: 14),

        SizedBox(width: 180, child: estado),
      ],
    );
  }

  Widget _buildTabla() {
    final proveedores = _pagina?.contenido ?? const <Proveedor>[];

    if (proveedores.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No hay proveedores registrados.',
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
          final tablaReducida = constraints.maxWidth < 900;

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
                    columnSpacing: tablaReducida ? 20 : 30,
                    horizontalMargin: 18,
                    columns: tablaReducida
                        ? const [
                            DataColumn(label: Text('Proveedor')),
                            DataColumn(label: Text('RUC')),
                            DataColumn(label: Text('Teléfono')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ]
                        : const [
                            DataColumn(label: Text('Razón social')),
                            DataColumn(label: Text('RUC')),
                            DataColumn(label: Text('Contacto')),
                            DataColumn(label: Text('Teléfono')),
                            DataColumn(label: Text('Correo')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ],
                    rows: proveedores.map((proveedor) {
                      if (tablaReducida) {
                        return _crearFilaReducida(proveedor);
                      }

                      return _crearFilaCompleta(proveedor);
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

  DataRow _crearFilaReducida(Proveedor proveedor) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proveedor.razonSocial,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                if (proveedor.contacto != null &&
                    proveedor.contacto!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      proveedor.contacto!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        DataCell(Text(proveedor.ruc)),

        DataCell(Text(proveedor.telefono ?? '-')),

        DataCell(_EstadoProveedorBadge(estado: proveedor.estado)),

        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (accion) {
              if (accion == 'editar') {
                _editarProveedor(proveedor);
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'editar',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar proveedor'),
                  ),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }

  DataRow _crearFilaCompleta(Proveedor proveedor) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 200,
            child: Text(
              proveedor.razonSocial,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        DataCell(Text(proveedor.ruc)),

        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              proveedor.contacto ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(Text(proveedor.telefono ?? '-')),

        DataCell(
          SizedBox(
            width: 190,
            child: Text(
              proveedor.email ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(_EstadoProveedorBadge(estado: proveedor.estado)),

        DataCell(
          IconButton(
            tooltip: 'Editar proveedor',
            onPressed: () {
              _editarProveedor(proveedor);
            },
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ),
      ],
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
            '${pagina.totalElementos} proveedores',
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
          '${pagina.totalElementos} proveedores',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _EstadoProveedorBadge extends StatelessWidget {
  final String estado;

  const _EstadoProveedorBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'ACTIVO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: activo ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}

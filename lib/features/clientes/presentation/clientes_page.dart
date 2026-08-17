import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/cliente.dart';
import '../models/pagina_clientes.dart';
import '../services/cliente_service.dart';
import '../widgets/cliente_form_dialog.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _clienteService = ClienteService();

  final _buscarController = TextEditingController();

  PaginaClientes? _paginaClientes;

  bool _cargando = true;
  String? _error;

  int _paginaActual = 0;

  final int _tamanio = 20;

  String? _estado;
  String? _categoria;

  @override
  void initState() {
    super.initState();

    _cargarInformacion();
  }

  @override
  void dispose() {
    _buscarController.dispose();

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
      final pagina = await _clienteService.obtenerClientes(
        pagina: _paginaActual,
        tamanio: _tamanio,
        texto: _buscarController.text.trim(),
        estado: _estado,
        categoria: _categoria,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _paginaClientes = pagina;
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

  Future<void> _buscar() async {
    _paginaActual = 0;

    await _cargarInformacion();
  }

  Future<void> _limpiarFiltros() async {
    setState(() {
      _buscarController.clear();
      _estado = null;
      _categoria = null;
      _paginaActual = 0;
    });

    await _cargarInformacion();
  }

  Future<void> _paginaAnterior() async {
    if (_paginaClientes == null || _paginaClientes!.primera) {
      return;
    }

    _paginaActual--;

    await _cargarInformacion();
  }

  Future<void> _paginaSiguiente() async {
    if (_paginaClientes == null || _paginaClientes!.ultima) {
      return;
    }

    _paginaActual++;

    await _cargarInformacion();
  }

  Future<void> _nuevoCliente() async {
    final creado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const ClienteFormDialog();
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
      const SnackBar(content: Text('Cliente registrado correctamente.')),
    );
  }

  Future<void> _editarCliente(Cliente cliente) async {
    final actualizado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ClienteFormDialog(cliente: cliente);
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
      const SnackBar(content: Text('Cliente actualizado correctamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _paginaClientes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _paginaClientes == null) {
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

                  _buildFiltros(),

                  const SizedBox(height: 18),

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
          'Gestión de clientes',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Consulta y administra los clientes registrados.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevoCliente,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo cliente'),
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

        SizedBox(width: 160, child: boton),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;

          if (ancho < 650) {
            return Column(
              children: [
                _buildBuscar(),

                const SizedBox(height: 10),

                _buildEstado(),

                const SizedBox(height: 10),

                _buildCategoria(),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _buscar,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      width: 48,
                      child: IconButton(
                        tooltip: 'Limpiar filtros',
                        onPressed: _limpiarFiltros,
                        icon: const Icon(Icons.filter_alt_off_outlined),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          if (ancho < 950) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildBuscar()),

                    const SizedBox(width: 12),

                    Expanded(child: _buildEstado()),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildCategoria()),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 125,
                      child: ElevatedButton.icon(
                        onPressed: _buscar,
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar'),
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton(
                      tooltip: 'Limpiar filtros',
                      onPressed: _limpiarFiltros,
                      icon: const Icon(Icons.filter_alt_off_outlined),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 4, child: _buildBuscar()),

              const SizedBox(width: 14),

              Expanded(flex: 2, child: _buildEstado()),

              const SizedBox(width: 14),

              Expanded(flex: 2, child: _buildCategoria()),

              const SizedBox(width: 14),

              SizedBox(
                width: 125,
                child: ElevatedButton.icon(
                  onPressed: _buscar,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Limpiar filtros',
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBuscar() {
    return TextField(
      controller: _buscarController,
      onSubmitted: (_) {
        _buscar();
      },
      decoration: const InputDecoration(
        hintText: 'Buscar cliente...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _buildEstado() {
    return DropdownButtonFormField<String?>(
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

        _buscar();
      },
    );
  }

  Widget _buildCategoria() {
    return DropdownButtonFormField<String?>(
      initialValue: _categoria,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Categoría'),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todas')),
        DropdownMenuItem(value: 'DISTRIBUIDOR', child: Text('Distribuidor')),
        DropdownMenuItem(
          value: 'CONSUMIDOR_FINAL',
          child: Text('Consumidor final'),
        ),
        DropdownMenuItem(value: 'CORPORATIVO', child: Text('Corporativo')),
      ],
      onChanged: (value) {
        setState(() {
          _categoria = value;
        });

        _buscar();
      },
    );
  }

  Widget _buildTabla() {
    final clientes = _paginaClientes!.contenido;

    if (clientes.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No se encontraron clientes.',
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

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columnSpacing: tablaReducida ? 20 : 30,
                  columns: tablaReducida
                      ? const [
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ]
                      : const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Dirección')),
                          DataColumn(label: Text('Teléfono')),
                          DataColumn(label: Text('Correo')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                  rows: clientes.map((cliente) {
                    if (tablaReducida) {
                      return _crearFilaClienteReducida(cliente);
                    }

                    return _crearFilaCliente(cliente);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _crearFilaClienteReducida(Cliente cliente) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              cliente.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        DataCell(Text(cliente.telefono.isEmpty ? '-' : cliente.telefono)),

        DataCell(_CategoriaCliente(categoria: cliente.categoria)),

        DataCell(_EstadoCliente(estado: cliente.estado)),

        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (accion) {
              if (accion == 'editar') {
                _editarCliente(cliente);
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar cliente'),
                  ),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }

  DataRow _crearFilaCliente(Cliente cliente) {
    return DataRow(
      cells: [
        DataCell(Text(cliente.id.toString())),

        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              cliente.nombre,
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
              cliente.direccion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(Text(cliente.telefono.isEmpty ? '-' : cliente.telefono)),

        DataCell(
          SizedBox(
            width: 190,
            child: Text(
              cliente.email.isEmpty ? '-' : cliente.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(_CategoriaCliente(categoria: cliente.categoria)),

        DataCell(_EstadoCliente(estado: cliente.estado)),

        DataCell(
          IconButton(
            tooltip: 'Editar cliente',
            onPressed: () {
              _editarCliente(cliente);
            },
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginacion(bool pantallaPequena) {
    final pagina = _paginaClientes!;

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
            '${pagina.totalElementos} clientes',
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
          '${pagina.totalElementos} clientes',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _EstadoCliente extends StatelessWidget {
  final String? estado;

  const _EstadoCliente({required this.estado});

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'ACTIVO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado ?? '-',
        style: TextStyle(
          color: activo ? const Color(0xFF15803D) : const Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoriaCliente extends StatelessWidget {
  final String? categoria;

  const _CategoriaCliente({required this.categoria});

  String _formatearCategoria() {
    switch (categoria) {
      case 'DISTRIBUIDOR':
        return 'Distribuidor';

      case 'CONSUMIDOR_FINAL':
        return 'Consumidor final';

      case 'CORPORATIVO':
        return 'Corporativo';

      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_formatearCategoria(), style: const TextStyle(fontSize: 12));
  }
}

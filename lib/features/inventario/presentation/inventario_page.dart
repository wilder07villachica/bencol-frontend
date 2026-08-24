import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/inventario.dart';
import '../models/pagina_inventarios.dart';
import '../services/inventario_service.dart';

import '../widgets/historial_inventario_dialog.dart';
import '../widgets/inventario_form_dialog.dart';
import '../widgets/movimiento_inventario_dialog.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final _inventarioService = InventarioService();

  final ScrollController _tablaScrollController = ScrollController();

  PaginaInventarios? _pagina;

  bool _cargando = true;
  String? _error;

  int _paginaActual = 0;
  final int _tamanio = 20;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  @override
  void dispose() {
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
      final pagina = await _inventarioService.obtenerInventarios(
        pagina: _paginaActual,
        tamanio: _tamanio,
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

  Future<void> _nuevoInventario() async {
    final creado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const InventarioFormDialog();
      },
    );

    if (creado != true) {
      return;
    }

    _paginaActual = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventario creado correctamente.')),
    );
  }

  Future<void> _movimiento(Inventario inventario) async {
    final registrado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return MovimientoInventarioDialog(inventario: inventario);
      },
    );

    if (registrado != true) {
      return;
    }

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movimiento registrado correctamente.')),
    );
  }

  Future<void> _historial(Inventario inventario) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return HistorialInventarioDialog(inventario: inventario);
      },
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
              final pantallaPequena = constraints.maxWidth < 750;

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
          'Control de inventario',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Consulta existencias y registra entradas o salidas.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevoInventario,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo inventario'),
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

        SizedBox(width: 175, child: boton),
      ],
    );
  }

  Widget _buildTabla() {
    final inventarios = _pagina!.contenido;

    if (inventarios.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No hay inventarios registrados.',
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
          final tablaReducida = constraints.maxWidth < 850;

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
                    columns: tablaReducida
                        ? const [
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ]
                        : const [
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Producto')),
                            DataColumn(label: Text('Stock actual')),
                            DataColumn(label: Text('Mínimo')),
                            DataColumn(label: Text('Máximo')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Acciones')),
                          ],
                    rows: inventarios.map((inventario) {
                      if (tablaReducida) {
                        return _crearFilaReducida(inventario);
                      }

                      return _crearFilaCompleta(inventario);
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

  DataRow _crearFilaReducida(Inventario inventario) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            inventario.codigoProducto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        DataCell(
          SizedBox(
            width: 170,
            child: Text(
              inventario.descripcionProducto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(
          Text(
            inventario.stockActual.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        DataCell(_StockBadge(inventario: inventario)),

        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (accion) {
              switch (accion) {
                case 'movimiento':
                  _movimiento(inventario);
                  break;

                case 'historial':
                  _historial(inventario);
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'movimiento',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.swap_vert),
                    title: Text('Registrar movimiento'),
                  ),
                ),

                PopupMenuItem<String>(
                  value: 'historial',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.history),
                    title: Text('Ver historial'),
                  ),
                ),
              ];
            },
          ),
        ),
      ],
    );
  }

  DataRow _crearFilaCompleta(Inventario inventario) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            inventario.codigoProducto,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        DataCell(
          SizedBox(
            width: 230,
            child: Text(
              inventario.descripcionProducto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(
          Text(
            inventario.stockActual.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        DataCell(Text(inventario.stockMinimo?.toString() ?? '-')),

        DataCell(Text(inventario.stockMaximo?.toString() ?? '-')),

        DataCell(_StockBadge(inventario: inventario)),

        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Registrar movimiento',
                onPressed: () {
                  _movimiento(inventario);
                },
                icon: const Icon(Icons.swap_vert, size: 20),
              ),

              IconButton(
                tooltip: 'Ver historial',
                onPressed: () {
                  _historial(inventario);
                },
                icon: const Icon(Icons.history, size: 20),
              ),
            ],
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
            '${pagina.totalElementos} inventarios',
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
          '${pagina.totalElementos} inventarios',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Inventario inventario;

  const _StockBadge({required this.inventario});

  @override
  Widget build(BuildContext context) {
    final minimo = inventario.stockMinimo ?? 0;

    final sinStock = inventario.stockActual == 0;

    final bajo = !sinStock && inventario.stockActual <= minimo;

    final texto = sinStock
        ? 'SIN STOCK'
        : bajo
        ? 'STOCK BAJO'
        : 'NORMAL';

    final fondo = sinStock
        ? const Color(0xFFFEE2E2)
        : bajo
        ? const Color(0xFFFFF7ED)
        : const Color(0xFFDCFCE7);

    final color = sinStock
        ? const Color(0xFFB91C1C)
        : bajo
        ? const Color(0xFFEA580C)
        : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

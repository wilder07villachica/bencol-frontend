import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/compra.dart';
import '../models/pagina_compras.dart';
import '../services/compra_service.dart';
import '../widgets/compra_form_dialog.dart';

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  final _compraService = CompraService();

  final _buscarController = TextEditingController();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  PaginaCompras? _pagina;

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

    super.dispose();
  }

  String _moneda(num valor) {
    return 'S/ ${_numero.format(valor)}';
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final pagina = await _compraService.obtenerCompras(
        pagina: _paginaActual,
        tamanio: _tamanio,
        codigo: _buscarController.text.trim(),
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

  Future<void> _nuevaCompra() async {
    final compra = await showDialog<Compra>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const CompraFormDialog();
      },
    );

    if (compra == null) {
      return;
    }

    _paginaActual = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra registrada correctamente.')),
    );
  }

  Future<void> _verDetalle(Compra compra) async {
    try {
      final actualizada = await _compraService.obtenerPorId(compra.id);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return _DetalleCompraDialog(compra: actualizada);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _anularCompra(Compra compra) async {
    if (compra.estado == 'ANULADA') {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular compra'),
          content: Text(
            '¿Seguro que deseas anular la compra '
            '${compra.codigo}?\n\n'
            'El backend revertirá el inventario y '
            'anulará la cuenta por pagar, siempre que '
            'la compra no tenga pagos registrados.',
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
              child: const Text('Anular'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _compraService.anular(compra.id);

      await _cargar();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra anulada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  void _mostrarError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
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

              final pequena = ancho < 720;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecera(pequena),

                  const SizedBox(height: 20),

                  _buildFiltros(pequena),

                  const SizedBox(height: 16),

                  Expanded(child: _buildTabla()),

                  const SizedBox(height: 12),

                  _buildPaginacion(pequena),
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

  Widget _buildCabecera(bool pequena) {
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compras',
          style: TextStyle(
            fontSize: pequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Registra compras y entradas de inventario.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevaCompra,
      icon: const Icon(Icons.add),
      label: const Text('Nueva compra'),
    );

    if (pequena) {
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

        SizedBox(width: 165, child: boton),
      ],
    );
  }

  Widget _buildFiltros(bool pequena) {
    final buscar = TextField(
      controller: _buscarController,
      onChanged: _buscar,
      decoration: const InputDecoration(
        hintText: 'Buscar por código de compra...',
        prefixIcon: Icon(Icons.search),
      ),
    );

    final estado = DropdownButtonFormField<String?>(
      initialValue: _estado,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'REGISTRADA', child: Text('Registrada')),
        DropdownMenuItem(value: 'ANULADA', child: Text('Anulada')),
      ],
      onChanged: (value) {
        setState(() {
          _estado = value;
        });

        _paginaActual = 0;

        _cargar();
      },
    );

    if (pequena) {
      return Column(children: [buscar, const SizedBox(height: 10), estado]);
    }

    return Row(
      children: [
        Expanded(child: buscar),

        const SizedBox(width: 14),

        SizedBox(width: 190, child: estado),
      ],
    );
  }

  Widget _buildTabla() {
    final compras = _pagina?.contenido ?? const <Compra>[];

    if (compras.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No hay compras registradas.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

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
          final reducida = constraints.maxWidth < 880;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columnSpacing: reducida ? 20 : 30,
                  columns: reducida
                      ? const [
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Proveedor')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ]
                      : const [
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Proveedor')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Usuario')),
                          DataColumn(label: Text('Acciones')),
                        ],
                  rows: compras.map((compra) {
                    final anulada = compra.estado == 'ANULADA';

                    if (reducida) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              compra.codigo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 170,
                              child: Text(
                                compra.razonSocialProveedor,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              _moneda(compra.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          DataCell(_EstadoCompraBadge(estado: compra.estado)),

                          DataCell(_buildAcciones(compra, compacto: true)),
                        ],
                      );
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            compra.codigo,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              compra.razonSocialProveedor,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            _moneda(compra.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),

                        DataCell(_EstadoCompraBadge(estado: compra.estado)),

                        DataCell(
                          Text(
                            compra.fechaCreacion != null
                                ? formatoFecha.format(compra.fechaCreacion!)
                                : '-',
                          ),
                        ),

                        DataCell(Text(compra.creadoPor ?? '-')),

                        DataCell(_buildAcciones(compra, anulada: anulada)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAcciones(Compra compra, {bool compacto = false, bool? anulada}) {
    final estaAnulada = anulada ?? compra.estado == 'ANULADA';

    if (compacto) {
      return PopupMenuButton<String>(
        tooltip: 'Acciones',
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (accion) {
          switch (accion) {
            case 'ver':
              _verDetalle(compra);
              break;

            case 'anular':
              _anularCompra(compra);
              break;
          }
        },
        itemBuilder: (context) {
          return [
            const PopupMenuItem(
              value: 'ver',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.visibility_outlined),
                title: Text('Ver detalle'),
              ),
            ),

            if (!estaAnulada)
              const PopupMenuItem(
                value: 'anular',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Anular compra'),
                ),
              ),
          ];
        },
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Ver detalle',
          onPressed: () {
            _verDetalle(compra);
          },
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),

        IconButton(
          tooltip: estaAnulada ? 'Compra anulada' : 'Anular compra',
          onPressed: estaAnulada
              ? null
              : () {
                  _anularCompra(compra);
                },
          icon: const Icon(Icons.cancel_outlined, size: 20),
        ),
      ],
    );
  }

  Widget _buildPaginacion(bool pequena) {
    final pagina = _pagina!;

    final controles = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          onPressed: pagina.primera
              ? null
              : () async {
                  _paginaActual--;

                  await _cargar();
                },
          icon: const Icon(Icons.chevron_left),
        ),

        Text(
          'Página ${pagina.pagina + 1} de '
          '${pagina.totalPaginas == 0 ? 1 : pagina.totalPaginas}',
          style: const TextStyle(fontSize: 12),
        ),

        IconButton(
          tooltip: 'Página siguiente',
          onPressed: pagina.ultima
              ? null
              : () async {
                  _paginaActual++;

                  await _cargar();
                },
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );

    if (pequena) {
      return Column(
        children: [
          Text(
            '${pagina.totalElementos} compras',
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
          '${pagina.totalElementos} compras',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _EstadoCompraBadge extends StatelessWidget {
  final String estado;

  const _EstadoCompraBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final registrada = estado == 'REGISTRADA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: registrada ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: registrada ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }
}

class _DetalleCompraDialog extends StatelessWidget {
  final Compra compra;

  const _DetalleCompraDialog({required this.compra});

  String _moneda(num valor) {
    final numero = NumberFormat('#,##0.00', 'en_US');

    return 'S/ ${numero.format(valor)}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final pequena = size.width < 720;

    final ancho = size.width < 1000 ? size.width * 0.92 : 900.0;

    final altoMaximo = size.height * 0.90;

    final formatoFecha = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(pequena ? 12 : 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho, maxHeight: altoMaximo),
        child: Container(
          width: ancho,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildHeader(context, pequena),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(pequena ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResumen(pequena, formatoFecha),

                      const SizedBox(height: 22),

                      const Text(
                        'Productos comprados',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildProductos(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool pequena) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: pequena ? 16 : 24,
        vertical: pequena ? 14 : 20,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        children: [
          Container(
            width: pequena ? 38 : 42,
            height: pequena ? 38 : 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compra.codigo,
                  style: TextStyle(
                    fontSize: pequena ? 17 : 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  compra.razonSocialProveedor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          _EstadoCompraBadge(estado: compra.estado),

          const SizedBox(width: 6),

          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(bool pequena, DateFormat formatoFecha) {
    final datos = [
      _DatoCompra(titulo: 'Subtotal', valor: _moneda(compra.subtotal)),
      _DatoCompra(
        titulo: 'Total',
        valor: _moneda(compra.total),
        destacado: true,
      ),
      _DatoCompra(titulo: 'Registrado por', valor: compra.creadoPor ?? '-'),
      _DatoCompra(
        titulo: 'Fecha',
        valor: compra.fechaCreacion != null
            ? formatoFecha.format(compra.fechaCreacion!)
            : '-',
      ),
    ];

    if (pequena) {
      return Column(
        children: [
          for (int i = 0; i < datos.length; i++) ...[
            SizedBox(width: double.infinity, child: datos[i]),
            if (i != datos.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: datos[0]),
        const SizedBox(width: 12),
        Expanded(child: datos[1]),
        const SizedBox(width: 12),
        Expanded(child: datos[2]),
        const SizedBox(width: 12),
        Expanded(child: datos[3]),
      ],
    );
  }

  Widget _buildProductos() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE7EAF0)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Producto')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Costo unitario')),
                  DataColumn(label: Text('Subtotal')),
                ],
                rows: compra.detalles.map((detalle) {
                  return DataRow(
                    cells: [
                      DataCell(Text(detalle.codigoProducto)),

                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            detalle.descripcionProducto,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      DataCell(Text(detalle.cantidad.toString())),

                      DataCell(Text(_moneda(detalle.costoUnitario))),

                      DataCell(
                        Text(
                          _moneda(detalle.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatoCompra extends StatelessWidget {
  final String titulo;
  final String valor;
  final bool destacado;

  const _DatoCompra({
    required this.titulo,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destacado ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 4),

          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: destacado ? const Color(0xFF2563EB) : null,
            ),
          ),
        ],
      ),
    );
  }
}

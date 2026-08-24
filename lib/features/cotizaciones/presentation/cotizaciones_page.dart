import 'dart:async';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/cotizacion.dart';
import '../models/pagina_cotizaciones.dart';
import '../services/cotizacion_service.dart';

import '../widgets/cotizacion_detalle_dialog.dart';
import '../widgets/cotizacion_form_dialog.dart';

class CotizacionesPage extends StatefulWidget {
  const CotizacionesPage({super.key});

  @override
  State<CotizacionesPage> createState() => _CotizacionesPageState();
}

class _CotizacionesPageState extends State<CotizacionesPage> {
  final _cotizacionService = CotizacionService();

  final _buscarController = TextEditingController();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  PaginaCotizaciones? _pagina;

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
      final pagina = await _cotizacionService.obtenerCotizaciones(
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

  Future<void> _nuevaCotizacion() async {
    final creada = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const CotizacionFormDialog();
      },
    );

    if (creada != true) {
      return;
    }

    _paginaActual = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cotización registrada correctamente.')),
    );
  }

  Future<void> _verDetalle(Cotizacion cotizacion) async {
    try {
      final actualizada = await _cotizacionService.obtenerPorId(cotizacion.id);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return CotizacionDetalleDialog(cotizacion: actualizada);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _editar(Cotizacion cotizacion) async {
    if (cotizacion.estado != 'BORRADOR') {
      return;
    }

    try {
      final actualizada = await _cotizacionService.obtenerPorId(cotizacion.id);

      if (!mounted) {
        return;
      }

      final editada = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return CotizacionFormDialog(cotizacion: actualizada);
        },
      );

      if (editada != true) {
        return;
      }

      await _cargar();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización actualizada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _emitir(Cotizacion cotizacion) async {
    if (cotizacion.estado != 'BORRADOR') {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Emitir cotización'),
          content: Text(
            '¿Deseas emitir la cotización '
            '${cotizacion.codigo}?\n\n'
            'Después de emitirla ya no podrá ser modificada.',
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
              child: const Text('Emitir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _cotizacionService.emitir(cotizacion.id);

      await _cargar();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización emitida correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _anular(Cotizacion cotizacion) async {
    if (cotizacion.estado == 'ANULADA') {
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular cotización'),
          content: Text(
            '¿Seguro que deseas anular la cotización '
            '${cotizacion.codigo}?',
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
      await _cotizacionService.anular(cotizacion.id);

      await _cargar();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización anulada correctamente.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _descargarPdf(Cotizacion cotizacion) async {
    try {
      final bytes = await _cotizacionService.obtenerPdf(cotizacion.id);

      await FileSaver.instance.saveAs(
        name: cotizacion.codigo,
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
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

    return ResponsivePage(
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
          'Cotizaciones',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Crea y administra propuestas comerciales para clientes.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(pantallaPequena ? double.infinity : 170, 44),
      ),
      onPressed: _nuevaCotizacion,
      icon: const Icon(Icons.add),
      label: const Text('Nueva cotización'),
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

        const SizedBox(width: 18),

        SizedBox(width: 180, child: boton),
      ],
    );
  }

  Widget _buildFiltros(bool pantallaPequena) {
    final buscar = TextField(
      controller: _buscarController,
      onChanged: _buscar,
      decoration: const InputDecoration(
        hintText: 'Buscar por código de cotización...',
        prefixIcon: Icon(Icons.search),
      ),
    );

    final estado = DropdownButtonFormField<String?>(
      initialValue: _estado,
      decoration: const InputDecoration(labelText: 'Estado'),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'BORRADOR', child: Text('Borrador')),
        DropdownMenuItem(value: 'EMITIDA', child: Text('Emitida')),
        DropdownMenuItem(value: 'ANULADA', child: Text('Anulada')),
      ],
      onChanged: (value) {
        _estado = value;
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

        SizedBox(width: 190, child: estado),
      ],
    );
  }

  Widget _buildTabla() {
    final cotizaciones = _pagina?.contenido ?? const <Cotizacion>[];

    if (cotizaciones.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No hay cotizaciones registradas.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final formatoFecha = DateFormat('dd/MM/yyyy');

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
          final usarTablaReducida = constraints.maxWidth < 900;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: usarTablaReducida ? 20 : 32,
                  horizontalMargin: 18,
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columns: usarTablaReducida
                      ? const [
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ]
                      : const [
                          DataColumn(label: Text('Código')),
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Productos')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('IGV')),
                          DataColumn(label: Text('Vencimiento')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                  rows: cotizaciones.map((cotizacion) {
                    if (usarTablaReducida) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              cotizacion.codigo,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Text(
                                cotizacion.nombreCliente,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              _moneda(cotizacion.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          DataCell(
                            _EstadoCotizacionBadge(estado: cotizacion.estado),
                          ),

                          DataCell(_buildAcciones(cotizacion, compacto: true)),
                        ],
                      );
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            cotizacion.codigo,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 170,
                            child: Text(
                              cotizacion.nombreCliente,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(Text(cotizacion.detalles.length.toString())),

                        DataCell(
                          Text(
                            _moneda(cotizacion.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),

                        DataCell(
                          Text(
                            cotizacion.tipoPrecio == 'CON_IGV'
                                ? 'Incluido'
                                : '+ ${cotizacion.porcentajeImpuesto.toStringAsFixed(0)}%',
                          ),
                        ),

                        DataCell(
                          Text(
                            cotizacion.fechaVencimiento != null
                                ? formatoFecha.format(
                                    cotizacion.fechaVencimiento!,
                                  )
                                : '-',
                          ),
                        ),

                        DataCell(
                          _EstadoCotizacionBadge(estado: cotizacion.estado),
                        ),

                        DataCell(_buildAcciones(cotizacion)),
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

  Widget _buildAcciones(Cotizacion cotizacion, {bool compacto = false}) {
    final borrador = cotizacion.estado == 'BORRADOR';

    final anulada = cotizacion.estado == 'ANULADA';

    if (compacto) {
      return PopupMenuButton<String>(
        tooltip: 'Acciones',
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (accion) {
          switch (accion) {
            case 'ver':
              _verDetalle(cotizacion);
              break;

            case 'editar':
              _editar(cotizacion);
              break;

            case 'pdf':
              _descargarPdf(cotizacion);
              break;

            case 'emitir':
              _emitir(cotizacion);
              break;

            case 'anular':
              _anular(cotizacion);
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

            if (borrador)
              const PopupMenuItem(
                value: 'editar',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Editar'),
                ),
              ),

            const PopupMenuItem(
              value: 'pdf',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.picture_as_pdf_outlined),
                title: Text('Descargar PDF'),
              ),
            ),

            if (borrador)
              const PopupMenuItem(
                value: 'emitir',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.send_outlined),
                  title: Text('Emitir'),
                ),
              ),

            if (!anulada)
              const PopupMenuItem(
                value: 'anular',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('Anular'),
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
            _verDetalle(cotizacion);
          },
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),

        IconButton(
          tooltip: borrador
              ? 'Editar cotización'
              : 'Solo los borradores pueden editarse',
          onPressed: borrador
              ? () {
                  _editar(cotizacion);
                }
              : null,
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),

        IconButton(
          tooltip: 'Descargar PDF',
          onPressed: () {
            _descargarPdf(cotizacion);
          },
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
        ),

        IconButton(
          tooltip: borrador ? 'Emitir cotización' : 'Cotización ya procesada',
          onPressed: borrador
              ? () {
                  _emitir(cotizacion);
                }
              : null,
          icon: const Icon(Icons.send_outlined, size: 20),
        ),

        IconButton(
          tooltip: anulada ? 'Cotización anulada' : 'Anular cotización',
          onPressed: anulada
              ? null
              : () {
                  _anular(cotizacion);
                },
          icon: const Icon(Icons.cancel_outlined, size: 20),
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

    if (pantallaPequena) {
      return Column(
        children: [
          Text(
            '${pagina.totalElementos} cotizaciones',
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
          '${pagina.totalElementos} cotizaciones',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _EstadoCotizacionBadge extends StatelessWidget {
  final String estado;

  const _EstadoCotizacionBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color color;

    switch (estado) {
      case 'BORRADOR':
        fondo = const Color(0xFFF1F5F9);
        color = const Color(0xFF475569);
        break;

      case 'EMITIDA':
        fondo = const Color(0xFFDCFCE7);
        color = const Color(0xFF15803D);
        break;

      case 'ANULADA':
        fondo = const Color(0xFFFEE2E2);
        color = const Color(0xFFB91C1C);
        break;

      default:
        fondo = const Color(0xFFF1F5F9);
        color = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../../auth/models/auth_user.dart';
import '../../auth/services/auth_service.dart';

import '../models/pagina_ventas.dart';
import '../models/venta.dart';
import '../services/venta_service.dart';
import '../widgets/venta_detalle_dialog.dart';
import '../widgets/venta_form_dialog.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  final _authService = AuthService();
  final _ventaService = VentaService();

  final _codigoController = TextEditingController();

  final _tablaScrollController = ScrollController();

  final _numero = NumberFormat('#,##0.00', 'en_US');
  final _fechaFormato = DateFormat('dd/MM/yyyy');

  AuthUser? _usuario;
  PaginaVentas? _paginaVentas;

  bool _cargando = true;
  String? _error;

  int _paginaActual = 0;
  final int _tamanio = 20;

  String? _estado;

  DateTime? _desde;
  DateTime? _hasta;

  @override
  void initState() {
    super.initState();

    _cargarInformacion();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _tablaScrollController.dispose();

    super.dispose();
  }

  String _formatearMoneda(num valor) {
    if (valor < 0) {
      return '-S/ ${_numero.format(valor.abs())}';
    }

    return 'S/ ${_numero.format(valor)}';
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

        _ventaService.obtenerVentas(
          pagina: _paginaActual,
          tamanio: _tamanio,
          codigo: _codigoController.text.trim(),
          estado: _estado,
          desde: _desde,
          hasta: _hasta,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _usuario = resultados[0] as AuthUser;
        _paginaVentas = resultados[1] as PaginaVentas;
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
      _codigoController.clear();

      _estado = null;
      _desde = null;
      _hasta = null;

      _paginaActual = 0;
    });

    await _cargarInformacion();
  }

  Future<void> _paginaAnterior() async {
    if (_paginaVentas == null || _paginaVentas!.primera) {
      return;
    }

    _paginaActual--;

    await _cargarInformacion();
  }

  Future<void> _paginaSiguiente() async {
    if (_paginaVentas == null || _paginaVentas!.ultima) {
      return;
    }

    _paginaActual++;

    await _cargarInformacion();
  }

  Future<void> _seleccionarDesde() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _desde ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _desde = fecha;

      if (_hasta != null && _desde!.isAfter(_hasta!)) {
        _hasta = null;
      }
    });
  }

  Future<void> _seleccionarHasta() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _hasta ?? _desde ?? DateTime.now(),
      firstDate: _desde ?? DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null) {
      return;
    }

    setState(() {
      _hasta = fecha;
    });
  }

  Future<void> _nuevaVenta() async {
    if (_usuario == null) {
      return;
    }

    final venta = await showDialog<Venta>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return VentaFormDialog(usuario: _usuario!);
      },
    );

    if (venta == null) {
      return;
    }

    _paginaActual = 0;

    await _cargarInformacion();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Venta ${venta.codigo} registrada correctamente.'),
      ),
    );
  }

  Future<void> _verVenta(Venta venta) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return VentaDetalleDialog(venta: venta);
      },
    );
  }

  Future<void> _anularVenta(Venta venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Anular venta'),
          content: Text(
            '¿Deseas anular la venta ${venta.codigo}?\n\n'
            'Esta operación revertirá el inventario, '
            'los movimientos de envases y la cuenta por cobrar '
            'si la venta todavía puede ser anulada.',
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
      await _ventaService.anular(venta.id);

      await _cargarInformacion();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venta ${venta.codigo} anulada correctamente.')),
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
    if (_cargando && _paginaVentas == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _paginaVentas == null) {
      return _buildError();
    }

    return Stack(
      children: [
        ResponsivePage(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;
              final pequena = ancho < 750;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecera(pequena),

                  const SizedBox(height: 20),

                  _buildFiltros(),

                  const SizedBox(height: 18),

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

            ElevatedButton(
              onPressed: _cargarInformacion,
              child: const Text('Reintentar'),
            ),
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
          'Gestión de ventas',
          style: TextStyle(
            fontSize: pequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Consulta, registra y administra las ventas de Bencol.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevaVenta,
      icon: const Icon(Icons.add),
      label: const Text('Nueva venta'),
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
                _buildBuscarCodigo(),

                const SizedBox(height: 10),

                _buildEstado(),

                const SizedBox(height: 10),

                _FechaField(
                  label: 'Desde',
                  fecha: _desde,
                  formato: _fechaFormato,
                  onTap: _seleccionarDesde,
                ),

                const SizedBox(height: 10),

                _FechaField(
                  label: 'Hasta',
                  fecha: _hasta,
                  formato: _fechaFormato,
                  onTap: _seleccionarHasta,
                ),

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

          if (ancho < 1000) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildBuscarCodigo()),

                    const SizedBox(width: 12),

                    Expanded(child: _buildEstado()),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _FechaField(
                        label: 'Desde',
                        fecha: _desde,
                        formato: _fechaFormato,
                        onTap: _seleccionarDesde,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _FechaField(
                        label: 'Hasta',
                        fecha: _hasta,
                        formato: _fechaFormato,
                        onTap: _seleccionarHasta,
                      ),
                    ),

                    const SizedBox(width: 12),

                    SizedBox(
                      width: 115,
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
              Expanded(flex: 3, child: _buildBuscarCodigo()),

              const SizedBox(width: 12),

              Expanded(flex: 2, child: _buildEstado()),

              const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: _FechaField(
                  label: 'Desde',
                  fecha: _desde,
                  formato: _fechaFormato,
                  onTap: _seleccionarDesde,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                flex: 2,
                child: _FechaField(
                  label: 'Hasta',
                  fecha: _hasta,
                  formato: _fechaFormato,
                  onTap: _seleccionarHasta,
                ),
              ),

              const SizedBox(width: 12),

              SizedBox(
                width: 115,
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

  Widget _buildBuscarCodigo() {
    return TextField(
      controller: _codigoController,
      onSubmitted: (_) {
        _buscar();
      },
      decoration: const InputDecoration(
        hintText: 'Buscar código de venta...',
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
        DropdownMenuItem(value: 'EMITIDA', child: Text('Emitida')),
        DropdownMenuItem(value: 'ANULADA', child: Text('Anulada')),
      ],
      onChanged: (value) {
        setState(() {
          _estado = value;
        });
      },
    );
  }

  Widget _buildTabla() {
    final ventas = _paginaVentas!.contenido;

    if (ventas.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No se encontraron ventas.',
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
          final reducida = constraints.maxWidth < 900;

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
                    columnSpacing: reducida ? 20 : 28,
                    horizontalMargin: 18,
                    columns: reducida
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
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Usuario')),
                            DataColumn(label: Text('Acciones')),
                          ],
                    rows: ventas.map((venta) {
                      if (reducida) {
                        return _crearFilaVentaReducida(venta);
                      }

                      return _crearFilaVenta(venta);
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

  DataRow _crearFilaVentaReducida(Venta venta) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            venta.codigo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 140,
            child: Text(
              venta.nombreCliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(
          Text(
            _formatearMoneda(venta.total),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        DataCell(_EstadoVentaBadge(estado: venta.estado)),

        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Acciones',
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (accion) {
              switch (accion) {
                case 'ver':
                  _verVenta(venta);
                  break;

                case 'anular':
                  _anularVenta(venta);
                  break;
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'ver',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.visibility_outlined),
                    title: Text('Ver detalle'),
                  ),
                ),

                if (venta.estado == 'EMITIDA')
                  const PopupMenuItem<String>(
                    value: 'anular',
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.cancel_outlined,
                        color: Color(0xFFDC2626),
                      ),
                      title: Text('Anular venta'),
                    ),
                  ),
              ];
            },
          ),
        ),
      ],
    );
  }

  DataRow _crearFilaVenta(Venta venta) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            venta.codigo,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 160,
            child: Text(
              venta.nombreCliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        DataCell(Text(venta.detalles.length.toString())),

        DataCell(
          Text(
            _formatearMoneda(venta.total),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        DataCell(_EstadoVentaBadge(estado: venta.estado)),

        DataCell(
          Text(
            venta.fechaCreacion != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(venta.fechaCreacion!)
                : '-',
          ),
        ),

        DataCell(Text(venta.creadoPor ?? '-')),

        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Ver detalle',
                onPressed: () {
                  _verVenta(venta);
                },
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),

              if (venta.estado == 'EMITIDA')
                IconButton(
                  tooltip: 'Anular venta',
                  onPressed: () {
                    _anularVenta(venta);
                  },
                  icon: const Icon(
                    Icons.cancel_outlined,
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

  Widget _buildPaginacion(bool pequena) {
    final pagina = _paginaVentas!;

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

    if (pequena) {
      return Column(
        children: [
          Text(
            '${pagina.totalElementos} ventas',
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
          '${pagina.totalElementos} ventas',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _EstadoVentaBadge extends StatelessWidget {
  final String estado;

  const _EstadoVentaBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final emitida = estado == 'EMITIDA';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emitida ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        emitida ? 'EMITIDA' : 'ANULADA',
        style: TextStyle(
          color: emitida ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FechaField extends StatelessWidget {
  final String label;
  final DateTime? fecha;
  final DateFormat formato;
  final VoidCallback onTap;

  const _FechaField({
    required this.label,
    required this.fecha,
    required this.formato,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          fecha != null ? formato.format(fecha!) : 'Seleccionar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fecha != null
                ? const Color(0xFF0F172A)
                : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

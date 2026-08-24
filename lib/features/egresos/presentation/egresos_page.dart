import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/egreso.dart';
import '../models/pagina_egresos.dart';
import '../services/egreso_service.dart';
import '../widgets/egreso_form_dialog.dart';

class EgresosPage extends StatefulWidget {
  const EgresosPage({super.key});

  @override
  State<EgresosPage> createState() => _EgresosPageState();
}

class _EgresosPageState extends State<EgresosPage> {
  final _egresoService = EgresoService();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  PaginaEgresos? _pagina;

  bool _cargando = true;
  String? _error;

  int _paginaActual = 0;
  final int _tamanio = 20;

  String? _categoria;

  @override
  void initState() {
    super.initState();

    _cargar();
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
      final pagina = await _egresoService.obtenerEgresos(
        pagina: _paginaActual,
        tamanio: _tamanio,
        categoria: _categoria,
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

  Future<void> _nuevoEgreso() async {
    final egreso = await showDialog<Egreso>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const EgresoFormDialog();
      },
    );

    if (egreso == null) {
      return;
    }

    _paginaActual = 0;

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Egreso registrado correctamente.')),
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

              final pantallaPequena = ancho < 700;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecera(pantallaPequena),

                  SizedBox(height: pantallaPequena ? 16 : 22),

                  _buildFiltros(pantallaPequena),

                  SizedBox(height: pantallaPequena ? 14 : 18),

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

            SizedBox(
              width: 130,
              child: ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
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
          'Egresos',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Control de gastos operativos.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _nuevoEgreso,
      icon: const Icon(Icons.add),
      label: const Text('Nuevo egreso'),
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

        SizedBox(width: 165, child: boton),
      ],
    );
  }

  Widget _buildFiltros(bool pantallaPequena) {
    final dropdown = DropdownButtonFormField<String?>(
      initialValue: _categoria,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todas')),
        DropdownMenuItem(value: 'COMBUSTIBLE', child: Text('Combustible')),
        DropdownMenuItem(value: 'MOVILIDAD', child: Text('Movilidad')),
        DropdownMenuItem(value: 'SERVICIOS', child: Text('Servicios')),
        DropdownMenuItem(value: 'MANTENIMIENTO', child: Text('Mantenimiento')),
        DropdownMenuItem(value: 'INSUMOS', child: Text('Insumos')),
        DropdownMenuItem(value: 'PERSONAL', child: Text('Personal')),
        DropdownMenuItem(value: 'OTRO', child: Text('Otro')),
      ],
      onChanged: (value) async {
        setState(() {
          _categoria = value;
          _paginaActual = 0;
        });

        await _cargar();
      },
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(pantallaPequena ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: pantallaPequena
          ? dropdown
          : Row(
              children: [
                const Text(
                  'Filtrar egresos',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(width: 16),

                SizedBox(width: 240, child: dropdown),
              ],
            ),
    );
  }

  Widget _buildTabla() {
    final egresos = _pagina?.contenido ?? const <Egreso>[];

    if (egresos.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No hay egresos registrados.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final fecha = DateFormat('dd/MM/yyyy HH:mm');

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

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columnSpacing: tablaReducida ? 22 : 32,
                  horizontalMargin: 18,
                  columns: tablaReducida
                      ? const [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Concepto')),
                          DataColumn(label: Text('Monto')),
                        ]
                      : const [
                          DataColumn(label: Text('Fecha')),
                          DataColumn(label: Text('Categoría')),
                          DataColumn(label: Text('Concepto')),
                          DataColumn(label: Text('Monto')),
                          DataColumn(label: Text('Referencia')),
                          DataColumn(label: Text('Usuario')),
                        ],
                  rows: egresos.map((egreso) {
                    if (tablaReducida) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              egreso.fechaEgreso != null
                                  ? DateFormat(
                                      'dd/MM/yy',
                                    ).format(egreso.fechaEgreso!)
                                  : '-',
                            ),
                          ),

                          DataCell(
                            _CategoriaEgresoBadge(categoria: egreso.categoria),
                          ),

                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                egreso.concepto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              _moneda(egreso.monto),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            egreso.fechaEgreso != null
                                ? fecha.format(egreso.fechaEgreso!)
                                : '-',
                          ),
                        ),

                        DataCell(
                          _CategoriaEgresoBadge(categoria: egreso.categoria),
                        ),

                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Text(
                              egreso.concepto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(
                          Text(
                            _moneda(egreso.monto),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),

                        DataCell(
                          SizedBox(
                            width: 160,
                            child: Text(
                              egreso.referencia ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),

                        DataCell(Text(egreso.registradoPor ?? '-')),
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
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
            '${pagina.totalElementos} egresos',
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
          '${pagina.totalElementos} egresos',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _CategoriaEgresoBadge extends StatelessWidget {
  final String categoria;

  const _CategoriaEgresoBadge({required this.categoria});

  String _formatearCategoria() {
    switch (categoria) {
      case 'COMBUSTIBLE':
        return 'Combustible';

      case 'MOVILIDAD':
        return 'Movilidad';

      case 'SERVICIOS':
        return 'Servicios';

      case 'MANTENIMIENTO':
        return 'Mantenimiento';

      case 'INSUMOS':
        return 'Insumos';

      case 'PERSONAL':
        return 'Personal';

      case 'OTRO':
        return 'Otro';

      default:
        return categoria.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatearCategoria(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}

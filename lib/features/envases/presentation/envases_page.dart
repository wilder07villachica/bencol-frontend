import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_page.dart';

import '../models/cuenta_envases.dart';
import '../services/envase_service.dart';
import '../widgets/movimiento_envase_dialog.dart';
import '../widgets/movimientos_envase_dialog.dart';
import '../widgets/saldo_inicial_envase_dialog.dart';

class EnvasesPage extends StatefulWidget {
  const EnvasesPage({super.key});

  @override
  State<EnvasesPage> createState() => _EnvasesPageState();
}

class _EnvasesPageState extends State<EnvasesPage> {
  final _envaseService = EnvaseService();

  List<CuentaEnvases> _cuentas = [];

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      final cuentas = await _envaseService.obtenerCuentas();

      if (!mounted) {
        return;
      }

      setState(() {
        _cuentas = cuentas;
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

  Future<void> _abrirSaldoInicial() async {
    final registrado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const SaldoInicialEnvaseDialog();
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
      const SnackBar(content: Text('Saldo inicial registrado correctamente.')),
    );
  }

  Future<void> _abrirHistorial(CuentaEnvases cuenta) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return MovimientosEnvaseDialog(cuenta: cuenta);
      },
    );
  }

  Future<void> _gestionarCuenta(CuentaEnvases cuenta) async {
    if (cuenta.cantidadPrestados <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta cuenta no tiene envases prestados pendientes.'),
        ),
      );

      return;
    }

    final registrado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return MovimientoEnvaseDialog(cuenta: cuenta);
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
      const SnackBar(
        content: Text('Operación de envases registrada correctamente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando && _cuentas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _cuentas.isEmpty) {
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

                  _buildResumen(),

                  SizedBox(height: pantallaPequena ? 16 : 20),

                  Expanded(child: _buildTabla()),
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
          'Control de envases',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Consulta envases propios y prestados por cliente.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );

    final boton = ElevatedButton.icon(
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
      onPressed: _abrirSaldoInicial,
      icon: const Icon(Icons.add),
      label: const Text('Saldo inicial'),
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

  Widget _buildResumen() {
    final propios = _cuentas.fold<int>(
      0,
      (total, cuenta) => total + cuenta.cantidadPropios,
    );

    final prestados = _cuentas.fold<int>(
      0,
      (total, cuenta) => total + cuenta.cantidadPrestados,
    );

    final total = _cuentas.fold<int>(
      0,
      (total, cuenta) => total + cuenta.cantidadTotal,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        final columnas = ancho >= 1000
            ? 4
            : ancho >= 550
            ? 2
            : 1;

        final proporcion = columnas == 1
            ? 3.4
            : columnas == 2
            ? 2.7
            : 2.4;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columnas,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: proporcion,
          children: [
            _ResumenCard(
              titulo: 'Envases propios',
              valor: propios.toString(),
              icono: Icons.inventory_2_outlined,
            ),

            _ResumenCard(
              titulo: 'Envases prestados',
              valor: prestados.toString(),
              icono: Icons.handshake_outlined,
            ),

            _ResumenCard(
              titulo: 'Total registrados',
              valor: total.toString(),
              icono: Icons.water_drop_outlined,
            ),

            _ResumenCard(
              titulo: 'Cuentas de clientes',
              valor: _cuentas.length.toString(),
              icono: Icons.people_outline,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabla() {
    if (_cuentas.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7EAF0)),
        ),
        child: const Center(
          child: Text(
            'No hay cuentas de envases registradas.',
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

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFF8FAFC),
                  ),
                  columnSpacing: tablaReducida ? 22 : 30,
                  horizontalMargin: 18,
                  columns: tablaReducida
                      ? const [
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Prestados')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Acciones')),
                        ]
                      : const [
                          DataColumn(label: Text('Cliente')),
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Propios')),
                          DataColumn(label: Text('Prestados')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Acciones')),
                        ],
                  rows: _cuentas.map((cuenta) {
                    if (tablaReducida) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Text(
                                cuenta.nombreCliente,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                cuenta.descripcionProducto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              cuenta.cantidadPrestados.toString(),
                              style: TextStyle(
                                fontWeight: cuenta.cantidadPrestados > 0
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: cuenta.cantidadPrestados > 0
                                    ? const Color(0xFFEA580C)
                                    : null,
                              ),
                            ),
                          ),

                          DataCell(
                            Text(
                              cuenta.cantidadTotal.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          DataCell(_buildAcciones(cuenta, compacto: true)),
                        ],
                      );
                    }

                    return _crearFila(cuenta);
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _crearFila(CuentaEnvases cuenta) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              cuenta.nombreCliente,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        DataCell(
          SizedBox(
            width: 220,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cuenta.descripcionProducto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  cuenta.codigoProducto,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),

        DataCell(Text(cuenta.cantidadPropios.toString())),

        DataCell(
          Text(
            cuenta.cantidadPrestados.toString(),
            style: TextStyle(
              fontWeight: cuenta.cantidadPrestados > 0
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: cuenta.cantidadPrestados > 0
                  ? const Color(0xFFEA580C)
                  : null,
            ),
          ),
        ),

        DataCell(
          Text(
            cuenta.cantidadTotal.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        DataCell(_EstadoEnvaseBadge(prestados: cuenta.cantidadPrestados)),

        DataCell(_buildAcciones(cuenta)),
      ],
    );
  }

  Widget _buildAcciones(CuentaEnvases cuenta, {bool compacto = false}) {
    if (compacto) {
      return PopupMenuButton<String>(
        tooltip: 'Acciones',
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (accion) {
          switch (accion) {
            case 'historial':
              _abrirHistorial(cuenta);
              break;

            case 'gestionar':
              _gestionarCuenta(cuenta);
              break;
          }
        },
        itemBuilder: (context) {
          return const [
            PopupMenuItem(
              value: 'historial',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.history),
                title: Text('Ver historial'),
              ),
            ),

            PopupMenuItem(
              value: 'gestionar',
              child: ListTile(
                dense: true,
                leading: Icon(Icons.settings_outlined),
                title: Text('Gestionar envases'),
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
          tooltip: 'Ver historial',
          onPressed: () {
            _abrirHistorial(cuenta);
          },
          icon: const Icon(Icons.history, size: 20),
        ),

        IconButton(
          tooltip: 'Gestionar envases',
          onPressed: () {
            _gestionarCuenta(cuenta);
          },
          icon: const Icon(Icons.settings_outlined, size: 20),
        ),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 21, color: const Color(0xFF2563EB)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoEnvaseBadge extends StatelessWidget {
  final int prestados;

  const _EstadoEnvaseBadge({required this.prestados});

  @override
  Widget build(BuildContext context) {
    final tienePrestados = prestados > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tienePrestados
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tienePrestados ? 'CON PRÉSTAMOS' : 'SIN PRÉSTAMOS',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: tienePrestados
              ? const Color(0xFFEA580C)
              : const Color(0xFF15803D),
        ),
      ),
    );
  }
}

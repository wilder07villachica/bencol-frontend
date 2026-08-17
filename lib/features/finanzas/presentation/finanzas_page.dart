import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cuenta_cobrar.dart';
import '../models/cuenta_pagar.dart';
import '../models/pagina_cuentas_cobrar.dart';
import '../models/pagina_cuentas_pagar.dart';
import '../models/resumen_cuentas_pagar.dart';
import '../models/resumen_financiero.dart';

import '../services/cuenta_cobrar_service.dart';
import '../services/cuenta_pagar_service.dart';

import '../widgets/registrar_pago_dialog.dart';
import '../widgets/registrar_pago_proveedor_dialog.dart';

import '../widgets/detalle_cuenta_cobrar_dialog.dart';
import '../widgets/detalle_cuenta_pagar_dialog.dart';

class FinanzasPage extends StatefulWidget {
  const FinanzasPage({super.key});

  @override
  State<FinanzasPage> createState() => _FinanzasPageState();
}

class _FinanzasPageState extends State<FinanzasPage> {
  final _cuentaCobrarService = CuentaCobrarService();
  final _cuentaPagarService = CuentaPagarService();

  final _numero = NumberFormat('#,##0.00', 'en_US');

  PaginaCuentasCobrar? _cuentasCobrar;
  PaginaCuentasPagar? _cuentasPagar;

  ResumenFinanciero? _resumenCobrar;
  ResumenCuentasPagar? _resumenPagar;

  bool _cargando = true;
  String? _error;

  bool _mostrarCobrar = true;

  int _paginaCobrar = 0;
  int _paginaPagar = 0;

  final int _tamanio = 20;

  String? _estadoCobrar;
  String? _estadoPagar;

  @override
  void initState() {
    super.initState();

    _cargar();
  }

  String _moneda(num valor) {
    return 'S/ ${_numero.format(valor)}';
  }

  bool get _sinDatosActuales {
    if (_mostrarCobrar) {
      return _cuentasCobrar == null || _resumenCobrar == null;
    }

    return _cuentasPagar == null || _resumenPagar == null;
  }

  Future<void> _cargar() async {
    if (mounted) {
      setState(() {
        _cargando = true;
        _error = null;
      });
    }

    try {
      if (_mostrarCobrar) {
        final resultados = await Future.wait([
          _cuentaCobrarService.obtenerCuentas(
            pagina: _paginaCobrar,
            tamanio: _tamanio,
            estado: _estadoCobrar,
          ),
          _cuentaCobrarService.obtenerResumen(),
        ]);

        if (!mounted) {
          return;
        }

        setState(() {
          _cuentasCobrar = resultados[0] as PaginaCuentasCobrar;
          _resumenCobrar = resultados[1] as ResumenFinanciero;
          _cargando = false;
        });

        return;
      }

      final resultados = await Future.wait([
        _cuentaPagarService.obtenerCuentas(
          pagina: _paginaPagar,
          tamanio: _tamanio,
          estado: _estadoPagar,
        ),
        _cuentaPagarService.obtenerResumen(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _cuentasPagar = resultados[0] as PaginaCuentasPagar;
        _resumenPagar = resultados[1] as ResumenCuentasPagar;
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

  Future<void> _cambiarSeccion(bool cobrar) async {
    if (_mostrarCobrar == cobrar) {
      return;
    }

    setState(() {
      _mostrarCobrar = cobrar;
      _error = null;
    });

    await _cargar();
  }

  Future<void> _registrarPago(CuentaCobrar cuenta) async {
    final resultado = await showDialog<CuentaCobrar>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RegistrarPagoDialog(cuenta: cuenta);
      },
    );

    if (resultado == null) {
      return;
    }

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pago registrado correctamente.')),
    );
  }

  Future<void> _registrarPagoProveedor(CuentaPagar cuenta) async {
    final resultado = await showDialog<CuentaPagar>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return RegistrarPagoProveedorDialog(cuenta: cuenta);
      },
    );

    if (resultado == null) {
      return;
    }

    await _cargar();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pago al proveedor registrado correctamente.'),
      ),
    );
  }

  Future<void> _verDetalleCobrar(CuentaCobrar cuenta) async {
    try {
      final actualizada = await _cuentaCobrarService.obtenerPorId(cuenta.id);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return DetalleCuentaCobrarDialog(cuenta: actualizada);
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarError(error);
    }
  }

  Future<void> _verDetallePagar(CuentaPagar cuenta) async {
    try {
      final actualizada = await _cuentaPagarService.obtenerPorId(cuenta.id);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return DetalleCuentaPagarDialog(cuenta: actualizada);
        },
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
    if (_cargando && _sinDatosActuales) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _sinDatosActuales) {
      return _buildError();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        final pantallaPequena = ancho < 750;

        final paddingHorizontal = pantallaPequena ? 16.0 : 28.0;
        final paddingVertical = pantallaPequena ? 16.0 : 22.0;

        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal,
                vertical: paddingVertical,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCabecera(pantallaPequena),

                  const SizedBox(height: 14),

                  _buildTabs(pantallaPequena),

                  const SizedBox(height: 14),

                  if (_mostrarCobrar)
                    _buildResumenCobrar()
                  else
                    _buildResumenPagar(),

                  const SizedBox(height: 14),

                  _buildFiltros(pantallaPequena),

                  const SizedBox(height: 12),

                  Expanded(
                    child: _mostrarCobrar
                        ? _buildTablaCobrar(ancho)
                        : _buildTablaPagar(ancho),
                  ),

                  const SizedBox(height: 8),

                  _buildPaginacion(pantallaPequena),
                ],
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
      },
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
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finanzas',
          style: TextStyle(
            fontSize: pantallaPequena ? 22 : 26,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Control de cuentas por cobrar y pagar.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildTabs(bool pantallaPequena) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: pantallaPequena
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TabFinanzas(
                  texto: 'Cuentas por cobrar',
                  seleccionado: _mostrarCobrar,
                  expandido: true,
                  onTap: () {
                    _cambiarSeccion(true);
                  },
                ),

                const SizedBox(height: 4),

                _TabFinanzas(
                  texto: 'Cuentas por pagar',
                  seleccionado: !_mostrarCobrar,
                  expandido: true,
                  onTap: () {
                    _cambiarSeccion(false);
                  },
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TabFinanzas(
                  texto: 'Cuentas por cobrar',
                  seleccionado: _mostrarCobrar,
                  onTap: () {
                    _cambiarSeccion(true);
                  },
                ),

                _TabFinanzas(
                  texto: 'Cuentas por pagar',
                  seleccionado: !_mostrarCobrar,
                  onTap: () {
                    _cambiarSeccion(false);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildResumenCobrar() {
    final resumen = _resumenCobrar!;

    return _ResumenGrid(
      children: [
        _ResumenFinanzaCard(
          titulo: 'Total vendido',
          valor: _moneda(resumen.totalVendido),
          icono: Icons.point_of_sale_outlined,
        ),

        _ResumenFinanzaCard(
          titulo: 'Total cobrado',
          valor: _moneda(resumen.totalCobrado),
          icono: Icons.payments_outlined,
        ),

        _ResumenFinanzaCard(
          titulo: 'Por cobrar',
          valor: _moneda(resumen.totalPorCobrar),
          icono: Icons.receipt_long_outlined,
          destacado: true,
        ),

        _ResumenFinanzaCard(
          titulo: 'Cuentas pendientes',
          valor: '${resumen.cantidadPendientes + resumen.cantidadParciales}',
          icono: Icons.pending_actions_outlined,
        ),
      ],
    );
  }

  Widget _buildResumenPagar() {
    final resumen = _resumenPagar!;

    return _ResumenGrid(
      children: [
        _ResumenFinanzaCard(
          titulo: 'Total comprado',
          valor: _moneda(resumen.totalComprado),
          icono: Icons.shopping_cart_outlined,
        ),

        _ResumenFinanzaCard(
          titulo: 'Total pagado',
          valor: _moneda(resumen.totalPagado),
          icono: Icons.outbox_outlined,
        ),

        _ResumenFinanzaCard(
          titulo: 'Por pagar',
          valor: _moneda(resumen.totalPorPagar),
          icono: Icons.account_balance_outlined,
          destacado: true,
        ),

        _ResumenFinanzaCard(
          titulo: 'Cuentas pendientes',
          valor: '${resumen.cantidadPendientes + resumen.cantidadParciales}',
          icono: Icons.pending_actions_outlined,
        ),
      ],
    );
  }

  Widget _buildFiltros(bool pantallaPequena) {
    final valor = _mostrarCobrar ? _estadoCobrar : _estadoPagar;

    final dropdown = DropdownButtonFormField<String?>(
      initialValue: valor,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Estado',
        prefixIcon: Icon(Icons.filter_alt_outlined, size: 19),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Todos')),
        DropdownMenuItem(value: 'PENDIENTE', child: Text('Pendiente')),
        DropdownMenuItem(value: 'PARCIAL', child: Text('Parcial')),
        DropdownMenuItem(value: 'PAGADA', child: Text('Pagada')),
        DropdownMenuItem(value: 'ANULADA', child: Text('Anulada')),
      ],
      onChanged: (value) async {
        if (_mostrarCobrar) {
          _estadoCobrar = value;
          _paginaCobrar = 0;
        } else {
          _estadoPagar = value;
          _paginaPagar = 0;
        }

        await _cargar();
      },
    );

    if (pantallaPequena) {
      return SizedBox(width: double.infinity, child: dropdown);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(width: 210, child: dropdown),
    );
  }

  Widget _buildTablaCobrar(double anchoDisponible) {
    final cuentas = _cuentasCobrar?.contenido ?? const <CuentaCobrar>[];

    if (cuentas.isEmpty) {
      return _buildVacio(
        'No hay cuentas por cobrar para los filtros seleccionados.',
      );
    }

    return _TablaBase(
      builder: (context, anchoTabla) {
        final compacta = anchoTabla < 850;

        if (compacta) {
          return DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 14,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('Cliente')),
              DataColumn(label: Text('Pendiente')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: cuentas.map((cuenta) {
              final puedePagar =
                  cuenta.estado == 'PENDIENTE' || cuenta.estado == 'PARCIAL';

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cuenta.nombreCliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            cuenta.codigoVenta,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      _moneda(cuenta.saldoPendiente),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  DataCell(_EstadoCuentaBadge(estado: cuenta.estado)),

                  DataCell(
                    _AccionesCuenta(
                      puedePagar: puedePagar,
                      iconoPago: Icons.payments_outlined,
                      onVer: () {
                        _verDetalleCobrar(cuenta);
                      },
                      onPagar: () {
                        _registrarPago(cuenta);
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }

        return DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          horizontalMargin: 18,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Cliente')),
            DataColumn(label: Text('Venta')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Pagado')),
            DataColumn(label: Text('Pendiente')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: cuentas.map((cuenta) {
            final puedePagar =
                cuenta.estado == 'PENDIENTE' || cuenta.estado == 'PARCIAL';

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      cuenta.nombreCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                DataCell(Text(cuenta.codigoVenta)),

                DataCell(Text(_moneda(cuenta.montoTotal))),

                DataCell(Text(_moneda(cuenta.montoPagado))),

                DataCell(
                  Text(
                    _moneda(cuenta.saldoPendiente),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                DataCell(_EstadoCuentaBadge(estado: cuenta.estado)),

                DataCell(
                  _AccionesCuenta(
                    puedePagar: puedePagar,
                    iconoPago: Icons.payments_outlined,
                    onVer: () {
                      _verDetalleCobrar(cuenta);
                    },
                    onPagar: () {
                      _registrarPago(cuenta);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTablaPagar(double anchoDisponible) {
    final cuentas = _cuentasPagar?.contenido ?? const <CuentaPagar>[];

    if (cuentas.isEmpty) {
      return _buildVacio(
        'No hay cuentas por pagar para los filtros seleccionados.',
      );
    }

    return _TablaBase(
      builder: (context, anchoTabla) {
        final compacta = anchoTabla < 850;

        if (compacta) {
          return DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 14,
            columnSpacing: 22,
            columns: const [
              DataColumn(label: Text('Proveedor')),
              DataColumn(label: Text('Pendiente')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: cuentas.map((cuenta) {
              final puedePagar =
                  cuenta.estado == 'PENDIENTE' || cuenta.estado == 'PARCIAL';

              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cuenta.razonSocialProveedor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            cuenta.codigoCompra,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  DataCell(
                    Text(
                      _moneda(cuenta.saldoPendiente),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),

                  DataCell(_EstadoCuentaBadge(estado: cuenta.estado)),

                  DataCell(
                    _AccionesCuenta(
                      puedePagar: puedePagar,
                      iconoPago: Icons.outbox_outlined,
                      onVer: () {
                        _verDetallePagar(cuenta);
                      },
                      onPagar: () {
                        _registrarPagoProveedor(cuenta);
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }

        return DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          horizontalMargin: 18,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Proveedor')),
            DataColumn(label: Text('Compra')),
            DataColumn(label: Text('Total')),
            DataColumn(label: Text('Pagado')),
            DataColumn(label: Text('Pendiente')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: cuentas.map((cuenta) {
            final puedePagar =
                cuenta.estado == 'PENDIENTE' || cuenta.estado == 'PARCIAL';

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      cuenta.razonSocialProveedor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                DataCell(Text(cuenta.codigoCompra)),

                DataCell(Text(_moneda(cuenta.montoTotal))),

                DataCell(Text(_moneda(cuenta.montoPagado))),

                DataCell(
                  Text(
                    _moneda(cuenta.saldoPendiente),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),

                DataCell(_EstadoCuentaBadge(estado: cuenta.estado)),

                DataCell(
                  _AccionesCuenta(
                    puedePagar: puedePagar,
                    iconoPago: Icons.outbox_outlined,
                    onVer: () {
                      _verDetallePagar(cuenta);
                    },
                    onPagar: () {
                      _registrarPagoProveedor(cuenta);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVacio(String mensaje) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginacion(bool pantallaPequena) {
    if (_mostrarCobrar) {
      final pagina = _cuentasCobrar!;

      final controles = _ControlesPaginacion(
        paginaActual: pagina.pagina + 1,
        totalPaginas: pagina.totalPaginas == 0 ? 1 : pagina.totalPaginas,
        primera: pagina.primera,
        ultima: pagina.ultima,
        onAnterior: () async {
          _paginaCobrar--;

          await _cargar();
        },
        onSiguiente: () async {
          _paginaCobrar++;

          await _cargar();
        },
      );

      if (pantallaPequena) {
        return Column(
          children: [
            Text(
              '${pagina.totalElementos} cuentas',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 4),

            controles,
          ],
        );
      }

      return Row(
        children: [
          Text(
            '${pagina.totalElementos} cuentas',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),

          const Spacer(),

          controles,
        ],
      );
    }

    final pagina = _cuentasPagar!;

    final controles = _ControlesPaginacion(
      paginaActual: pagina.pagina + 1,
      totalPaginas: pagina.totalPaginas == 0 ? 1 : pagina.totalPaginas,
      primera: pagina.primera,
      ultima: pagina.ultima,
      onAnterior: () async {
        _paginaPagar--;

        await _cargar();
      },
      onSiguiente: () async {
        _paginaPagar++;

        await _cargar();
      },
    );

    if (pantallaPequena) {
      return Column(
        children: [
          Text(
            '${pagina.totalElementos} cuentas',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 4),

          controles,
        ],
      );
    }

    return Row(
      children: [
        Text(
          '${pagina.totalElementos} cuentas',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),

        const Spacer(),

        controles,
      ],
    );
  }
}

class _ResumenGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResumenGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        int columnas;

        if (ancho >= 1050) {
          columnas = 4;
        } else if (ancho >= 620) {
          columnas = 2;
        } else {
          columnas = 1;
        }

        const separacion = 12.0;

        final anchoItem = (ancho - ((columnas - 1) * separacion)) / columnas;

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: children.map((child) {
            return SizedBox(width: anchoItem, height: 92, child: child);
          }).toList(),
        );
      },
    );
  }
}

class _TabFinanzas extends StatelessWidget {
  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;
  final bool expandido;

  const _TabFinanzas({
    required this.texto,
    required this.seleccionado,
    required this.onTap,
    this.expandido = false,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = Material(
      color: seleccionado ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
              color: seleccionado
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );

    if (expandido) {
      return SizedBox(width: double.infinity, child: contenido);
    }

    return contenido;
  }
}

class _ResumenFinanzaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final bool destacado;

  const _ResumenFinanzaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: destacado ? const Color(0xFFBFDBFE) : const Color(0xFFE7EAF0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: destacado
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icono,
              size: 19,
              color: destacado
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(width: 11),

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
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: destacado
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF172033),
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

class _EstadoCuentaBadge extends StatelessWidget {
  final String estado;

  const _EstadoCuentaBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color color;

    switch (estado) {
      case 'PENDIENTE':
        fondo = const Color(0xFFFFF7ED);
        color = const Color(0xFFEA580C);
        break;

      case 'PARCIAL':
        fondo = const Color(0xFFEFF6FF);
        color = const Color(0xFF2563EB);
        break;

      case 'PAGADA':
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        maxLines: 1,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AccionesCuenta extends StatelessWidget {
  final bool puedePagar;
  final IconData iconoPago;

  final VoidCallback onVer;
  final VoidCallback onPagar;

  const _AccionesCuenta({
    required this.puedePagar,
    required this.iconoPago,
    required this.onVer,
    required this.onPagar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Ver detalle',
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: const EdgeInsets.all(6),
          onPressed: onVer,
          icon: const Icon(Icons.visibility_outlined, size: 19),
        ),

        IconButton(
          tooltip: puedePagar ? 'Registrar pago' : 'La cuenta no admite pagos',
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          padding: const EdgeInsets.all(6),
          onPressed: puedePagar ? onPagar : null,
          icon: Icon(iconoPago, size: 19),
        ),
      ],
    );
  }
}

class _TablaBase extends StatefulWidget {
  final Widget Function(BuildContext context, double anchoDisponible) builder;

  const _TablaBase({required this.builder});

  @override
  State<_TablaBase> createState() => _TablaBaseState();
}

class _TablaBaseState extends State<_TablaBase> {
  final ScrollController _scrollHorizontal = ScrollController();

  @override
  void dispose() {
    _scrollHorizontal.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _scrollHorizontal,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _scrollHorizontal,
              primary: false,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  primary: false,
                  child: widget.builder(context, constraints.maxWidth),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ControlesPaginacion extends StatelessWidget {
  final int paginaActual;
  final int totalPaginas;

  final bool primera;
  final bool ultima;

  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const _ControlesPaginacion({
    required this.paginaActual,
    required this.totalPaginas,
    required this.primera,
    required this.ultima,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Página anterior',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: primera ? null : onAnterior,
          icon: const Icon(Icons.chevron_left, size: 20),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Página $paginaActual de $totalPaginas',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),

        IconButton(
          tooltip: 'Página siguiente',
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: ultima ? null : onSiguiente,
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

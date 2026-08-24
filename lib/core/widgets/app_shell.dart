import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/models/auth_user.dart';
import '../../features/auth/services/auth_service.dart';
import '../responsive/app_breakpoints.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String rutaActual;

  const AppShell({super.key, required this.child, required this.rutaActual});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _authService = AuthService();

  AuthUser? _usuario;

  bool _cargandoUsuario = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();

    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final usuario = await _authService.obtenerUsuarioActual();

      if (!mounted) {
        return;
      }

      setState(() {
        _usuario = usuario;
        _cargandoUsuario = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cargandoUsuario = false;
      });

      context.go('/login');
    }
  }

  Future<void> _cerrarSesion() async {
    await _authService.logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  String get _titulo {
    switch (widget.rutaActual) {
      case '/dashboard':
        return 'Dashboard';

      case '/clientes':
        return 'Clientes';

      case '/productos':
        return 'Productos';

      case '/precios-clientes':
        return 'Precios clientes';

      case '/ventas':
        return 'Ventas';

      case '/inventario':
        return 'Inventario';

      case '/envases':
        return 'Envases';

      case '/caja':
        return 'Caja';

      case '/finanzas':
        return 'Finanzas';

      case '/proveedores':
        return 'Proveedores';

      case '/compras':
        return 'Compras';

      case '/egresos':
        return 'Egresos';

      case '/cotizaciones':
        return 'Cotizaciones';

      case '/configuracion':
        return 'Configuración';

      default:
        return 'Bencol';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final compacto = AppBreakpoints.isCompact(width);

        final mediano = AppBreakpoints.isMedium(width);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F7FB),

          drawer: compacto
              ? Drawer(
                  width: 250,
                  child: _Sidebar(
                    rutaActual: widget.rutaActual,
                    onLogout: _cerrarSesion,
                    compacto: false,
                    cerrarDrawer: true,
                  ),
                )
              : null,

          body: Row(
            children: [
              if (!compacto)
                _Sidebar(
                  rutaActual: widget.rutaActual,
                  onLogout: _cerrarSesion,
                  compacto: mediano,
                ),

              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      titulo: _titulo,
                      usuario: _usuario,
                      cargandoUsuario: _cargandoUsuario,
                      mostrarMenu: compacto,
                      onMenuPressed: compacto
                          ? () {
                              _scaffoldKey.currentState?.openDrawer();
                            }
                          : null,
                    ),

                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String rutaActual;
  final VoidCallback onLogout;

  final bool compacto;
  final bool cerrarDrawer;

  const _Sidebar({
    required this.rutaActual,
    required this.onLogout,
    this.compacto = false,
    this.cerrarDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final ancho = compacto ? 76.0 : 230.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: ancho,
      color: const Color(0xFF0F4C81),
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 10 : 15,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),

          const SizedBox(height: 26),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _menuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    texto: 'Dashboard',
                    ruta: '/dashboard',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.people_outline,
                    texto: 'Clientes',
                    ruta: '/clientes',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.inventory_2_outlined,
                    texto: 'Productos',
                    ruta: '/productos',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.price_change_outlined,
                    texto: 'Precios clientes',
                    ruta: '/precios-clientes',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.point_of_sale_outlined,
                    texto: 'Ventas',
                    ruta: '/ventas',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.warehouse_outlined,
                    texto: 'Inventario',
                    ruta: '/inventario',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.water_drop_outlined,
                    texto: 'Envases',
                    ruta: '/envases',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    texto: 'Caja',
                    ruta: '/caja',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.account_balance_outlined,
                    texto: 'Finanzas',
                    ruta: '/finanzas',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.local_shipping_outlined,
                    texto: 'Proveedores',
                    ruta: '/proveedores',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.shopping_cart_outlined,
                    texto: 'Compras',
                    ruta: '/compras',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.trending_down,
                    texto: 'Egresos',
                    ruta: '/egresos',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.request_quote_outlined,
                    texto: 'Cotizaciones',
                    ruta: '/cotizaciones',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.settings_outlined,
                    texto: 'Configuración',
                    ruta: '/configuracion',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          _menuItem(
            context,
            icon: Icons.logout,
            texto: 'Cerrar sesión',
            onTap: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    if (compacto) {
      return const Center(
        child: Icon(Icons.water_drop_rounded, color: Colors.white, size: 30),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.water_drop_rounded, color: Colors.white, size: 30),

          SizedBox(width: 10),

          Text(
            'BENCOL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String texto,
    String? ruta,
    VoidCallback? onTap,
  }) {
    final seleccionado = ruta != null && rutaActual == ruta;

    final contenido = Material(
      color: seleccionado
          ? Colors.white.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap();

            if (cerrarDrawer) {
              Navigator.of(context).pop();
            }

            return;
          }

          if (ruta == null || ruta == rutaActual) {
            if (cerrarDrawer) {
              Navigator.of(context).pop();
            }

            return;
          }

          if (cerrarDrawer) {
            Navigator.of(context).pop();
          }

          context.go(ruta);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compacto ? 10 : 14,
            vertical: 13,
          ),
          child: Row(
            mainAxisAlignment: compacto
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 21),

              if (!compacto) ...[
                const SizedBox(width: 13),

                Expanded(
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: seleccionado
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: compacto ? Tooltip(message: texto, child: contenido) : contenido,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String titulo;

  final AuthUser? usuario;
  final bool cargandoUsuario;

  final bool mostrarMenu;
  final VoidCallback? onMenuPressed;

  const _TopBar({
    required this.titulo,
    required this.usuario,
    required this.cargandoUsuario,
    required this.mostrarMenu,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: mostrarMenu ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: Row(
        children: [
          if (mostrarMenu) ...[
            IconButton(
              tooltip: 'Menú',
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
            ),

            const SizedBox(width: 8),
          ],

          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: mostrarMenu ? 19 : 23,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (cargandoUsuario)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (usuario != null)
            _UsuarioTopBar(usuario: usuario!, compacto: mostrarMenu),
        ],
      ),
    );
  }
}

class _UsuarioTopBar extends StatelessWidget {
  final AuthUser usuario;
  final bool compacto;

  const _UsuarioTopBar({required this.usuario, required this.compacto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!compacto) ...[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usuario.username,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              Text(
                usuario.rol,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),

          const SizedBox(width: 12),
        ],

        CircleAvatar(
          radius: compacto ? 17 : 19,
          backgroundColor: const Color(0xFFE8F0FE),
          child: Text(
            usuario.username.isNotEmpty
                ? usuario.username.substring(0, 1).toUpperCase()
                : '?',
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

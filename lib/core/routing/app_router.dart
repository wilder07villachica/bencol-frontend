import 'package:go_router/go_router.dart';

import '../widgets/app_shell.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/clientes/presentation/clientes_page.dart';
import '../../features/productos/presentation/productos_page.dart';
import '../../features/precios_clientes/presentation/precios_clientes_page.dart';
import '../../features/ventas/presentation/ventas_page.dart';
import '../../features/inventario/presentation/inventario_page.dart';
import '../../features/envases/presentation/envases_page.dart';
import '../../features/caja/presentation/caja_page.dart';
import '../../features/finanzas/presentation/finanzas_page.dart';
import '../../features/proveedores/presentation/proveedores_page.dart';
import '../../features/compras/presentation/compras_page.dart';
import '../../features/egresos/presentation/egresos_page.dart';
import '../../features/cotizaciones/presentation/cotizaciones_page.dart';
import '../../features/empresa/presentation/empresa_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          return AppShell(rutaActual: state.uri.path, child: child);
        },

        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: DashboardPage());
            },
          ),

          GoRoute(
            path: '/clientes',
            name: 'clientes',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ClientesPage());
            },
          ),

          GoRoute(
            path: '/productos',
            name: 'productos',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProductosPage());
            },
          ),

          GoRoute(
            path: '/precios-clientes',
            name: 'precios-clientes',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: PreciosClientesPage());
            },
          ),

          GoRoute(
            path: '/ventas',
            name: 'ventas',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: VentasPage());
            },
          ),

          GoRoute(
            path: '/inventario',
            name: 'inventario',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: InventarioPage());
            },
          ),

          GoRoute(
            path: '/envases',
            name: 'envases',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: EnvasesPage());
            },
          ),

          GoRoute(
            path: '/caja',
            name: 'caja',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CajaPage());
            },
          ),

          GoRoute(
            path: '/finanzas',
            name: 'finanzas',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: FinanzasPage());
            },
          ),

          GoRoute(
            path: '/proveedores',
            name: 'proveedores',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProveedoresPage());
            },
          ),

          GoRoute(
            path: '/compras',
            name: 'compras',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ComprasPage());
            },
          ),

          GoRoute(
            path: '/egresos',
            name: 'egresos',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: EgresosPage());
            },
          ),

          GoRoute(
            path: '/cotizaciones',
            name: 'cotizaciones',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CotizacionesPage());
            },
          ),

          GoRoute(
            path: '/configuracion',
            name: 'configuracion',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: EmpresaPage());
            },
          ),
        ],
      ),
    ],
  );
}

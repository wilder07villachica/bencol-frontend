class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'http://localhost:8080';
  static const String apiPrefix = '/bencol.agua';

  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  // AUTH
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // REPORTES
  static const String dashboard = '/reportes/dashboard';
  static const String productosMasVendidos = '/reportes/productos-mas-vendidos';
  static const String ventasPorDia = '/reportes/ventas-por-dia';
  static const String clientesMayorDeuda = '/reportes/clientes-mayor-deuda';
  static const String stockBajo = '/reportes/stock-bajo';
  static const String ventasPorMes = '/reportes/ventas-por-mes';
  static const String ingresosPorMes = '/reportes/ingresos-por-mes';
  static const String egresosPorMes = '/reportes/egresos-por-mes';
  static const String flujoNetoPorMes = '/reportes/flujo-neto-por-mes';
  static const String tendencias = '/reportes/tendencias';
  static const String rentabilidadProductos =
      '/reportes/rentabilidad-productos';

  // CLIENTES
  static const String clientes = '/clientes';

  // PRODUCTOS
  static const String productos = '/productos';

  // PRECIOS CLIENTES - PRODUCTO
  static const String preciosClientes = '/precios-clientes';

  // VENTAS
  static const String ventas = '/ventas';

  // INVENTARIO
  static const String inventarios = '/inventarios';

  // ENVASES
  static const String envases = '/envases';

  // CAJA
  static const String caja = '/caja';

  // FINANZAS
  static const String cuentasCobrar = '/finanzas/cuentas';
  static const String cuentasPagar = '/finanzas/cuentas-pagar';

  // EGRESOS
  static const String egresos = '/egresos';

  // PROVEEDORES
  static const String proveedores = '/proveedores';

  // COMPRAS
  static const String compras = '/compras';

  // COTIZACIONES
  static const String cotizaciones = '/cotizaciones';

  // EMPRESA
  static const String empresa = '/empresa';
}

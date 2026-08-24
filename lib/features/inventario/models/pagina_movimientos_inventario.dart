import 'movimiento_inventario.dart';

class PaginaMovimientosInventario {
  final List<MovimientoInventario> contenido;
  final int pagina;
  final int tamanio;
  final int totalElementos;
  final int totalPaginas;
  final bool primera;
  final bool ultima;

  const PaginaMovimientosInventario({
    required this.contenido,
    required this.pagina,
    required this.tamanio,
    required this.totalElementos,
    required this.totalPaginas,
    required this.primera,
    required this.ultima,
  });

  factory PaginaMovimientosInventario.fromJson(Map<String, dynamic> json) {
    final lista = json['contenido'] as List<dynamic>? ?? [];

    return PaginaMovimientosInventario(
      contenido: lista
          .map(
            (item) =>
                MovimientoInventario.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      pagina: (json['pagina'] as num?)?.toInt() ?? 0,
      tamanio: (json['tamanio'] as num?)?.toInt() ?? 20,
      totalElementos: (json['totalElementos'] as num?)?.toInt() ?? 0,
      totalPaginas: (json['totalPaginas'] as num?)?.toInt() ?? 0,
      primera: json['primera'] as bool? ?? true,
      ultima: json['ultima'] as bool? ?? true,
    );
  }
}

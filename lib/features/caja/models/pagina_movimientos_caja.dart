import 'movimiento_caja.dart';

class PaginaMovimientosCaja {
  final List<MovimientoCaja> contenido;
  final int pagina;
  final int tamanio;
  final int totalElementos;
  final int totalPaginas;
  final bool primera;
  final bool ultima;

  const PaginaMovimientosCaja({
    required this.contenido,
    required this.pagina,
    required this.tamanio,
    required this.totalElementos,
    required this.totalPaginas,
    required this.primera,
    required this.ultima,
  });

  factory PaginaMovimientosCaja.fromJson(Map<String, dynamic> json) {
    final lista = json['contenido'] as List<dynamic>? ?? [];

    return PaginaMovimientosCaja(
      contenido: lista
          .map((item) => MovimientoCaja.fromJson(item as Map<String, dynamic>))
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

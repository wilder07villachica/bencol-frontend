import 'cotizacion.dart';

class PaginaCotizaciones {
  final List<Cotizacion> contenido;

  final int pagina;
  final int tamanio;

  final int totalElementos;
  final int totalPaginas;

  final bool primera;
  final bool ultima;

  PaginaCotizaciones({
    required this.contenido,
    required this.pagina,
    required this.tamanio,
    required this.totalElementos,
    required this.totalPaginas,
    required this.primera,
    required this.ultima,
  });

  factory PaginaCotizaciones.fromJson(Map<String, dynamic> json) {
    return PaginaCotizaciones(
      contenido: (json['contenido'] as List<dynamic>)
          .map((item) => Cotizacion.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagina: json['pagina'] as int,
      tamanio: json['tamanio'] as int,
      totalElementos: json['totalElementos'] as int,
      totalPaginas: json['totalPaginas'] as int,
      primera: json['primera'] as bool,
      ultima: json['ultima'] as bool,
    );
  }
}

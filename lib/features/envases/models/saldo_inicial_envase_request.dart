class SaldoInicialEnvaseRequest {
  final int clienteId;
  final int productoId;
  final int cantidadPropios;
  final int cantidadPrestados;
  final String? referencia;

  const SaldoInicialEnvaseRequest({
    required this.clienteId,
    required this.productoId,
    required this.cantidadPropios,
    required this.cantidadPrestados,
    this.referencia,
  });

  Map<String, dynamic> toJson() {
    return {
      'clienteId': clienteId,
      'productoId': productoId,
      'cantidadPropios': cantidadPropios,
      'cantidadPrestados': cantidadPrestados,
      if (referencia != null && referencia!.trim().isNotEmpty)
        'referencia': referencia!.trim(),
    };
  }
}

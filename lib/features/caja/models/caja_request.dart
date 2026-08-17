class CajaRequest {
  final double saldoInicial;

  const CajaRequest({required this.saldoInicial});

  Map<String, dynamic> toJson() {
    return {'saldoInicial': saldoInicial};
  }
}

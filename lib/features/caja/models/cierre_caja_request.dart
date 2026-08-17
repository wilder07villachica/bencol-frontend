class CierreCajaRequest {
  final double saldoReal;

  const CierreCajaRequest({required this.saldoReal});

  Map<String, dynamic> toJson() {
    return {'saldoReal': saldoReal};
  }
}

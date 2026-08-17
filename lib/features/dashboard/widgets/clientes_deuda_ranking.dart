import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_rankings_response.dart';

class ClientesDeudaRanking extends StatelessWidget {
  final List<ClienteMayorDeuda> clientes;

  ClientesDeudaRanking({super.key, required this.clientes});

  final NumberFormat _numero = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    if (clientes.isEmpty) {
      return const Center(
        child: Text(
          'No existen clientes con deuda pendiente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 430;

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: clientes.length,
          separatorBuilder: (_, _) {
            return const Divider(height: 1, color: Color(0xFFF1F5F9));
          },
          itemBuilder: (context, index) {
            final cliente = clientes[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: compacto ? _buildCompacto(cliente) : _buildNormal(cliente),
            );
          },
        );
      },
    );
  }

  Widget _buildNormal(ClienteMayorDeuda cliente) {
    return Row(
      children: [
        _ClienteAvatar(nombre: cliente.nombreCliente),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente.nombreCliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 4),

              Text(
                '${cliente.cantidadCuentasPendientes} cuentas pendientes',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Text(
          'S/ ${_numero.format(cliente.deudaTotal)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _buildCompacto(ClienteMayorDeuda cliente) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ClienteAvatar(nombre: cliente.nombreCliente),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente.nombreCliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${cliente.cantidadCuentasPendientes} cuentas pendientes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),

              const SizedBox(height: 5),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'S/ ${_numero.format(cliente.deudaTotal)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClienteAvatar extends StatelessWidget {
  final String nombre;

  const _ClienteAvatar({required this.nombre});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFFFF1F2),
      child: Text(
        nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(
          color: Color(0xFFE11D48),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

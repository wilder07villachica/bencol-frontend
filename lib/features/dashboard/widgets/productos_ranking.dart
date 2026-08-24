import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_rankings_response.dart';

class ProductosRanking extends StatelessWidget {
  final List<ProductoMasVendido> productos;

  ProductosRanking({super.key, required this.productos});

  final NumberFormat _numero = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const Center(
        child: Text(
          'No hay ventas de productos en este periodo.',
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
          itemCount: productos.length,
          separatorBuilder: (_, _) {
            return const Divider(height: 1, color: Color(0xFFF1F5F9));
          },
          itemBuilder: (context, index) {
            final producto = productos[index];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: compacto
                  ? _buildCompacto(producto, index)
                  : _buildNormal(producto, index),
            );
          },
        );
      },
    );
  }

  Widget _buildNormal(ProductoMasVendido producto, int index) {
    return Row(
      children: [
        _RankingNumero(numero: index + 1),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.descripcionProducto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 4),

              Text(
                '${producto.codigoProducto} · '
                '${producto.cantidadVendida} vendidos · '
                '${producto.unidadesFisicasVendidas} unidades físicas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        Text(
          'S/ ${_numero.format(producto.totalVendido)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCompacto(ProductoMasVendido producto, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RankingNumero(numero: index + 1),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                producto.descripcionProducto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${producto.codigoProducto} · '
                '${producto.cantidadVendida} vendidos',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),

              const SizedBox(height: 5),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'S/ ${_numero.format(producto.totalVendido)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _RankingNumero extends StatelessWidget {
  final int numero;

  const _RankingNumero({required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$numero',
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

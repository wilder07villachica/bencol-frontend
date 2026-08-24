import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/login_request.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _cargando = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (_cargando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _cargando = true;
    });

    try {
      final response = await _authService.login(
        LoginRequest(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        'Login correcto: '
        '${response.username} - ${response.rol}',
      );

      context.go('/dashboard');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final ancho = constraints.maxWidth;

          final pantallaPequena = ancho < 850;
          final pantallaMuyPequena = ancho < 520;

          if (pantallaPequena) {
            return _buildVistaCompacta(pantallaMuyPequena);
          }

          return _buildVistaEscritorio();
        },
      ),
    );
  }

  Widget _buildVistaEscritorio() {
    return Row(
      children: [
        Expanded(flex: 11, child: _buildPanelMarca()),

        Expanded(
          flex: 9,
          child: Container(
            color: const Color(0xFFF8FAFD),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: _buildLoginCard(compacto: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVistaCompacta(bool pantallaMuyPequena) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7F3FF), Color(0xFFF8FAFD)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: pantallaMuyPequena ? 16 : 28,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  _buildMarcaCompacta(),

                  const SizedBox(height: 24),

                  _buildLoginCard(compacto: true),

                  const SizedBox(height: 18),

                  const Text(
                    'Sistema de gestión empresarial',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelMarca() {
    return Container(
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF083E73), Color(0xFF0F68A5), Color(0xFF1599D4)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -110,
            child: _CirculoDecorativo(
              size: 360,
              color: Colors.white,
              opacity: 0.05,
            ),
          ),

          Positioned(
            bottom: -160,
            right: -120,
            child: _CirculoDecorativo(
              size: 430,
              color: Colors.white,
              opacity: 0.06,
            ),
          ),

          Positioned(
            top: 80,
            right: -100,
            child: _CirculoDecorativo(
              size: 250,
              color: const Color(0xFF7DD3FC),
              opacity: 0.08,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 58, vertical: 44),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _RupajBrand(claro: true),

                const Spacer(),

                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 530),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            color: Colors.white,
                            size: 68,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Agua purificada\nRupaj',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Manantial de los Andes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFD85A),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Container(
                          width: 70,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white70,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Controla ventas, clientes, inventario, '
                          'envases, compras, caja y finanzas '
                          'desde una sola plataforma.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFE0F2FE),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                const Row(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 17,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'BENCOL N&L EIRL',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarcaCompacta() {
    return const Column(
      children: [
        _RupajBrand(claro: false, centrado: true),

        SizedBox(height: 8),

        Text(
          'Sistema de gestión Bencol',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildLoginCard({required bool compacto}) {
    return Container(
      padding: EdgeInsets.all(compacto ? 24 : 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 32,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Color(0xFF1675C1),
                size: 25,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: compacto ? 26 : 30,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172033),
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Ingresa tus credenciales para acceder al sistema.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Usuario',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _usernameController,
              enabled: !_cargando,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                hintText: 'Ingresa tu usuario',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El usuario es obligatorio.';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Contraseña',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),

            const SizedBox(height: 8),

            TextFormField(
              controller: _passwordController,
              enabled: !_cargando,
              obscureText: _ocultarPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                hintText: 'Ingresa tu contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _ocultarPassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: _cargando
                      ? null
                      : () {
                          setState(() {
                            _ocultarPassword = !_ocultarPassword;
                          });
                        },
                  icon: Icon(
                    _ocultarPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onFieldSubmitted: (_) {
                if (!_cargando) {
                  _iniciarSesion();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La contraseña es obligatoria.';
                }

                return null;
              },
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _cargando ? null : _iniciarSesion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1675C1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: _cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 22),

            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFFE7EAF0))),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'BENCOL',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                Expanded(child: Divider(color: Color(0xFFE7EAF0))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RupajBrand extends StatelessWidget {
  final bool claro;
  final bool centrado;

  const _RupajBrand({required this.claro, this.centrado = false});

  @override
  Widget build(BuildContext context) {
    final principal = claro ? Colors.white : const Color(0xFF0A4F91);

    final secundario = claro
        ? const Color(0xFFBAE6FD)
        : const Color(0xFF168AC7);

    final contenido = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: claro
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFE8F4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.water_drop_rounded, color: principal, size: 25),
        ),

        const SizedBox(width: 11),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RUPAJ',
              style: TextStyle(
                color: principal,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),

            Text(
              'AGUA PURIFICADA',
              style: TextStyle(
                color: secundario,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ],
    );

    if (centrado) {
      return Center(child: contenido);
    }

    return contenido;
  }
}

class _CirculoDecorativo extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _CirculoDecorativo({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

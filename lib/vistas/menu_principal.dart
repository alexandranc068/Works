import 'package:flutter/material.dart';
import 'package:tfg_alexandra/vistas/contenedor_principal.dart';
import '../controladores/logica_juego.dart';
import 'selector_dificultad_vista.dart';
import 'pantalla_repaso_vista.dart';
import 'pantalla_tutorial_vista.dart';

// ─── Paleta japonesa ──────────────────────────────────────────────────────────
// Sakura:    #F4A7B9   Rosa flor de cerezo
// Dorado:    #C9A96E   Oro washi antiguo
// Crema:     #FDFAF5   Papel washi blanco hueso
// Rojo torii:#C0392B   Rojo torii tradicional
// Sumi:      #1a0a0a   Tinta japonesa oscura
// ─────────────────────────────────────────────────────────────────────────────

class MenuPrincipalVista extends StatefulWidget {
  const MenuPrincipalVista({super.key});

  @override
  State<MenuPrincipalVista> createState() => _MenuPrincipalVistaState();
}

class _MenuPrincipalVistaState extends State<MenuPrincipalVista>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nombreController = TextEditingController();
  final LogicaJuego _controlador = LogicaJuego();
  bool _estaCargando = false;

  // Animación de entrada única — sin bucle, sin balanceo
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _irALaGuia() {
    if (_controlador.jugadorActual == null) {
      _mostrarMensaje(
        "Inicia sesión primero para ver tu guía personalizada",
        const Color(0xFFC9A96E),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PantallaRepasoVista(controlador: _controlador),
      ),
    );
  }

  void _mostrarMensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  // Valida que el nombre no esté vacío (acepta japonés, latino, etc.)
  bool _nombreValido(String nombre) => nombre.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // 1. Obtener la altura disponible
   final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Fondo con imagen + gradiente ──────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/imagenes/entrada.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66000000), // 40% negro arriba
                    Color(0xCC1a0a0a), // 80% tinta abajo
                    Color(0xF21a0a0a), // 95% tinta al fondo
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // ── Contenido principal ───────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                         SizedBox(height: 48 * escala),

                        // ── Sello hanko ──────────────────────────────
                        _SelloHanko(),

                         SizedBox(height: 28 * escala),

                        // ── Kanji decorativo ─────────────────────────
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Color(0xFFF4A7B9), Color(0xFFC9A96E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            "日本語",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),

                        SizedBox(height: 10* escala),
                        _LineaDorada(),
                        SizedBox(height: 16* escala),

                        // ── Título ───────────────────────────────────
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [Color(0xFFFDFAF5), Color(0xFFF4A7B9)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            "INMERSIÓN\nJAPÓN",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 44,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              height: 1.1,
                            ),
                          ),
                        ),

                        SizedBox(height: 10* escala),

                        // ── Subtítulo japonés ─────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: const Color(0xFFC9A96E)
                                    .withOpacity(0.35),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Text(
                            "日本語の冒険",
                            style: TextStyle(
                              fontSize: 15,
                              color: const Color(0xFFC9A96E).withOpacity(0.9),
                              letterSpacing: 7,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),

                        SizedBox(height: 52* escala),

                        // ── Campo de nombre ───────────────────────────
                        _CampoNombre(controller: _nombreController),

                        SizedBox(height: 8* escala),

                        // Hint sobre nombres japoneses
                        Text(
                          "Puedes usar tu nombre en japonés: 桜、健太...",
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFFC9A96E).withOpacity(0.55),
                            letterSpacing: 0.3,
                          ),
                        ),

                        SizedBox(height: 36* escala),

                        // ── Botones o loader ──────────────────────────
                        if (_estaCargando)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: CircularProgressIndicator(
                              color: Color(0xFFF4A7B9),
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          _BotonJapones(
                            texto: "CONTINUAR PARTIDA",
                            icono: Icons.play_arrow_rounded,
                            esPrimario: true,
                            onPressed: () async {
                              final nombre =
                                  _nombreController.text.trim();
                              if (!_nombreValido(nombre)) {
                                _mostrarMensaje(
                                  "Introduce tu nombre para continuar",
                                  const Color(0xFFC0392B),
                                );
                                return;
                              }
                              setState(() => _estaCargando = true);
                              final existe = await _controlador
                                  .elNombreYaExiste(nombre);
                              if (!existe) {
                                _mostrarMensaje(
                                  "No existe ningún perfil con ese nombre.",
                                  const Color(0xFFC9A96E),
                                );
                                setState(() => _estaCargando = false);
                                return;
                              }
                              await _controlador
                                  .iniciarOSuperarSesion(nombre);
                              setState(() => _estaCargando = false);
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContenedorPrincipal(
                                        controlador: _controlador),
                                  ),
                                );
                              }
                            },
                          ),

                          SizedBox(height: 14* escala),

                          _BotonJapones(
                            texto: "NUEVO ESTUDIANTE",
                            icono: Icons.person_add_outlined,
                            esPrimario: false,
                            onPressed: () async {
                              final nombre =
                                  _nombreController.text.trim();
                              if (!_nombreValido(nombre)) {
                                _mostrarMensaje(
                                  "Elige un nombre para registrarte",
                                  const Color(0xFFC0392B),
                                );
                                return;
                              }
                              setState(() => _estaCargando = true);
                              final existe = await _controlador
                                  .elNombreYaExiste(nombre);
                              if (existe) {
                                _mostrarMensaje(
                                  "Este nombre ya está pillado. ¡Elige otro!",
                                  const Color(0xFFC9A96E),
                                );
                                setState(() => _estaCargando = false);
                                return;
                              }
                              await _controlador
                                  .iniciarOSuperarSesion(nombre);
                              setState(() => _estaCargando = false);
                              if (mounted) {
                                // Usuario nuevo → mostrar tutorial
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        PantallaTutorialVista(
                                            controlador: _controlador),
                                    transitionsBuilder: (_, anim, __, child) =>
                                        FadeTransition(opacity: anim, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 600),
                                  ),
                                );
                              }
                            },
                          ),


                        ],

                        SizedBox(height: 40* escala),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineaFina(double width) => Container(
        width: width,
        height: 0.8,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFC9A96E).withOpacity(0.5),
              Colors.transparent,
            ],
          ),
        ),
      );
}

// ── Sello hanko decorativo ─────────────────────────────────────────────────────
class _SelloHanko extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC0392B).withOpacity(0.6),
          width: 1.5,
        ),
        color: const Color(0xFFC0392B).withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC0392B).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          "印",
          style: TextStyle(
            fontSize: 20,
            color: const Color(0xFFC0392B).withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

// ── Línea dorada decorativa ────────────────────────────────────────────────────
class _LineaDorada extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFFC9A96E).withOpacity(0.7),
            const Color(0xFFF4A7B9).withOpacity(0.4),
            const Color(0xFFC9A96E).withOpacity(0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }
}

// ── Campo de nombre con soporte japonés ───────────────────────────────────────
class _CampoNombre extends StatelessWidget {
  final TextEditingController controller;
  const _CampoNombre({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF4A7B9).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        // Permite cualquier teclado incluyendo japonés
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: Color(0xFFFDFAF5),
          fontSize: 16,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: "Nombre de jugador · プレイヤー名",
          labelStyle: TextStyle(
            color: const Color(0xFFF4A7B9).withOpacity(0.8),
            fontSize: 13,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w400,
          ),
          hintText: "Alexandra · 健太 · さくら",
          hintStyle: TextStyle(
            color: const Color(0xFFFDFAF5).withOpacity(0.2),
            fontSize: 14,
            letterSpacing: 1,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFFC9A96E).withOpacity(0.35),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFF4A7B9),
              width: 1.6,
            ),
          ),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: const Color(0xFFC9A96E).withOpacity(0.7),
            size: 21,
          ),
          filled: true,
          fillColor: Colors.black.withOpacity(0.38),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

// ── Botón japonés reutilizable ────────────────────────────────────────────────
class _BotonJapones extends StatelessWidget {
  final String texto;
  final IconData icono;
  final bool esPrimario;
  final VoidCallback onPressed;

  const _BotonJapones({
    required this.texto,
    required this.icono,
    required this.esPrimario,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (esPrimario) {
      return Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFC0392B), Color(0xFFE8503A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC0392B).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onPressed,
          icon: Icon(icono, size: 20, color: Colors.white),
          label: Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFDFAF5),
            side: BorderSide(
              color: const Color(0xFFFDFAF5).withOpacity(0.35),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.white.withOpacity(0.05),
          ),
          onPressed: onPressed,
          icon: Icon(icono,
              size: 20,
              color: const Color(0xFFFDFAF5).withOpacity(0.8)),
          label: Text(
            texto,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: const Color(0xFFFDFAF5).withOpacity(0.9),
            ),
          ),
        ),
      );
    }
  }
}
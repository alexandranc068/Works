import 'package:flutter/material.dart';
import 'contenedor_principal.dart';
import '../controladores/logica_juego.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PantallaTutorialVista
// Onboarding de 6 pasos que aparece solo la primera vez que un usuario se
// registra. Usa el irasutoya "presentadora_aplicacion" como guía.
// ─────────────────────────────────────────────────────────────────────────────

class PantallaTutorialVista extends StatefulWidget {
  final LogicaJuego controlador;
  const PantallaTutorialVista({super.key, required this.controlador});

  @override
  State<PantallaTutorialVista> createState() => _PantallaTutorialVistaState();
}

class _PantallaTutorialVistaState extends State<PantallaTutorialVista>
    with TickerProviderStateMixin {
  int _pasoActual = 0;

  late AnimationController _entradaController;
  late AnimationController _personajeController;
  late Animation<double> _fadeContenido;
  late Animation<Offset> _slideContenido;
  late Animation<double> _fadePersonaje;
  late Animation<Offset> _slidePersonaje;

  // ── Datos de cada paso ────────────────────────────────────────────────────
  final List<_PasoTutorial> _pasos = [
    _PasoTutorial(
      emoji: "👋",
      titulo: "¡Bienvenido a\nInmersión Japón!",
      descripcion:
          "Soy tu guía y estoy aquí para enseñarte todo lo que necesitas saber antes de empezar tu aventura cultural japonesa.",
      colorAcento: Color(0xFFF4A7B9),
      iconoPestana: null,
      nombrePestana: null,
    ),
    _PasoTutorial(
      emoji: "🎮",
      titulo: "El Juego",
      descripcion:
          "Aquí es donde ocurre la magia. Sato-san te pondrá en situaciones reales de Japón y tendrás que elegir la respuesta culturalmente correcta. Puedes elegir entre nivel fácil, medio y difícil.",
      colorAcento: Color(0xFFC0392B),
      iconoPestana: Icons.videogame_asset_rounded,
      nombrePestana: "Juego",
    ),
    _PasoTutorial(
      emoji: "📖",
      titulo: "Tu Diccionario",
      descripcion:
          "Cada término japonés que encuentres en los retos puedes guardarlo aquí. Con el tiempo construirás tu propio diccionario personal de japonés.",
      colorAcento: Color(0xFF5B8CDD),
      iconoPestana: Icons.book_rounded,
      nombrePestana: "Dicc",
    ),
    _PasoTutorial(
      emoji: "📝",
      titulo: "Repaso de Errores",
      descripcion:
          "Cada vez que falles un reto, quedará registrado aquí. Es tu guía personal para repasar lo que necesitas mejorar. ¡Los errores son parte del aprendizaje!",
      colorAcento: Color(0xFFC9A96E),
      iconoPestana: Icons.history_edu_rounded,
      nombrePestana: "Errores",
    ),
    _PasoTutorial(
      emoji: "🗾",
      titulo: "Explora Japón",
      descripcion:
          "Descubre Japón más allá de los retos. Noticias reales, píldoras culturales y curiosidades del idioma japonés actualizadas para que siempre tengas algo nuevo que aprender.",
      colorAcento: Color(0xFF4CAF50),
      iconoPestana: Icons.explore_rounded,
      nombrePestana: "Japón",
    ),
    _PasoTutorial(
      emoji: "⛩️",
      titulo: "Tu Perfil",
      descripcion:
          "Aquí puedes ver tu progreso, tu rango cultural y tus puntos. Cuanto más aciertes, más subirás de Gaijin a Sensei. ¡Ya estás listo para empezar!",
      colorAcento: Color(0xFFF4A7B9),
      iconoPestana: Icons.account_circle_rounded,
      nombrePestana: "Perfil",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _personajeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeContenido = CurvedAnimation(
      parent: _entradaController,
      curve: Curves.easeOut,
    );
    _slideContenido = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entradaController,
      curve: Curves.easeOutCubic,
    ));

    _fadePersonaje = CurvedAnimation(
      parent: _personajeController,
      curve: Curves.easeOut,
    );
    _slidePersonaje = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _personajeController,
      curve: Curves.easeOutCubic,
    ));

    _entradaController.forward();
    _personajeController.forward();
  }

  @override
  void dispose() {
    _entradaController.dispose();
    _personajeController.dispose();
    super.dispose();
  }

  void _siguiente() {
    if (_pasoActual < _pasos.length - 1) {
      _entradaController.reset();
      setState(() => _pasoActual++);
      _entradaController.forward();
    } else {
      _entrarALaApp();
    }
  }

  void _saltar() => _entrarALaApp();

  void _entrarALaApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            ContenedorPrincipal(controlador: widget.controlador),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    final paso = _pasos[_pasoActual];
    final size = MediaQuery.of(context).size;
    final esPrimero = _pasoActual == 0;
    final esUltimo = _pasoActual == _pasos.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Fondo con gradiente de color del paso actual ──────────────
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    paso.colorAcento.withOpacity(0.12),
                    const Color(0xFF0D0D0D),
                  ],
                ),
              ),
            ),
          ),

          // ── Botón saltar ──────────────────────────────────────────────
          if (!esUltimo)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 20,
              child: TextButton(
                onPressed: _saltar,
                child: Text(
                  "Saltar",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ── Contenido principal ───────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
               SizedBox(height: 24 * escala),

                // ── Indicadores de paso ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pasos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _pasoActual ? 24 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _pasoActual
                            ? paso.colorAcento
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

               SizedBox(height: 32 * escala),  

                // ── Personaje irasutoya ───────────────────────────────
                SlideTransition(
                  position: _slidePersonaje,
                  child: FadeTransition(
                    opacity: _fadePersonaje,
                    child: SizedBox(
                      height: size.height * 0.32,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo de color detrás del personaje
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  paso.colorAcento.withOpacity(0.18),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Personaje
                          Image.asset(
                            'assets/imagenes/presentadora_aplicacion.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              size: 120,
                              color: paso.colorAcento.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

               SizedBox(height: 8 * escala),

                // ── Burbuja de diálogo ────────────────────────────────
                Expanded(
                  child: SlideTransition(
                    position: _slideContenido,
                    child: FadeTransition(
                      opacity: _fadeContenido,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Icono de pestana (pasos 2-6)
                            if (paso.iconoPestana != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: paso.colorAcento.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: paso.colorAcento.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      paso.iconoPestana,
                                      color: paso.colorAcento,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      paso.nombrePestana!,
                                      style: TextStyle(
                                        color: paso.colorAcento,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                             SizedBox(height: 16 * escala),
                            ] else ...[
                              // Emoji para la bienvenida
                              Text(
                                paso.emoji,
                                style: const TextStyle(fontSize: 36),
                              ),
                             SizedBox(height: 12  * escala),
                            ],

                            // Título
                            Text(
                              paso.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFDFAF5),
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: 0.5,
                              ),
                            ),

                           SizedBox(height: 16 * escala),

                            // Descripción en burbuja
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: paso.colorAcento.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                paso.descripcion,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 15,
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Botón siguiente / empezar ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: GestureDetector(
                    onTap: _siguiente,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            paso.colorAcento,
                            paso.colorAcento.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: paso.colorAcento.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              esUltimo ? "¡Empezar aventura!" : "Siguiente",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                             SizedBox(width: 8  * escala),
                            Icon(
                              esUltimo
                                  ? Icons.auto_awesome_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modelo de datos de cada paso ──────────────────────────────────────────────
class _PasoTutorial {
  final String emoji;
  final String titulo;
  final String descripcion;
  final Color colorAcento;
  final IconData? iconoPestana;
  final String? nombrePestana;

  const _PasoTutorial({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.colorAcento,
    required this.iconoPestana,
    required this.nombrePestana,
  });
}
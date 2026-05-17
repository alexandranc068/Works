import 'package:flutter/material.dart';
import '../controladores/logica_juego.dart';
import '../modelos/escena_modelo.dart';

// ─── Paleta japonesa ───────────────────────────────────────────────────────────
// Sakura: #F4A7B9  Dorado: #C9A96E  Crema: #FDFAF5
// Rojo torii: #C0392B  Oscuro: #1a0a0a
// ─────────────────────────────────────────────────────────────────────────────

class PantallaJuegoVista extends StatefulWidget {
  final LogicaJuego controlador;
  const PantallaJuegoVista({super.key, required this.controlador});

  @override
  State<PantallaJuegoVista> createState() => _PantallaJuegoVistaState();
}

class _PantallaJuegoVistaState extends State<PantallaJuegoVista>
    with SingleTickerProviderStateMixin {
  EscenaModelo? escenaActual;
  bool cargandoSituacion = true;
  bool evaluandoPro = false;
  String animoSatoSan = "feliz";
  int puntosContextoActual = 0;
  int puntosTotales = 0;
  double impactoCulturalActual = 0.5;
  final TextEditingController _controllerIA = TextEditingController();

  late AnimationController _entradaAnim;
  late Animation<double> _fadePersonaje;
  late Animation<Offset> _slideBocadillo;

  Color _colorAnimo() {
    switch (animoSatoSan) {
      case "enfadado": return const Color(0xFFC0392B);
      case "serio":    return const Color(0xFFC9A96E);
      case "triste":   return const Color(0xFF7f8c8d);
      default:         return const Color(0xFF27ae60);
    }
  }

  String _emojiAnimo() {
    if (evaluandoPro) return "⏳";
    switch (animoSatoSan) {
      case "enfadado": return "😠";
      case "serio":    return "😐";
      case "triste":   return "😔";
      default:         return "😊";
    }
  }

  void _actualizarEstadoLocal() {
    if (widget.controlador.jugadorActual != null) {
      puntosContextoActual = widget.controlador.jugadorActual!
          .progresoContextos[widget.controlador.contextoSeleccionado] ?? 0;
      puntosTotales = widget.controlador.jugadorActual!.puntosCultura;
      impactoCulturalActual = widget.controlador.jugadorActual!.impactoCultural;
    }
  }

  @override
  void initState() {
    super.initState();
    _entradaAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadePersonaje =
        CurvedAnimation(parent: _entradaAnim, curve: Curves.easeOut);
    _slideBocadillo = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaAnim, curve: Curves.easeOut));

    _actualizarEstadoLocal();
    _generarNuevaSituacion();
  }

  @override
  void dispose() {
    _entradaAnim.dispose();
    _controllerIA.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PantallaJuegoVista oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controlador != widget.controlador) {
      setState(() => _actualizarEstadoLocal());
    }
  }

  Future<void> _generarNuevaSituacion() async {
    if (!mounted) return;
    setState(() { cargandoSituacion = true; animoSatoSan = "feliz"; });
    final nuevaEscena = await widget.controlador.obtenerEscena();
    if (!mounted) return;
    await widget.controlador.recargarDatosUsuario();
    setState(() {
      escenaActual = nuevaEscena;
      cargandoSituacion = false;
      _controllerIA.clear();
      evaluandoPro = false;
      _actualizarEstadoLocal();
    });
    _entradaAnim.forward(from: 0);
  }

  void _mostrarSnack(String texto, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(texto, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _mostrarCambioPuntos(int diferencia) {
    if (diferencia == 0) return;
    _mostrarSnack(
      diferencia > 0 ? "+$diferencia puntos de cultura" : "$diferencia puntos",
      diferencia > 0 ? const Color(0xFF27ae60) : const Color(0xFFC0392B),
    );
  }

  void _mostrarCambioImpacto(double cambio) {
    if (cambio == 0) return;
    int pct = (cambio * 100).abs().toInt();
    _mostrarSnack(
      "Impacto cultural: $pct% ${cambio > 0 ? '↑' : '↓'}",
      const Color(0xFFC9A96E),
    );
  }

  void _mostrarGlosario() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFAF5),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0xFFC9A96E).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text("🏮 Vocabulario de la escena",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: Color(0xFF1a0a0a), letterSpacing: 1)),
          Divider(color: const Color(0xFFC9A96E).withOpacity(0.3), height: 24),
          if (escenaActual?.glosario.isEmpty ?? true)
            const Padding(padding: EdgeInsets.all(20),
                child: Text("No hay términos nuevos en esta escena.",
                    style: TextStyle(color: Color(0xFF7f8c8d))))
          else
            Flexible(
              child: ListView(shrinkWrap: true,
                  children: escenaActual!.glosario.map((t) => ListTile(
                    leading: const Icon(Icons.translate,
                        color: Color(0xFFC0392B), size: 20),
                    title: Text(t.termino,
                        style: const TextStyle(fontWeight: FontWeight.w700,
                            color: Color(0xFF1a0a0a))),
                    subtitle: Text(t.significado,
                        style: const TextStyle(color: Color(0xFF5d4e37))),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_add_outlined,
                          color: Color(0xFFC9A96E), size: 20),
                      onPressed: () async {
                        await widget.controlador.guardarPalabraEnGlosarioPersonal(t);
                        Navigator.pop(context);
                        _mostrarSnack("✅ Guardada en Diccionario", const Color(0xFF27ae60));
                      },
                    ),
                  )).toList()),
            ),
        ]),
      ),
    );
  }

  void _manejarEnvioPro() async {
    String respuesta = _controllerIA.text.trim();
    if (respuesta.isEmpty) return;
    setState(() => evaluandoPro = true);

    final resultado = await widget.controlador
        .evaluarRespuestaProIA(escenaActual!.texto, respuesta);
    if (!mounted) return;

    bool esCorrecto      = resultado['esCorrecta'] ?? false;
    int puntosObtenidos  = resultado['puntos'] ?? (esCorrecto ? 20 : -10);
    String animo         = resultado['animo'] ?? (esCorrecto ? "feliz" : "enfadado");
    double cambioImpacto = esCorrecto ? 0.1 : -0.15;

    await widget.controlador.guardarRespuestaUsuario(
      situacion: escenaActual!.texto, respuesta: respuesta,
      fueCorrecta: esCorrecto, puntosObtenidos: puntosObtenidos,
      cambioImpacto: cambioImpacto, animo: animo,
    );
    await widget.controlador.guardarProgresoEnNube(puntosObtenidos, cambioImpacto);
    if (!mounted) return;

    setState(() { animoSatoSan = animo; evaluandoPro = false; _actualizarEstadoLocal(); });
    widget.controlador.precargarSiguienteEscena(); // ⚡ precarga mientras el usuario lee el feedback
    _mostrarCambioPuntos(puntosObtenidos);
    _mostrarCambioImpacto(cambioImpacto);
    widget.controlador.registrarEnGuiaRepaso(
      situacion: escenaActual!.texto, opcionElegida: respuesta,
      explicacion: resultado['feedback'] ?? "",
      esCorrecto: esCorrecto, puntosGanados: puntosObtenidos,
      cambioImpacto: cambioImpacto, animoRespuesta: animo,
    );
    _mostrarFeedback(resultado['feedback'] ?? "", esCorrecto);
  }

  void _responderOpcion(OpcionModelo opcion) async {
    int puntosObtenidos  = opcion.puntosCultura;
    double cambioImpacto = opcion.impactoCultural;
    String nuevoAnimo    = opcion.esCorrecta ? "feliz" : "enfadado";

    await widget.controlador.guardarRespuestaUsuario(
      situacion: escenaActual!.texto, respuesta: opcion.texto,
      fueCorrecta: opcion.esCorrecta, puntosObtenidos: puntosObtenidos,
      cambioImpacto: cambioImpacto, animo: nuevoAnimo,
    );
    await widget.controlador.guardarProgresoEnNube(puntosObtenidos, cambioImpacto);
    if (!mounted) return;

    setState(() { animoSatoSan = nuevoAnimo; _actualizarEstadoLocal(); });
    widget.controlador.precargarSiguienteEscena(); // ⚡ precarga mientras el usuario lee el feedback
    _mostrarCambioPuntos(puntosObtenidos);
    _mostrarCambioImpacto(cambioImpacto);
    widget.controlador.registrarEnGuiaRepaso(
      situacion: escenaActual!.texto, opcionElegida: opcion.texto,
      explicacion: opcion.retroalimentacion, esCorrecto: opcion.esCorrecta,
      puntosGanados: puntosObtenidos, cambioImpacto: cambioImpacto,
      animoRespuesta: nuevoAnimo,
    );
    _mostrarFeedback(opcion.retroalimentacion, opcion.esCorrecta);
  }

  void _mostrarFeedback(String mensaje, bool fueCorrecto) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFDFAF5),
        child: SingleChildScrollView(         // 👈 AÑADE ESTO
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(fueCorrecto ? "🌸" : "⛩️",
          style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 8),
      Text(fueCorrecto ? "¡Muy bien!" : "Nota de etiqueta",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: fueCorrecto
                  ? const Color(0xFF27ae60)
                  : const Color(0xFFC0392B),
              letterSpacing: 1)),
      const SizedBox(height: 12),
      Container(height: 1,
          color: const Color(0xFFC9A96E).withOpacity(0.3)),
      const SizedBox(height: 12),
      Text(mensaje, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.6,
              color: Color(0xFF3d2b1f))),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4A7B9).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFC9A96E).withOpacity(0.25)),
        ),
        child: Column(children: [
          _statRow("📊 ${widget.controlador.contextoSeleccionado}",
              "$puntosContextoActual pts"),
          const SizedBox(height: 4),
          _statRow("🏆 Puntos totales", "$puntosTotales"),
          const SizedBox(height: 4),
          _statRow("🎭 Impacto cultural",
              "${(impactoCulturalActual * 100).toInt()}%"),
        ]),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF4A7B9).withOpacity(0.85),
            foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: () {
            Navigator.pop(context);
            _generarNuevaSituacion();
          },
          child: const Text("Siguiente reto",
              style: TextStyle(
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
          ),
        ]),
      ),           // 👈 CIERRA Padding
    ),             // 👈 CIERRA SingleChildScrollView
  )
  );
}

  Widget _statRow(String label, String valor) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF7f6a55))),
      Text(valor, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w700, color: Color(0xFF3d2b1f))),
    ],
  );

  // ══════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Pantalla de carga con fondo de contexto
    if (cargandoSituacion) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(widget.controlador.obtenerFondoContexto()),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            color: Colors.black.withOpacity(0.55),
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(
                    color: Color(0xFFF4A7B9), strokeWidth: 2),
                SizedBox(height: 20),
                Text("Preparando la escena...",
                    style: TextStyle(color: Color(0xFFC9A96E),
                        letterSpacing: 2, fontSize: 13)),
              ]),
            ),
          ),
        ),
      );
    }

    final nombresContexto = {
      "templos": "Espiritual", "restaurante": "Restaurante",
      "amistad": "Social",    "trabajo": "Laboral",
    };
    final nombreCtx =
        nombresContexto[widget.controlador.contextoSeleccionado]
        ?? widget.controlador.contextoSeleccionado;
    final fondo     = widget.controlador.obtenerFondoContexto();
    final personaje = widget.controlador.obtenerPersonajeContexto();

    return Scaffold(
      extendBodyBehindAppBar: true,

      // ── AppBar translúcido ─────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFF4A7B9), size: 20),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            "${widget.controlador.jugadorActual?.nombre ?? 'Jugador'} · $nombreCtx · ${widget.controlador.nivelDificultad.toUpperCase()}",
            style: TextStyle(fontSize: 11,
                color: const Color(0xFFF4A7B9).withOpacity(0.85),
                letterSpacing: 1),
          ),
          Text("✦ $puntosContextoActual puntos",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                  color: Color(0xFFC9A96E), letterSpacing: 1)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate,
                color: Color(0xFFC9A96E), size: 22),
            onPressed: _mostrarGlosario,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFFF4A7B9), size: 22),
            onPressed: _generarNuevaSituacion,
          ),
        ],
      ),

      body: Column(children: [

        // ── BANDA DE FONDO con barra de impacto ───────────
        SizedBox(
          height: 140 + MediaQuery.of(context).padding.top,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(fondo, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12, left: 16, right: 16,
              child: _BarraImpacto(valor: impactoCulturalActual),
            ),
          ]),
        ),

        // ── ZONA CENTRAL: personaje + bocadillo ───────────
        Expanded(
          child: Container(
            color: const Color(0xFFFDFAF5),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(children: [

                // Personaje irasutoya — sin fondo, tamaño medio
                FadeTransition(
                  opacity: _fadePersonaje,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      SizedBox(
                        height: 160,
                        child: Image.asset(
                          personaje,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person, size: 80, color: Color(0xFFC9A96E)),
                        ),
                      ),
                      // Emoji de ánimo en esquina superior derecha
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _colorAnimo(),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6)],
                        ),
                        child: Text(_emojiAnimo(),
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Bocadillo centrado debajo del personaje
                SlideTransition(
                  position: _slideBocadillo,
                  child: FadeTransition(
                    opacity: _fadePersonaje,
                    child: _Bocadillo(
                      personaje: escenaActual!.personaje,
                      texto: escenaActual!.texto,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),

        // ── ZONA DE RESPUESTAS ─────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12, offset: const Offset(0, -3))],
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Tirador decorativo
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A96E).withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              if (widget.controlador.nivelDificultad == "pro") ...[
                TextField(
                  controller: _controllerIA,
                  enabled: !evaluandoPro,
                  maxLines: 3,
                  style: const TextStyle(
                      color: Color(0xFF3d2b1f), fontSize: 14, height: 1.5),
                  decoration: InputDecoration(
                    hintText: "Escribe tu respuesta a Sato-san...",
                    hintStyle: TextStyle(
                        color: const Color(0xFF7f6a55).withOpacity(0.6),
                        fontSize: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                          color: const Color(0xFFC9A96E).withOpacity(0.35)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                          color: Color(0xFFF4A7B9), width: 1.5),
                    ),
                    filled: true, fillColor: const Color(0xFFFFF8F0),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFF4A7B9).withOpacity(0.85),
                      foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: evaluandoPro ? null : _manejarEnvioPro,
                    child: evaluandoPro
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text("Enviar a Sato-san",
                            style: TextStyle(fontWeight: FontWeight.w700,
                                letterSpacing: 1.5, fontSize: 14)),
                  ),
                ),
              ] else ...[
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.32),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: escenaActual!.opciones
                          .asMap()
                          .entries
                          .map((e) => _OpcionBoton(
                                opcion: e.value,
                                indice: e.key,
                                onPressed: () => _responderOpcion(e.value),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _BarraImpacto extends StatelessWidget {
  final double valor;
  const _BarraImpacto({required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFC9A96E).withOpacity(0.25), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("🌏 Inmersión Cultural",
              style: TextStyle(fontSize: 11, color: Color(0xFFC9A96E),
                  letterSpacing: 1, fontWeight: FontWeight.w600)),
          Text("${(valor * 100).toInt()}%",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: Color(0xFFF4A7B9))),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: valor,
            color: valor > 0.5
                ? const Color(0xFF27ae60)
                : const Color(0xFFC9A96E),
            backgroundColor: Colors.white.withOpacity(0.15),
            minHeight: 7,
          ),
        ),
        const SizedBox(height: 3),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("👶 Novato",     style: TextStyle(fontSize: 9, color: Color(0xAAFFFFFF))),
          Text("🧑‍🎓 Conocedor", style: TextStyle(fontSize: 9, color: Color(0xAAFFFFFF))),
          Text("👑 Experto",   style: TextStyle(fontSize: 9, color: Color(0xAAFFFFFF))),
        ]),
      ]),
    );
  }
}

/// Bocadillo centrado debajo del personaje con rabillo apuntando arriba
class _Bocadillo extends StatelessWidget {
  final String personaje;
  final String texto;
  const _Bocadillo({required this.personaje, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Rabillo apuntando al personaje (arriba)
        Positioned(
          top: -10,
          child: CustomPaint(
            size: const Size(20, 12),
            painter: _RabilloArribaPainter(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFFF4A7B9).withOpacity(0.6), width: 1.5),
            boxShadow: [BoxShadow(
                color: const Color(0xFFF4A7B9).withOpacity(0.15),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Nombre del personaje con barra roja
            Row(children: [
              Container(
                width: 4, height: 16,
                decoration: BoxDecoration(
                    color: const Color(0xFFC0392B),
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(personaje,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                      color: Color(0xFFC0392B), letterSpacing: 1)),
            ]),
            const SizedBox(height: 10),
            Container(height: 0.5,
                color: const Color(0xFFC9A96E).withOpacity(0.35)),
            const SizedBox(height: 10),
            Text(texto,
                style: const TextStyle(fontSize: 14, height: 1.65,
                    color: Color(0xFF2c1a0e))),
          ]),
        ),
      ],
    );
  }
}

class _RabilloArribaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFFF4A7B9).withOpacity(0.6)
      ..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(_RabilloArribaPainter old) => false;
}

class _OpcionBoton extends StatelessWidget {
  final OpcionModelo opcion;
  final int indice;
  final VoidCallback onPressed;
  const _OpcionBoton(
      {required this.opcion, required this.indice, required this.onPressed});
  static const _letras = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final letra = indice < _letras.length ? _letras[indice] : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF3d2b1f),
          side: BorderSide(
              color: const Color(0xFFC9A96E).withOpacity(0.5), width: 1),
          backgroundColor: const Color(0xFFFFF8F0),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          alignment: Alignment.centerLeft,
        ),
        onPressed: onPressed,
        child: Row(children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF4A7B9).withOpacity(0.25),
              border: Border.all(
                  color: const Color(0xFFF4A7B9).withOpacity(0.6), width: 1),
            ),
            child: Center(
              child: Text(letra,
                  style: const TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: Color(0xFFC0392B))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(opcion.texto,
              style: const TextStyle(fontSize: 13, height: 1.4))),
        ]),
      ),
    );
  }
}
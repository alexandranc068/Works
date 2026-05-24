import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../controladores/logica_juego.dart';

// ─── Paleta japonesa ───────────────────────────────────────────────────────────
// Sakura: #F4A7B9  Dorado: #C9A96E  Crema: #FDFAF5
// Rojo torii: #C0392B  Oscuro: #1a0a0a
// ─────────────────────────────────────────────────────────────────────────────

class PantallaPerfilVista extends StatefulWidget {
  final LogicaJuego controlador;
  const PantallaPerfilVista({super.key, required this.controlador});

  @override
  State<PantallaPerfilVista> createState() => _PantallaPerfilVistaState();
}



class _PantallaPerfilVistaState extends State<PantallaPerfilVista> {

  @override
  void initState() {
    super.initState();
    // Recarga datos frescos de Firebase al entrar
    widget.controlador.recargarDatosUsuario().then((_) {
      if (mounted) setState(() {});
    });
  }

  // ══════════════════════════════════════════════════════
  //  SELECTOR DE AVATARES (IRASUTOYA)
  // ══════════════════════════════════════════════════════
  void _mostrarSelectorAvatares() {
    final avatares = [
      'assets/imagenes/chico_graduado_foto_perfil.png',
      'assets/imagenes/chica_graduada_fotot_perfil.png',
      'assets/imagenes/chica_estudainte_foto_perfil.png',
      'assets/imagenes/estudiante_foto_perfil.png',
      'assets/imagenes/sushi_women_foto_perfil.png',
      'assets/imagenes/susshi_man_foto_perfil.png',
      'assets/imagenes/sushi_foto_perfil.png',
      'assets/imagenes/perro_estudiando_foto_perfil.png',
      'assets/imagenes/hanabi_chica_foto_perfil.png',
      'assets/imagenes/hanabi_hombre_foto_perfil.png',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFDFAF5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🏮 Selecciona tu Avatar",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF3d2b1f),
                letterSpacing: 1.2,
              ),
            ),
           SizedBox(height: 20),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, 
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                itemCount: avatares.length,
                itemBuilder: (context, index) {
                  final esSeleccionado = widget.controlador.jugadorActual?.fotoPerfil == avatares[index];
                  
                  return GestureDetector(
                    onTap: () async {
                      await widget.controlador.actualizarFotoPerfil(avatares[index]);
                      if (mounted) {
                        Navigator.pop(context);
                        setState(() {}); 
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: esSeleccionado ? const Color(0xFFC0392B) : const Color(0xFFC9A96E).withOpacity(0.3),
                          width: esSeleccionado ? 4 : 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          avatares[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
           SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  //  DIAGNÓSTICO CON IA — sin cambios de lógica
  // ══════════════════════════════════════════════════════
  Future<void> _mostrarDiagnosticoIA() async {
    final usuario = widget.controlador.jugadorActual;
    if (usuario == null) return;

    final int puntos         = usuario.puntosCultura;
    final double impacto     = usuario.impactoCultural;
    final Map<String, int> contextos = usuario.progresoContextos;
    final List<String> animos = usuario.historialAnimos;
    final int totalRespuestas  = animos.length;
    final int aciertos         = animos.where((a) => a == "feliz").length;
    final double pctAcierto    = totalRespuestas > 0 ? aciertos / totalRespuestas : 0.0;
    final String rango         = widget.controlador.obtenerRangoActual();
    final int ptsTemplos       = contextos['templos']     ?? 0;
    final int ptsRestaurante   = contextos['restaurante'] ?? 0;
    final int ptsAmistad       = contextos['amistad']     ?? 0;
    final int ptsTrabajo       = contextos['trabajo']     ?? 0;

    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const _DialogoCargando());

    String diagnostico;
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(temperature: 0.8),
      );
      final prompt = '''
Eres Sato-san, un sabio japonés amable y algo ceremonioso que evalúa si un extranjero está preparado para visitar Japón y respetar su cultura.

Estos son los datos reales del jugador "${usuario.nombre}":
- Rango actual: $rango
- Puntos totales de cultura: $puntos
- Nivel de inmersión cultural: ${(impacto * 100).toInt()}%
- Porcentaje de aciertos en situaciones: ${(pctAcierto * 100).toInt()}% (de $totalRespuestas respuestas)
- Módulo Espiritual (templos): $ptsTemplos / 500 pts
- Módulo Restaurante y Comida: $ptsRestaurante / 500 pts
- Módulo Vida Social y Amistad: $ptsAmistad / 500 pts
- Módulo Protocolo Laboral: $ptsTrabajo / 500 pts

Basándote ÚNICAMENTE en estos datos reales, redacta un diagnóstico personalizado en español con el siguiente formato EXACTO:

1. Saludo breve de Sato-san al jugador por su nombre (1 oración, tono cálido y ceremonioso).
2. Veredicto general: indica con claridad si está "No preparado", "Poco preparado", "Moderadamente preparado", "Bien preparado" o "Totalmente preparado" para viajar a Japón respetando su cultura. Justifícalo en 2-3 oraciones basándote en sus números.
3. Fortalezas: menciona 1-2 módulos donde destaca (solo si tiene puntos > 100), con una frase concreta por módulo.
4. Áreas de mejora: menciona 1-2 módulos donde flojea (puntos bajos o aciertos bajos), con un consejo práctico por módulo.
5. Frase de cierre motivadora de Sato-san en japonés seguida de su traducción entre paréntesis.

Importante: sé específico con los números reales. No inventes datos. El tono debe ser el de un sensei japonés paciente y sabio. Máximo 200 palabras en total.
''';
      final response = await model.generateContent([Content.text(prompt)]);
      diagnostico = response.text?.trim() ?? "No he podido generar el diagnóstico. Inténtalo de nuevo.";
    } catch (e) {
      diagnostico = "Sato-san no ha podido conectar con su sabiduría ahora mismo. Por favor, inténtalo más tarde.";
    }

    if (mounted) Navigator.of(context).pop();
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => _DialogoDiagnostico(
          nombre: usuario.nombre, diagnostico: diagnostico,
          impacto: impacto, pctAcierto: pctAcierto, puntos: puntos,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // 1. Obtener la altura disponible
  final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    final usuario  = widget.controlador.jugadorActual;
    final rango    = widget.controlador.obtenerRangoActual();

    final int puntosTotales         = usuario?.puntosCultura   ?? 0;
    final double impacto            = usuario?.impactoCultural ?? 0.5;
    final Map<String, int> contextos = usuario?.progresoContextos ?? {};
    final List<String> animos       = usuario?.historialAnimos ?? [];
    final int totalRespuestas        = animos.length;
    final int aciertos               = animos.where((a) => a == "feliz").length;
    final double porcentajeAcierto   =
        totalRespuestas > 0 ? aciertos / totalRespuestas : 0.0;

    // Info por contexto — paleta japonesa
    final contextoInfo = {
      "templos":     {"nombre": "Módulo Espiritual",     "icono": Icons.temple_hindu, "color": const Color(0xFFC9A96E)},
      "restaurante": {"nombre": "Restaurante y Comida",  "icono": Icons.restaurant,   "color": const Color(0xFFF4A7B9)},
      "amistad":     {"nombre": "Vida Social y Amistad", "icono": Icons.people,        "color": const Color(0xFF87CEEB)},
      "trabajo":     {"nombre": "Protocolo Laboral",     "icono": Icons.business,      "color": const Color(0xFFA8D8A8)},
    };

    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF5),

      appBar: AppBar(
        backgroundColor: const Color(0xFFC0392B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Mi Perfil Cultural",
            style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => widget.controlador
                .recargarDatosUsuario()
                .then((_) { if (mounted) setState(() {}); }),
            tooltip: "Actualizar",
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(children: [

          // ── CABECERA ─────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC0392B), Color(0xFFE8736A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(children: [
              // Avatar Interactivo de Irasutoya
              GestureDetector(
                onTap: _mostrarSelectorAvatares,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.white38, width: 3),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.2), blurRadius: 12)],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          usuario?.fotoPerfil ?? 'assets/imagenes/foto_defecto_foto_perfil.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/imagenes/foto_defecto_foto_perfil.png',
                            fit: BoxFit.cover
                        ),
                      ),
                    ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC9A96E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
             SizedBox(height: 12 * escala),
              Text(usuario?.nombre ?? "Usuario",
                  style: const TextStyle(fontSize: 24, color: Colors.white,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
             SizedBox(height: 6 * escala),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38, width: 1),
                ),
                child: Text(rango,
                    style: const TextStyle(fontSize: 13, color: Colors.white,
                        fontWeight: FontWeight.w600, letterSpacing: 1)),
              ),
            ]),
          ),

          Container(
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFDFAF5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(children: [

              Row(children: [
                _TarjetaStat(titulo: "🏆 Puntos", valor: "$puntosTotales",
                    color: const Color(0xFFC9A96E)),
                const SizedBox(width: 12),
                _TarjetaStat(titulo: "🎯 Aciertos",
                    valor: "${(porcentajeAcierto * 100).toInt()}%",
                    color: const Color(0xFF27ae60)),
              ]),
             SizedBox(height: 12  * escala),
              Row(children: [
                _TarjetaStat(titulo: "📝 Respuestas",
                    valor: "$totalRespuestas",
                    color: const Color(0xFF87CEEB)),
                const SizedBox(width: 12),
                _TarjetaStat(titulo: "🌏 Inmersión",
                    valor: "${(impacto * 100).toInt()}%",
                    color: const Color(0xFFF4A7B9)),
              ]),

             SizedBox(height: 24 * escala),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFFC9A96E).withOpacity(0.25)),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("🌏 Nivel de Inmersión Cultural",
                          style: TextStyle(fontWeight: FontWeight.w700,
                              fontSize: 14, color: Color(0xFF3d2b1f))),
                      Text("${(impacto * 100).toInt()}%",
                          style: const TextStyle(fontWeight: FontWeight.w700,
                              color: Color(0xFFC9A96E), fontSize: 14)),
                    ],
                  ),
                 SizedBox(height: 10 * escala),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: impacto, minHeight: 12,
                      color: impacto > 0.6
                          ? const Color(0xFF27ae60)
                          : impacto > 0.3
                              ? const Color(0xFFC9A96E)
                              : const Color(0xFFC0392B),
                      backgroundColor:
                          const Color(0xFFC9A96E).withOpacity(0.12),
                    ),
                  ),
                 SizedBox(height: 6   * escala),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("👶 Novato",
                          style: TextStyle(fontSize: 11, color: Color(0xFF9e8b7a))),
                      Text("🧑‍🎓 Conocedor",
                          style: TextStyle(fontSize: 11, color: Color(0xFF9e8b7a))),
                      Text("👑 Experto",
                          style: TextStyle(fontSize: 11, color: Color(0xFF9e8b7a))),
                    ],
                  ),
                ]),
              ),

             SizedBox(height: 24 * escala),

              Row(children: [
                Container(width: 4, height: 18,
                    decoration: BoxDecoration(
                        color: const Color(0xFFC0392B),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text("Progreso por módulo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: Color(0xFF3d2b1f))),
              ]),
             SizedBox(height: 14 * escala),

              ...contextoInfo.entries.map((entry) {
                final key     = entry.key;
                final info    = entry.value;
                final int pts = contextos[key] ?? 0;
                final double progreso = (pts / 500).clamp(0.0, 1.0);
                final color   = info["color"] as Color;
                final icono   = info["icono"] as IconData;
                final nombre  = info["nombre"] as String;
                final String medalla =
                    widget.controlador.obtenerMedallaContexto(key);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.25)),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.15),
                          border: Border.all(
                              color: color.withOpacity(0.3), width: 1)),
                      child: Icon(icono, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(nombre, style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13,
                                color: Color(0xFF3d2b1f))),
                            Text(medalla, style: TextStyle(
                                fontSize: 12, color: color,
                                fontWeight: FontWeight.w700)),
                          ],
                        ),
                       SizedBox(height: 6 * escala),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progreso, minHeight: 8,
                            color: color,
                            backgroundColor: color.withOpacity(0.12),
                          ),
                        ),
                       SizedBox(height: 4 * escala),
                        Text("$pts / 500 pts",
                            style: const TextStyle(fontSize: 11,
                                color: Color(0xFF9e8b7a))),
                      ],
                    )),
                  ]),
                );
              }),

             SizedBox(height: 24 * escala),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _lineaDorada(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text("⛩",
                      style: TextStyle(fontSize: 16,
                          color: const Color(0xFFC9A96E).withOpacity(0.7))),
                ),
                _lineaDorada(),
              ]),

             SizedBox(height: 24 * escala),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a0a0a), Color(0xFF3d1010)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFFC9A96E).withOpacity(0.4), width: 1),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFFC0392B).withOpacity(0.25),
                      blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _mostrarDiagnosticoIA,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFC0392B).withOpacity(0.3),
                            border: Border.all(
                                color: const Color(0xFFC9A96E).withOpacity(0.5)),
                          ),
                          child: const Center(
                            child: Text("佐藤", style: TextStyle(
                                fontSize: 16, color: Colors.white,
                                fontWeight: FontWeight.bold, letterSpacing: 2)),
                          ),
                        ),
                         SizedBox(width: 16 * escala),
                         Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Consultar a Sato-san",
                                style: TextStyle(fontSize: 16, color: Colors.white,
                                    fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            SizedBox(height: 2 * escala),
                            Text("¿Estoy listo para Japón?",
                                style: TextStyle(fontSize: 12,
                                    color: Color(0xFFC9A96E))),
                          ],
                        ),
                         SizedBox(width: 10 * escala),
                        Icon(Icons.chevron_right,
                            color: const Color(0xFFC9A96E).withOpacity(0.7),
                            size: 28),
                      ]),
                    ),
                  ),
                ),
              ),

             SizedBox(height: 32 * escala),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _lineaDorada({double width = 60}) => Container(
    width: width, height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [
        Colors.transparent,
        const Color(0xFFC9A96E).withOpacity(0.6),
        Colors.transparent,
      ]),
    ),
  );
}

class _TarjetaStat extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  const _TarjetaStat(
      {required this.titulo, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
     final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
         SizedBox(height: 6 * escala),
          Text(valor, style: TextStyle(fontSize: 22,
              fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _DialogoCargando extends StatelessWidget {
  const _DialogoCargando();

  @override
  Widget build(BuildContext context) {
     final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFFDFAF5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1a0a0a), Color(0xFF3d1010)],
              ),
              border: Border.all(
                  color: const Color(0xFFC9A96E).withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(
                  color: const Color(0xFFC0392B).withOpacity(0.3),
                  blurRadius: 12)],
            ),
            child: const Center(child: Text("佐藤", style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
         SizedBox(height: 20 * escala),
          const Text("Sato-san está meditando...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                  color: Color(0xFF3d2b1f))),
         SizedBox(height: 6 * escala),
          Text("Analizando tu progreso cultural",
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
         SizedBox(height: 24 * escala),
          const CircularProgressIndicator(
              color: Color(0xFFC9A96E), strokeWidth: 2),
        ]),
      ),
    );
  }
}

class _DialogoDiagnostico extends StatelessWidget {
  final String nombre;
  final String diagnostico;
  final double impacto;
  final double pctAcierto;
  final int puntos;

  const _DialogoDiagnostico({
    required this.nombre, required this.diagnostico,
    required this.impacto, required this.pctAcierto, required this.puntos,
  });

  Color get _colorNivel {
    if (impacto >= 0.75) return const Color(0xFF27ae60);
    if (impacto >= 0.5)  return const Color(0xFFC9A96E);
    return const Color(0xFFC0392B);
  }

  String get _emojiNivel {
    if (impacto >= 0.75) return "✅";
    if (impacto >= 0.5)  return "⚠️";
    return "❌";
  }

  String get _etiquetaNivel {
    if (impacto >= 0.75) return "Listo para Japón";
    if (impacto >= 0.5)  return "En progreso";
    return "Necesita mejorar";
  }

  @override
  Widget build(BuildContext context) {
     final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFFDFAF5),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1a0a0a), Color(0xFF3d1010)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC0392B).withOpacity(0.25),
                border: Border.all(
                    color: const Color(0xFFC9A96E).withOpacity(0.5), width: 1.5),
              ),
              child: const Center(child: Text("佐藤", style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold, letterSpacing: 2))),
            ),
           SizedBox(height: 10* escala),
            const Text("Sato-san", style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            Text("Diagnóstico Cultural",
                style: TextStyle(color: const Color(0xFFC9A96E).withOpacity(0.8),
                    fontSize: 12, letterSpacing: 1)),
          ]),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _colorNivel.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _colorNivel.withOpacity(0.35)),
                ),
                child: Row(children: [
                  Text(_emojiNivel, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_etiquetaNivel, style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: _colorNivel)),
                    Text("Inmersión: ${(impacto * 100).toInt()}%  •  Aciertos: ${(pctAcierto * 100).toInt()}%",
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ]),
                ]),
              ),
             SizedBox(height: 16 * escala),
              Text("Evaluación de Sato-san",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Colors.grey[600], letterSpacing: 0.5)),
             SizedBox(height: 8 * escala),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFC9A96E).withOpacity(0.2)),
                ),
                child: Text(diagnostico,
                    style: const TextStyle(fontSize: 14, height: 1.65,
                        color: Color(0xFF3d2b1f))),
              ),
             SizedBox(height: 16  * escala),
              Row(children: [
                _chipStat("🏆 $puntos pts", const Color(0xFFC9A96E)),
                const SizedBox(width: 8),
                _chipStat("🌏 ${(impacto * 100).toInt()}%", const Color(0xFF87CEEB)),
                const SizedBox(width: 8),
                _chipStat("🎯 ${(pctAcierto * 100).toInt()}%", const Color(0xFF27ae60)),
              ]),
             SizedBox(height: 20 * escala),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white, elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Arigato, Sato-san 🙏",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _chipStat(String texto, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(child: Text(texto,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: color.withOpacity(0.9)))),
    ),
  );
}



// ══════════════════════════════════════════════════════
//  DIÁLOGO: CARGANDO
// ══════════════════════════════════════════════════════


// ══════════════════════════════════════════════════════
//  DIÁLOGO: RESULTADO DEL DIAGNÓSTICO
// ══════════════════════════════════════════════════════


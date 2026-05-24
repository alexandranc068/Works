import 'package:flutter/material.dart';
import '../controladores/logica_juego.dart';

class PantallaRepasoVista extends StatelessWidget {
  final LogicaJuego controlador;
  const PantallaRepasoVista({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Fondo con imagen señales ──────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/imagenes/persona_señales_errores.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // ── Gradiente oscuro encima ───────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC0D0D0D),
                    Color(0xE60D0D0D),
                    Color(0xF50D0D0D),
                  ],
                  stops: [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // ── Contenido ─────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "復習",
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFFC0392B).withOpacity(0.9),
                              letterSpacing: 6,
                            ),
                          ),
                          const Text(
                            "Guía de",
                            style: TextStyle(
                              fontSize: 26,
                              color: Color(0xFFFDFAF5),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Text(
                            "Supervivencia",
                            style: TextStyle(
                              fontSize: 26,
                              color: Color(0xFFF4A7B9),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              height: 0.9,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC0392B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC0392B).withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.history_edu_rounded,
                          color: Color(0xFFC0392B),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),

               SizedBox(height: 8 * escala),

                // ── Línea roja ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC0392B).withOpacity(0.6),
                          const Color(0xFFF4A7B9).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

               SizedBox(height: 16 * escala),

                // ── Lista ─────────────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: controlador.streamGuiaRepaso(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFC0392B),
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error al cargar: ${snapshot.error}",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "学",
                                  style: TextStyle(
                                    fontSize: 72,
                                    color: const Color(0xFFC0392B)
                                        .withOpacity(0.15),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                               SizedBox(height: 12 * escala),
                                Text(
                                  "Aún no tienes consejos.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                               SizedBox(height: 6 * escala),
                                Text(
                                  "¡Juega para aprender!",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.35),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final notas = snapshot.data!;
                      final errores =
                          notas.where((n) => !(n['es_correcta'] ?? false)).length;
                      final aciertos = notas.length - errores;

                      return Column(
                        children: [
                          // Resumen aciertos/errores
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                _ChipResumen(
                                  icono: Icons.check_circle_rounded,
                                  texto: "$aciertos aciertos",
                                  color: const Color(0xFF4CAF50),
                                ),
                                const SizedBox(width: 8),
                                _ChipResumen(
                                  icono: Icons.cancel_rounded,
                                  texto: "$errores errores",
                                  color: const Color(0xFFC0392B),
                                ),
                              ],
                            ),
                          ),
                         SizedBox(height: 12 * escala),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: notas.length,
                              itemBuilder: (context, index) {
                                final nota = notas[index];
                                return _TarjetaRepaso(nota: nota);
                              },
                            ),
                          ),
                        ],
                      );
                    },
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

// ── Chip resumen ──────────────────────────────────────────────────────────────
class _ChipResumen extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;
  const _ChipResumen({
    required this.icono,
    required this.texto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de repaso expandible ──────────────────────────────────────────────
class _TarjetaRepaso extends StatefulWidget {
  final Map<String, dynamic> nota;
  const _TarjetaRepaso({required this.nota});

  @override
  State<_TarjetaRepaso> createState() => _TarjetaRepasoState();
}

class _TarjetaRepasoState extends State<_TarjetaRepaso> {
  bool _expandida = false;

  @override
  Widget build(BuildContext context) {
    final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    final nota = widget.nota;
    final esCorrecta = nota['es_correcta'] ?? false;
    final colorEstado =
        esCorrecta ? const Color(0xFF4CAF50) : const Color(0xFFC0392B);
    final categoria = nota['categoria'] ?? 'General';

    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expandida
                ? colorEstado.withOpacity(0.4)
                : colorEstado.withOpacity(0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera ────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    esCorrecta
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: colorEstado,
                    size: 20,
                  ),
                   SizedBox(width: 10 * escala),
                  Expanded(
                    child: Text(
                      nota['situacion'] ?? "Cuestión cultural",
                      maxLines: _expandida ? 5 : 1,
                      overflow: _expandida
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFFDFAF5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                     SizedBox(width: 8 * escala),
                  Icon(
                    _expandida
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.3),
                    size: 20,
                  ),
                ],
              ),

              // Categoría
              Padding(
                padding: const EdgeInsets.only(left: 30, top: 4),
                child: Text(
                  categoria,
                  style: TextStyle(
                    color: colorEstado.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // ── Detalle expandible ───────────────────────────────────
              if (_expandida) ...[
               SizedBox(height: 14 * escala),
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.07),
                ),
               SizedBox(height: 12 * escala),

                // Tu respuesta
                _FilaDetalle(
                  etiqueta: "Tu respuesta",
                  valor: nota['tu_respuesta'] ?? "-",
                  color: Colors.white.withOpacity(0.7),
                ),

               SizedBox(height: 10 * escala),

                // Lección de Sato-san
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFC0392B).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("🎌 ", style: TextStyle(fontSize: 13)),
                          Text(
                            "Lección de Sato-san",
                            style: TextStyle(
                              color: const Color(0xFFF4A7B9).withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                     SizedBox(height: 6 * escala),
                      Text(
                        nota['explicacion_cultural'] ?? "Sin explicación.",
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fila de detalle ───────────────────────────────────────────────────────────
class _FilaDetalle extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color color;
  const _FilaDetalle({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
       SizedBox(height: 4   * escala),
        Text(
          valor,
          style: TextStyle(
            color: color,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
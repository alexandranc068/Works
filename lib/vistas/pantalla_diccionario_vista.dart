import 'package:flutter/material.dart';
import '../controladores/logica_juego.dart';

class PantallaDiccionarioVista extends StatelessWidget {
  final LogicaJuego controlador;
  const PantallaDiccionarioVista({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Fondo con imagen shodo ────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/imagenes/shodo_camino_escribir.jpg',
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
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "辞書",
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFFC9A96E).withOpacity(0.8),
                              letterSpacing: 6,
                            ),
                          ),
                          const Text(
                            "Mi Diccionario",
                            style: TextStyle(
                              fontSize: 26,
                              color: Color(0xFFFDFAF5),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Text(
                            "Personal",
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
                          color: const Color(0xFFC9A96E).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFC9A96E).withOpacity(0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.translate_rounded,
                          color: Color(0xFFC9A96E),
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Línea dorada ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFC9A96E).withOpacity(0.6),
                          const Color(0xFFF4A7B9).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Lista ─────────────────────────────────────────────────
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: controlador.streamDiccionarioPersonal(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF4A7B9),
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
                                  "語",
                                  style: TextStyle(
                                    fontSize: 72,
                                    color: const Color(0xFFC9A96E)
                                        .withOpacity(0.15),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "Tu diccionario está vacío.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "¡Guarda palabras durante el juego!",
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

                      final palabras = snapshot.data!;
                      return Column(
                        children: [
                          // Contador
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4A7B9)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFF4A7B9)
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  child: Text(
                                    "${palabras.length} ${palabras.length == 1 ? 'término' : 'términos'}",
                                    style: const TextStyle(
                                      color: Color(0xFFF4A7B9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: palabras.length,
                              itemBuilder: (context, index) {
                                final item = palabras[index];
                                return _TarjetaPalabra(item: item);
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

class _TarjetaPalabra extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TarjetaPalabra({required this.item});

  @override
  Widget build(BuildContext context) {
    final termino = item['termino'] ?? '';
    final significado = item['significado'] ?? '';

    // Detecta si el término tiene caracteres japoneses
    final tieneJapones = RegExp(r'[\u3040-\u30FF\u4E00-\u9FFF]').hasMatch(termino);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFC9A96E).withOpacity(0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Indicador lateral dorado
            Container(
              width: 3,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A96E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    termino,
                    style: TextStyle(
                      color: const Color(0xFFFDFAF5),
                      fontSize: tieneJapones ? 20 : 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    significado,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFC9A96E).withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
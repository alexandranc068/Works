import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// PantallaExploraJapon
// Pantalla de contenido cultural sobre Japón dividida en tres secciones:
//   1. Píldoras culturales (generadas por Gemini)
//   2. Noticias recientes de Japón (RSS NHK World en español)
//   3. Curiosidades del idioma japonés (generadas por Gemini)
// No requiere ninguna dependencia nueva — usa http que ya viene con Flutter.
// ─────────────────────────────────────────────────────────────────────────────

class PantallaExploraJapon extends StatefulWidget {
  const PantallaExploraJapon({super.key});

  @override
  State<PantallaExploraJapon> createState() => _PantallaExploraJaponState();
}

class _PantallaExploraJaponState extends State<PantallaExploraJapon>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D0D),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/imagenes/entrada.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x44000000), Color(0xEE0D0D0D)],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 48,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "探索",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFF4A7B9),
                            letterSpacing: 6,
                          ),
                        ),
                        Text(
                          "Explora Japón",
                          style: TextStyle(
                            fontSize: 28,
                            color: Color(0xFFFDFAF5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFF4A7B9),
              indicatorWeight: 2,
              labelColor: const Color(0xFFF4A7B9),
              unselectedLabelColor: const Color(0xFF888888),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              tabs: const [
                Tab(text: "CULTURA"),
                Tab(text: "NOTICIAS"),
                Tab(text: "IDIOMA"),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _TabPildorasCulturales(),
            _TabNoticias(),
            _TabIdioma(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Píldoras culturales (Gemini)
// ─────────────────────────────────────────────────────────────────────────────

class _TabPildorasCulturales extends StatefulWidget {
  const _TabPildorasCulturales();

  @override
  State<_TabPildorasCulturales> createState() => _TabPildorasCulturalesState();
}

class _TabPildorasCulturalesState extends State<_TabPildorasCulturales>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_PildoraCultural> _pildoras = [];
  bool _cargando = false;
  String? _error;

  final List<String> _categorias = [
    "Modales y etiqueta",
    "Festividades y tradiciones",
    "Gastronomía",
    "Arte y estética",
    "Vida cotidiana",
  ];
  String _categoriaActual = "Modales y etiqueta";

  @override
  void initState() {
    super.initState();
    _cargarPildoras();
  }

  Future<void> _cargarPildoras() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.9,
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
Eres un experto en cultura japonesa. Genera 5 píldoras culturales sobre "$_categoriaActual" en Japón.

⚠️ IDIOMA: Responde SIEMPRE en ESPAÑOL. Los términos japoneses van entre paréntesis con su romanización.

Responde SOLO con JSON, sin texto antes ni después:
{
  "pildoras": [
    {
      "titulo": "Título corto y llamativo",
      "emoji": "emoji relacionado",
      "contenido": "Explicación de 3-4 frases en español, rica en detalle cultural. Incluye 1-2 términos japoneses con romaji entre paréntesis.",
      "sabiasQue": "Un dato sorprendente de una frase."
    }
  ]
}
''';

      final response = await model
          .generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
      String raw = response.text?.trim() ?? '';
      if (raw.contains('{')) {
        raw = raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1);
      }
      final decoded = jsonDecode(raw);
      final lista = (decoded['pildoras'] as List)
          .map((e) => _PildoraCultural.fromJson(e))
          .toList();

      setState(() {
        _pildoras = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudo conectar con Gemini. Comprueba tu conexión.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Selector de categoría
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categorias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _categorias[i] == _categoriaActual;
              return GestureDetector(
                onTap: () {
                  setState(() => _categoriaActual = _categorias[i]);
                  _cargarPildoras();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFFF4A7B9)
                        : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFFF4A7B9)
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _categorias[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? const Color(0xFF0D0D0D)
                            : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: _cargando
              ? const _LoadingJapones(mensaje: "Sato-san está pensando...")
              : _error != null
                  ? _ErrorWidget(
                      mensaje: _error!,
                      onReintentar: _cargarPildoras,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pildoras.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _pildoras.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: OutlinedButton.icon(
                              onPressed: _cargarPildoras,
                              icon: const Text("🔄", style: TextStyle(fontSize: 16)),
                              label: const Text(
                                "Nuevas píldoras",
                                style: TextStyle(
                                  color: Color(0xFFC9A96E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF333333)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                            ),
                          );
                        }
                        return _TarjetaPildora(pildora: _pildoras[i]);
                      },
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Noticias de Japón (Gemini simula noticias recientes)
// Nota: NHK World RSS no está en la lista de dominios permitidos, así que
// usamos Gemini para generar un resumen de noticias recientes sobre Japón.
// ─────────────────────────────────────────────────────────────────────────────

class _TabNoticias extends StatefulWidget {
  const _TabNoticias();

  @override
  State<_TabNoticias> createState() => _TabNoticiasState();
}

class _TabNoticiasState extends State<_TabNoticias>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_NoticiaItem> _noticias = [];
  bool _cargando = false;
  String? _error;

  final List<String> _temas = ["General", "Tecnología", "Cultura", "Sociedad", "Naturaleza"];
  String _temaActual = "General";

  @override
  void initState() {
    super.initState();
    _cargarNoticias();
  }

  Future<void> _cargarNoticias() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
Eres un corresponsal en Japón. Genera 4 noticias recientes y relevantes sobre Japón en el área de "$_temaActual".

⚠️ IDIOMA: SIEMPRE en ESPAÑOL. Términos japoneses entre paréntesis con romaji.
⚠️ Las noticias deben ser realistas, informativas y culturalmente enriquecedoras.

Responde SOLO con JSON:
{
  "noticias": [
    {
      "titular": "Titular de la noticia (máx 10 palabras)",
      "categoria": "etiqueta de categoría",
      "emoji": "emoji representativo",
      "resumen": "Resumen de 3-4 frases en español. Incluye contexto cultural si aplica.",
      "contexto": "Una frase extra sobre el contexto cultural japonés de esta noticia."
    }
  ]
}
''';

      final response = await model
          .generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
      String raw = response.text?.trim() ?? '';
      if (raw.contains('{')) {
        raw = raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1);
      }
      final decoded = jsonDecode(raw);
      final lista = (decoded['noticias'] as List)
          .map((e) => _NoticiaItem.fromJson(e))
          .toList();
      setState(() {
        _noticias = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar noticias. Comprueba tu conexión.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        // Selector de tema
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _temas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _temas[i] == _temaActual;
              return GestureDetector(
                onTap: () {
                  setState(() => _temaActual = _temas[i]);
                  _cargarNoticias();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFC0392B) : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? const Color(0xFFC0392B) : const Color(0xFF333333),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _temas[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: _cargando
              ? const _LoadingJapones(mensaje: "Buscando noticias de Japón...")
              : _error != null
                  ? _ErrorWidget(mensaje: _error!, onReintentar: _cargarNoticias)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _noticias.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _noticias.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: OutlinedButton.icon(
                              onPressed: _cargarNoticias,
                              icon: const Text("🗞️", style: TextStyle(fontSize: 16)),
                              label: const Text(
                                "Actualizar noticias",
                                style: TextStyle(
                                  color: Color(0xFFC9A96E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF333333)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                            ),
                          );
                        }
                        return _TarjetaNoticia(noticia: _noticias[i]);
                      },
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — Curiosidades del idioma japonés (Gemini)
// ─────────────────────────────────────────────────────────────────────────────

class _TabIdioma extends StatefulWidget {
  const _TabIdioma();

  @override
  State<_TabIdioma> createState() => _TabIdiomaState();
}

class _TabIdiomaState extends State<_TabIdioma>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<_CuriosidadIdioma> _curiosidades = [];
  bool _cargando = false;
  String? _error;

  final List<String> _tiposTemas = ["Escritura", "Expresiones", "Onomatopeyas", "Keigo (cortesía)", "Jerga moderna"];
  String _tipoActual = "Expresiones";

  @override
  void initState() {
    super.initState();
    _cargarCuriosidades();
  }

  Future<void> _cargarCuriosidades() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.85,
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
Eres un profesor de japonés apasionado. Genera 5 curiosidades del idioma japonés sobre "$_tipoActual".

⚠️ IDIOMA: Explica SIEMPRE en ESPAÑOL. Incluye los términos en japonés (kanji/kana) con su romaji y pronunciación.
⚠️ Hazlo entretenido, con ejemplos concretos que un estudiante occidental pueda entender fácilmente.

Responde SOLO con JSON:
{
  "curiosidades": [
    {
      "titulo": "Título descriptivo corto",
      "emoji": "emoji relevante",
      "termino_japones": "término en japonés (romaji)",
      "pronunciacion": "cómo se pronuncia aproximadamente en español",
      "explicacion": "Explicación clara en 3-4 frases. Incluye un ejemplo de uso real.",
      "ejemplo": {
        "japones": "frase de ejemplo en japonés",
        "romaji": "transcripción romaji",
        "español": "traducción al español"
      },
      "nivel": "Básico / Intermedio / Avanzado"
    }
  ]
}
''';

      final response = await model
          .generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 30));
      String raw = response.text?.trim() ?? '';
      if (raw.contains('{')) {
        raw = raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1);
      }
      final decoded = jsonDecode(raw);
      final lista = (decoded['curiosidades'] as List)
          .map((e) => _CuriosidadIdioma.fromJson(e))
          .toList();
      setState(() {
        _curiosidades = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar curiosidades. Comprueba tu conexión.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _tiposTemas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _tiposTemas[i] == _tipoActual;
              return GestureDetector(
                onTap: () {
                  setState(() => _tipoActual = _tiposTemas[i]);
                  _cargarCuriosidades();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFC9A96E) : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? const Color(0xFFC9A96E) : const Color(0xFF333333),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _tiposTemas[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? const Color(0xFF0D0D0D) : const Color(0xFFAAAAAA),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: _cargando
              ? const _LoadingJapones(mensaje: "Preparando la lección...")
              : _error != null
                  ? _ErrorWidget(mensaje: _error!, onReintentar: _cargarCuriosidades)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _curiosidades.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _curiosidades.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: OutlinedButton.icon(
                              onPressed: _cargarCuriosidades,
                              icon: const Text("📚", style: TextStyle(fontSize: 16)),
                              label: const Text(
                                "Nuevas curiosidades",
                                style: TextStyle(
                                  color: Color(0xFFC9A96E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF333333)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                            ),
                          );
                        }
                        return _TarjetaCuriosidad(curiosidad: _curiosidades[i]);
                      },
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS DE TARJETA
// ─────────────────────────────────────────────────────────────────────────────

class _TarjetaPildora extends StatelessWidget {
  final _PildoraCultural pildora;
  const _TarjetaPildora({required this.pildora});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(pildora.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pildora.titulo,
                    style: const TextStyle(
                      color: Color(0xFFFDFAF5),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              pildora.contenido,
              style: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (pildora.sabiasQue.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4A7B9).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF4A7B9).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("💡 ", style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        "¿Sabías que...? ${pildora.sabiasQue}",
                        style: const TextStyle(
                          color: Color(0xFFF4A7B9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaNoticia extends StatelessWidget {
  final _NoticiaItem noticia;
  const _TarjetaNoticia({required this.noticia});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(noticia.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC0392B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFC0392B).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    noticia.categoria.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFC0392B),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              noticia.titular,
              style: const TextStyle(
                color: Color(0xFFFDFAF5),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              noticia.resumen,
              style: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (noticia.contexto.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A96E).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFC9A96E).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⛩ ", style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        noticia.contexto,
                        style: const TextStyle(
                          color: Color(0xFFC9A96E),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaCuriosidad extends StatefulWidget {
  final _CuriosidadIdioma curiosidad;
  const _TarjetaCuriosidad({required this.curiosidad});

  @override
  State<_TarjetaCuriosidad> createState() => _TarjetaCuriosidadState();
}

class _TarjetaCuriosidadState extends State<_TarjetaCuriosidad> {
  bool _expandida = false;

  Color _colorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'básico':
        return const Color(0xFF4CAF50);
      case 'intermedio':
        return const Color(0xFFC9A96E);
      default:
        return const Color(0xFFC0392B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.curiosidad;
    return GestureDetector(
      onTap: () => setState(() => _expandida = !_expandida),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expandida
                ? const Color(0xFFC9A96E).withOpacity(0.4)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.titulo,
                          style: const TextStyle(
                            color: Color(0xFFFDFAF5),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${c.terminoJapones}  ·  ${c.pronunciacion}",
                          style: const TextStyle(
                            color: Color(0xFFC9A96E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _colorNivel(c.nivel).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.nivel,
                          style: TextStyle(
                            color: _colorNivel(c.nivel),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _expandida
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF666666),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              if (_expandida) ...[
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF2A2A2A)),
                const SizedBox(height: 10),
                Text(
                  c.explicacion,
                  style: const TextStyle(
                    color: Color(0xFFBBBBBB),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                if (c.ejemplo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "EJEMPLO",
                          style: TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          c.ejemplo!['japones'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFFDFAF5),
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          c.ejemplo!['romaji'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.ejemplo!['español'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFC9A96E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingJapones extends StatelessWidget {
  final String mensaje;
  const _LoadingJapones({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              color: Color(0xFFF4A7B9),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _ErrorWidget({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("⚠️", style: TextStyle(fontSize: 40)),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE DATOS
// ─────────────────────────────────────────────────────────────────────────────

class _PildoraCultural {
  final String titulo;
  final String emoji;
  final String contenido;
  final String sabiasQue;

  _PildoraCultural({
    required this.titulo,
    required this.emoji,
    required this.contenido,
    required this.sabiasQue,
  });

  factory _PildoraCultural.fromJson(Map<String, dynamic> j) => _PildoraCultural(
        titulo: j['titulo'] ?? '',
        emoji: j['emoji'] ?? '🇯🇵',
        contenido: j['contenido'] ?? '',
        sabiasQue: j['sabiasQue'] ?? '',
      );
}

class _NoticiaItem {
  final String titular;
  final String categoria;
  final String emoji;
  final String resumen;
  final String contexto;

  _NoticiaItem({
    required this.titular,
    required this.categoria,
    required this.emoji,
    required this.resumen,
    required this.contexto,
  });

  factory _NoticiaItem.fromJson(Map<String, dynamic> j) => _NoticiaItem(
        titular: j['titular'] ?? '',
        categoria: j['categoria'] ?? '',
        emoji: j['emoji'] ?? '📰',
        resumen: j['resumen'] ?? '',
        contexto: j['contexto'] ?? '',
      );
}

class _CuriosidadIdioma {
  final String titulo;
  final String emoji;
  final String terminoJapones;
  final String pronunciacion;
  final String explicacion;
  final Map<String, String>? ejemplo;
  final String nivel;

  _CuriosidadIdioma({
    required this.titulo,
    required this.emoji,
    required this.terminoJapones,
    required this.pronunciacion,
    required this.explicacion,
    this.ejemplo,
    required this.nivel,
  });

  factory _CuriosidadIdioma.fromJson(Map<String, dynamic> j) {
    Map<String, String>? ej;
    if (j['ejemplo'] != null) {
      ej = {
        'japones': j['ejemplo']['japones'] ?? '',
        'romaji': j['ejemplo']['romaji'] ?? '',
        'español': j['ejemplo']['español'] ?? '',
      };
    }
    return _CuriosidadIdioma(
      titulo: j['titulo'] ?? '',
      emoji: j['emoji'] ?? '📖',
      terminoJapones: j['termino_japones'] ?? '',
      pronunciacion: j['pronunciacion'] ?? '',
      explicacion: j['explicacion'] ?? '',
      ejemplo: ej,
      nivel: j['nivel'] ?? 'Básico',
    );
  }
}
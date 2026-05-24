import '../modelos/usuario.dart';
import 'dart:convert'; 
import '../modelos/escena_modelo.dart'; 
import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class LogicaJuego {
  Usuario? jugadorActual;
  String nivelDificultad = "medio"; 
  String contextoSeleccionado = "templos"; 
  
  String? _userDocId;

  // Cache en RAM de situaciones ya jugadas por contexto (respaldo de Firestore)
  final Map<String, List<String>> _situacionesJugadasCache = {
    'templos': [],
    'restaurante': [],
    'amistad': [],
    'trabajo': [],
  };

  // --- PREFETCHING: siguiente escena precargada en segundo plano ---
  EscenaModelo? _escenaPreCargada;
  bool _precargando = false;

  /// Lanza la generación de la siguiente escena en segundo plano.
  /// Se llama justo después de mostrar el feedback, mientras el usuario lo lee.
  void precargarSiguienteEscena() {
    if (_precargando || _escenaPreCargada != null) return;
    _precargando = true;
    obtenerNuevaSituacionIA().then((escena) {
      _escenaPreCargada = escena;
      _precargando = false;
      print("⚡ Escena precargada en segundo plano");
    }).catchError((e) {
      _precargando = false;
      print("⚠️ Error precargando escena: $e");
    });
  }

  /// Devuelve la escena precargada si existe; si no, espera a generarla.
  Future<EscenaModelo> obtenerEscena() async {
    if (_escenaPreCargada != null) {
      final escena = _escenaPreCargada!;
      _escenaPreCargada = null;
      print("⚡ Usando escena precargada — sin espera");
      precargarSiguienteEscena(); // ya empieza la siguiente
      return escena;
    }
    print("⏳ No hay escena precargada, generando ahora...");
    return obtenerNuevaSituacionIA();
  }

  // --- 1. GESTIÓN DE USUARIOS Y SESIÓN ---

  Future<bool> elNombreYaExiste(String nombre) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('nombre', isEqualTo: nombre)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print("Error checking username: $e");
      return false;
    }
  }

  Future<void> iniciarOSuperarSesion(String nombreIngresado) async {
    final coleccion = FirebaseFirestore.instance.collection('usuarios');
    final query = await coleccion.where('nombre', isEqualTo: nombreIngresado).get();
    print("🔍 Buscando nombre: '$nombreIngresado'");
print("🔍 Docs encontrados: ${query.docs.length}");
print("🔍 Error si hay: ${query.docs}");

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      _userDocId = doc.id;
      final datos = doc.data();

      Map<String, int> progresoCargado = {
        'templos': 0,
        'restaurante': 0,
        'amistad': 0,
        'trabajo': 0,
      };
      if (datos['progresoContextos'] != null) {
        (datos['progresoContextos'] as Map).forEach((k, v) {
          progresoCargado[k.toString()] = (v as num).toInt();
        });
      }

      // ASIGNACIÓN AL CARGAR SESIÓN
      jugadorActual = Usuario(
        id: _userDocId,
        nombre: datos['nombre'],
        puntosCultura: (datos['puntosCultura'] as num?)?.toInt() ?? 0,
        impactoCultural: (datos['impactoCultural'] as num?)?.toDouble() ?? 0.5,
        // Si no tiene foto en la BD, le ponemos la de turista por defecto
        fotoPerfil: datos['fotoPerfil'] ?? 'assets/imagenes/foto_defecto_foto_perfil.png',
        progresoContextos: progresoCargado,
        historialAnimos: datos['historialAnimos'] != null 
            ? List<String>.from(datos['historialAnimos']) 
            : [],
      );

      // Cargar el historial de situaciones jugadas desde Firestore al cache
      await _cargarSituacionesJugadasEnCache();

      print("✅ Sesión iniciada: ${jugadorActual!.nombre} | Foto: ${jugadorActual!.fotoPerfil}");

    } else {
      // CREACIÓN DE NUEVO USUARIO
      final nuevoUsuario = Usuario(nombre: nombreIngresado);
      
      final docRef = await coleccion.add({
        'nombre': nuevoUsuario.nombre,
        'puntosCultura': nuevoUsuario.puntosCultura,
        'impactoCultural': nuevoUsuario.impactoCultural,
        // Guardamos la foto inicial en la base de datos
        'fotoPerfil': nuevoUsuario.fotoPerfil, 
        'progresoContextos': nuevoUsuario.progresoContextos,
        'historialAnimos': nuevoUsuario.historialAnimos,
        'fechaCreacion': DateTime.now(),
        'totalRespuestas': 0,
        'respuestasCorrectas': 0,
      });
      
      _userDocId = docRef.id;
      nuevoUsuario.id = _userDocId;
      jugadorActual = nuevoUsuario;

      print("✅ Nuevo usuario creado: ${jugadorActual!.nombre} con foto inicial");
    }
  }
  
  Future<void> recargarDatosUsuario() async {
    if (jugadorActual == null || _userDocId == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .get();
          
      if (doc.exists) {
        final datos = doc.data()!;
        jugadorActual!.puntosCultura = (datos['puntosCultura'] as num?)?.toInt() ?? 0;
        jugadorActual!.impactoCultural = (datos['impactoCultural'] as num?)?.toDouble() ?? 0.5;
        
        if (datos['progresoContextos'] != null) {
          (datos['progresoContextos'] as Map).forEach((k, v) {
            jugadorActual!.progresoContextos[k.toString()] = (v as num).toInt();
          });
        }
        
        if (datos['historialAnimos'] != null) {
          jugadorActual!.historialAnimos = List<String>.from(datos['historialAnimos']);
        }

        print("🔄 Datos recargados - Puntos: ${jugadorActual!.puntosCultura}, Impacto: ${jugadorActual!.impactoCultural}");
      }
    } catch (e) {
      print("Error reloading user data: $e");
    }
  }

  // --- MEMORIA DE SITUACIONES JUGADAS ---

  /// Carga desde Firestore las últimas 10 situaciones jugadas por contexto al cache en RAM
  Future<void> _cargarSituacionesJugadasEnCache() async {
    if (_userDocId == null) return;
    try {
      for (String contexto in _situacionesJugadasCache.keys) {
        final snap = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_userDocId)
            .collection('situaciones_jugadas')
            .where('contexto', isEqualTo: contexto)
            .orderBy('fecha', descending: true)
            .limit(10)
            .get();

        _situacionesJugadasCache[contexto] = snap.docs
            .map((d) => d.data()['resumen'] as String)
            .toList();
      }
      print("📚 Historial de situaciones cargado en cache");
    } catch (e) {
      print("⚠️ Error cargando historial de situaciones: $e");
    }
  }

  /// Guarda una situación jugada en Firestore y la añade al cache en RAM
  Future<void> _guardarSituacionJugada(String resumenSituacion) async {
    if (_userDocId == null) return;
    try {
      // Añadir al cache local
      final lista = _situacionesJugadasCache[contextoSeleccionado] ?? [];
      lista.insert(0, resumenSituacion);
      if (lista.length > 10) lista.removeLast();
      _situacionesJugadasCache[contextoSeleccionado] = lista;

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('situaciones_jugadas')
          .add({
            'contexto': contextoSeleccionado,
            'resumen': resumenSituacion,
            'fecha': DateTime.now(),
          });

      // Mantener solo las 10 más recientes en Firestore por contexto
      final snap = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('situaciones_jugadas')
          .where('contexto', isEqualTo: contextoSeleccionado)
          .orderBy('fecha', descending: true)
          .get();

      if (snap.docs.length > 10) {
        for (int i = 10; i < snap.docs.length; i++) {
          await snap.docs[i].reference.delete();
        }
      }

      print("💾 Situación guardada en historial: $resumenSituacion");
    } catch (e) {
      print("⚠️ Error guardando situación jugada: $e");
    }
  }

  /// Devuelve el bloque de texto con las situaciones a evitar para el prompt
  String _construirBloqueSituacionesAEvitar() {
    final lista = _situacionesJugadasCache[contextoSeleccionado] ?? [];
    if (lista.isEmpty) return "";

    final buffer = StringBuffer();
    buffer.writeln("═══ SITUACIONES YA JUGADAS — PROHIBIDO REPETIRLAS O HACER ALGO SIMILAR ═══");
    buffer.writeln("El jugador YA ha visto estas situaciones. Debes crear algo COMPLETAMENTE DIFERENTE:");
    for (int i = 0; i < lista.length; i++) {
      buffer.writeln("  ${i + 1}. ${lista[i]}");
    }
    buffer.writeln("⛔ No uses el mismo escenario, el mismo dilema ni la misma norma cultural que las anteriores.");
    return buffer.toString();
  }

  // --- 2. GENERADOR DE SITUACIONES POR IA ---

  Future<EscenaModelo> obtenerNuevaSituacionIA({int reintentos = 0}) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.95,
          responseMimeType: 'application/json',
        ),
      );

      // SUBTEMAS ESPECÍFICOS POR CONTEXTO
      // Cada contexto tiene una lista de subtemas concretos; elegimos uno al azar
      // para obligar a Gemini a explorar ángulos distintos cada vez.
      final Map<String, List<String>> subtemasContexto = {
        "templos": [
          "El ritual del 手水舎 (Temizuya): orden correcto de lavado de manos",
          "Diferencia entre 神社 (Jinja) y 寺 (Tera) y cómo comportarse en cada uno",
          "Cuándo aplaudir (2 veces en Jinja) y cuándo NO aplaudir (en Tera budista)",
          "Cómo tirar la moneda en la 賽銭箱 (Saisen-bako) sin lanzarla con fuerza",
          "Qué hacer con un 御籤 (Omikuji) cuando sale mal agüero",
          "Comprar y usar correctamente un 御守り (Omamori)",
          "Zonas prohibidas al fotógrafo: qué está permitido fotografiar y qué no",
          "Reverencias al entrar y salir: profundidad y duración según el lugar",
          "Por qué NO se señala con el dedo a estatuas o figuras religiosas",
          "El silencio como norma: volumen de voz y comportamiento en recintos sagrados",
          "Qué hacer cuando coincides con una ceremonia o procesión en el templo",
          "Uso correcto del incienso (線香, Senkō) en los templos budistas",
          "Diferencia entre un santuario de barrio (小さい神社) y un gran santuario nacional",
          "Qué significa y cómo se hace el お参り (Omairi) correctamente",
          "Las puertas 鳥居 (Torii): por qué no se pasa por el centro y otros tabúes",
        ],
        "restaurante": [
          "Los 7 usos prohibidos de los 箸 (Hashi) que más ofenden en Japón",
          "Cómo llamar al camarero sin levantarse ni gritar: el botón, la voz, la mirada",
          "El significado de いただきます (Itadakimasu) y ごちそうさま (Gochisousama) y cuándo decirlos",
          "Por qué dejar propina es un insulto y qué hacer si el camarero te la devuelve",
          "Cómo funciona una máquina expendedora de tickets (食券機, Shokkenki) de ramen",
          "Etiqueta en kaiten-zushi (回転寿司): qué está permitido y qué es una falta grave",
          "Cómo pedir la cuenta: el gesto correcto con los dedos en forma de X",
          "Compartir comida: cuándo sí y cuándo no, y cómo servir a otros correctamente",
          "Comer soba o ramen haciendo ruido: por qué es correcto y hasta qué punto",
          "Qué significa el oshibori (お絞り) y para qué NO debe usarse",
          "Entrada a un restaurante: esperar al anfitrión, quitarse los zapatos si aplica",
          "Sake y bebidas: quién sirve a quién y por qué nunca te sirves a ti mismo primero",
          "Izakaya (居酒屋): diferencias de protocolo con un restaurante formal",
          "Por qué no se come caminando por la calle aunque sí en festivales",
          "Cómo manejar la bandeja de dinero (お盆, Obon) al pagar en caja",
        ],
        "amistad": [
          "Transporte: por qué está prohibido hablar por teléfono en tren y metro",
          "El modo silencio (マナーモード, Mana modo) del móvil: cuándo y por qué",
          "No comer en el transporte público: la única excepción permitida",
          "Asientos prioritarios (優先席, Yūsen-seki): quién debe y quién no debe sentarse",
          "La regla de las escaleras mecánicas: en qué lado quedarse y en qué ciudad",
          "No fumar en la calle: zonas designadas y multas en ciudades como Tokio",
          "Separar la basura en Japón: los colores y días de recogida como norma social",
          "No comer caminando por la calle: cuándo sí está aceptado (matsuri)",
          "La bandeja de dinero en tiendas: por qué no se pone el dinero en la mano",
          "Onsen (温泉): ducharse antes de entrar, no llevar toalla al agua, tatuajes",
          "Hacer cola: la cultura de la fila perfecta y no colarse nunca",
          "El intercambio de regalos (贈り物, Okurimono): envolver, recibir con dos manos, no abrir delante",
          "Quitarse los zapatos al entrar a una casa: el genkan y las zapatillas de interior",
          "Recibir una tarjeta o documento con las dos manos y mirarlo con respeto",
          "El concepto de 迷惑 (Meiwaku): no molestar al prójimo como valor central",
        ],
        "trabajo": [
          "Intercambio de 名刺 (Meishi): cómo dar, recibir, leer y guardar la tarjeta",
          "Los tipos de お辞儀 (Ojigi): 15°, 30° y 45° y cuándo usar cada uno",
          "Nemawashi: por qué las decisiones en Japón se consensúan antes de la reunión",
          "El 判子 (Hanko): el sello personal y su importancia en documentos oficiales",
          "La cultura de las horas extra (残業, Zangyō) y el concepto de lealtad a la empresa",
          "Por qué no está bien irse antes que tu superior aunque hayas terminado",
          "Cómo dirigirse a un superior: uso de honoríficos (さん, 様, 部長) correctamente",
          "Las reuniones en Japón: el silencio no es desacuerdo, el 'sí' no siempre es sí",
          "飲み会 (Nomikai): la cena de empresa como obligación social no escrita",
          "El concepto de 本音 (Honne) vs 建前 (Tatemae): lo que se dice vs lo que se piensa",
          "Cómo presentarse al llegar nuevo a una empresa: el 挨拶 (Aisatsu) de presentación",
          "El uso del correo electrónico en Japón: fórmulas de cortesía obligatorias",
          "Puntualidad extrema: llegar tarde vs llegar demasiado pronto a una reunión",
          "El 根回し (Nemawashi) informal: hablar con cada implicado antes de la junta",
          "Aceptar críticas del jefe: la respuesta correcta y la incorrecta ante un superior",
        ],
      };

      // Seleccionar un subtema al azar del contexto actual
      final random = Random();
      final subtemas = subtemasContexto[contextoSeleccionado] ?? ["etiqueta general"];
      final subtemaElegido = subtemas[random.nextInt(subtemas.length)];

      // Nombres descriptivos del contexto para el prompt
      Map<String, String> nombresContexto = {
        "templos": "espiritualidad y visita a espacios religiosos japoneses",
        "restaurante": "etiqueta en restaurantes y cultura gastronómica japonesa",
        "amistad": "comportamiento cotidiano y vida social en Japón",
        "trabajo": "protocolo empresarial y cultura laboral japonesa",
      };
      
      double impactoActual = jugadorActual?.impactoCultural ?? 0.5;
      String nivelMensaje = "";
      if (impactoActual > 0.7) {
        nivelMensaje = " (El jugador tiene alto conocimiento cultural, usa matices sutiles y avanzados)";
      } else if (impactoActual < 0.3) {
        nivelMensaje = " (El jugador es principiante, la situación debe ser sencilla y directa)";
      }

      // Configuración según nivel de dificultad
      int numeroOpciones = 2;
      String puntosCorrecta = "20";
      String puntosIncorrecta = "-10";
      String impactoCorrecta = "0.1";
      String impactoIncorrecta = "-0.1";
      String mensajeNivel = "";
      
      if (nivelDificultad == "facil") {
        numeroOpciones = 2;
        puntosCorrecta = "15";
        puntosIncorrecta = "-5";
        impactoCorrecta = "0.05";
        impactoIncorrecta = "-0.05";
        mensajeNivel = "FÁCIL: 2 opciones (1 correcta, 1 incorrecta). Opciones muy diferenciadas.";
      } else if (nivelDificultad == "medio") {
        numeroOpciones = 4;
        puntosCorrecta = "20";
        puntosIncorrecta = "-10";
        impactoCorrecta = "0.1";
        impactoIncorrecta = "-0.1";
        mensajeNivel = "MEDIO: EXACTAMENTE 4 opciones (1 correcta, 3 incorrectas). Las 3 incorrectas deben ser creíbles y tentadoras para un occidental.";
      } else if (nivelDificultad == "dificil") {
        numeroOpciones = 4;
        puntosCorrecta = "30";
        puntosIncorrecta = "-15";
        impactoCorrecta = "0.15";
        impactoIncorrecta = "-0.15";
        mensajeNivel = "DIFÍCIL: EXACTAMENTE 4 opciones (1 correcta, 3 incorrectas). Opciones con matices culturales sutiles y avanzados.";
      }

      String opcionesTemplate = '';
      if (numeroOpciones == 4) {
        opcionesTemplate = '''
      "opciones": [
        {"texto": "OPCIÓN_CORRECTA_AQUÍ", "esCorrecta": true, "puntosCultura": $puntosCorrecta, "impactoCultural": $impactoCorrecta, "retroalimentacion": "RETROALIMENTACIÓN_CORRECTA_AQUÍ"},
        {"texto": "OPCIÓN_INCORRECTA_1", "esCorrecta": false, "puntosCultura": $puntosIncorrecta, "impactoCultural": $impactoIncorrecta, "retroalimentacion": "RETROALIMENTACIÓN_INCORRECTA_1"},
        {"texto": "OPCIÓN_INCORRECTA_2", "esCorrecta": false, "puntosCultura": $puntosIncorrecta, "impactoCultural": $impactoIncorrecta, "retroalimentacion": "RETROALIMENTACIÓN_INCORRECTA_2"},
        {"texto": "OPCIÓN_INCORRECTA_3", "esCorrecta": false, "puntosCultura": $puntosIncorrecta, "impactoCultural": $impactoIncorrecta, "retroalimentacion": "RETROALIMENTACIÓN_INCORRECTA_3"}
      ]
      ''';
      } else {
        opcionesTemplate = '''
      "opciones": [
        {"texto": "OPCIÓN_CORRECTA_AQUÍ", "esCorrecta": true, "puntosCultura": $puntosCorrecta, "impactoCultural": $impactoCorrecta, "retroalimentacion": "RETROALIMENTACIÓN_CORRECTA_AQUÍ"},
        {"texto": "OPCIÓN_INCORRECTA_1", "esCorrecta": false, "puntosCultura": $puntosIncorrecta, "impactoCultural": $impactoIncorrecta, "retroalimentacion": "RETROALIMENTACIÓN_INCORRECTA_1"}
      ]
      ''';
      }

      // Bloque con las situaciones ya jugadas (memoria persistente)
      final bloqueSituacionesAEvitar = _construirBloqueSituacionesAEvitar();

      final prompt = '''
Eres Sato-san, guía cultural japonés experto en enseñar etiqueta a occidentales.

⚠️ NIVEL ACTUAL: ${nivelDificultad.toUpperCase()}
⚠️ DEBES GENERAR EXACTAMENTE $numeroOpciones OPCIONES

$mensajeNivel

$bloqueSituacionesAEvitar

═══ SUBTEMA OBLIGATORIO PARA ESTA SITUACIÓN ═══
Debes crear una situación basada ESPECÍFICAMENTE en este subtema:
👉 "$subtemaElegido"

No te salgas de este subtema. La situación debe girar en torno a él, 
con un escenario concreto y realista donde el jugador deba tomar una decisión.

═══ TAREA ═══
Genera UNA situación cultural japonesa sobre ${nombresContexto[contextoSeleccionado]}$nivelMensaje.
El subtema obligatorio ya está indicado arriba. Respeta ese encuadre.

═══ REGLAS DE FORMATO ═══
1. PROHIBIDO usar HTML (<span>, <b>, <lang>)
2. Términos japoneses: kanji/kana + romaji entre paréntesis. Ej: 手水舎 (Temizuya)
3. Texto debe leerse directamente en móvil sin procesar
4. Responde SOLO con JSON. Nada antes, nada después.

═══ REGLAS DE CONTENIDO ═══
- Situación en segunda persona ("Estás en...", "Te encuentras...")
- Escenario concreto y específico (no genérico)
- Incluye 2-3 términos japoneses relevantes al subtema
- Glosario con EXACTAMENTE esos términos
- Opción correcta: enseña la norma cultural japonesa REAL de ese subtema
- Opciones incorrectas: errores COMUNES y CREÍBLES que un occidental cometería
- Retroalimentación: explica el PORQUÉ cultural profundo con contexto histórico o social

Formato JSON exacto:
{
  "id": "${DateTime.now().millisecondsSinceEpoch}",
  "personaje": "Sato-san",
  "animo": "feliz o serio o enfadado",
  "texto": "Tu situación aquí...",
  "glosario": [{"termino": "término (romaji)", "significado": "significado"}],
  $opcionesTemplate
}
      ''';

      print("🎲 Generando situación | contexto: $contextoSeleccionado | subtema: $subtemaElegido | opciones: $numeroOpciones");

      final response = await model.generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));
          
      String rawJson = response.text?.trim() ?? "";
      if (rawJson.contains('{')) {
        rawJson = rawJson.substring(rawJson.indexOf('{'), rawJson.lastIndexOf('}') + 1);
      }

      rawJson = _limpiarHTML(rawJson);
      
      EscenaModelo escena = EscenaModelo.desdeJson(jsonDecode(rawJson));

      // Guardar el resumen de esta situación en Firestore para memoria futura
      final resumen = "${subtemaElegido.split(':').first}: ${escena.texto.length > 80 ? escena.texto.substring(0, 80) : escena.texto}...";
      _guardarSituacionJugada(resumen); // Fire-and-forget, no bloqueamos la UI
      
      // Verificación: si es nivel medio/difícil y no tiene 4 opciones, reintentar
      if ((nivelDificultad == "medio" || nivelDificultad == "dificil") && escena.opciones.length != 4) {
        print("⚠️ ERROR: La IA generó ${escena.opciones.length} opciones en lugar de 4. Reintentando...");
        if (reintentos < 2) {
          return obtenerNuevaSituacionIA(reintentos: reintentos + 1);
        } else {
          print("⚠️ Reintentos agotados. Usando situación por defecto.");
          return _escenaFallback();
        }
      }
      
      print("✅ Situación generada con ${escena.opciones.length} opciones");
      return escena;
      
    } catch (e) {
      print("❌ Error en obtenerNuevaSituacionIA: $e");
      if (reintentos < 2) return obtenerNuevaSituacionIA(reintentos: reintentos + 1);
      return _escenaError();
    }
  }

  EscenaModelo _escenaFallback() {
    return EscenaModelo(
      id: "fallback", personaje: "Sato-san", animo: "serio", 
      texto: "Error al generar la situación. Por favor, intenta de nuevo más tarde.",
      glosario: [],
      opciones: [
        OpcionModelo(texto: "Reintentar", esCorrecta: true, puntosCultura: 0, impactoCultural: 0, retroalimentacion: "Haz clic en Siguiente reto para reintentar"),
        OpcionModelo(texto: "Reintentar", esCorrecta: false, puntosCultura: 0, impactoCultural: 0, retroalimentacion: "Haz clic en Siguiente reto para reintentar"),
        OpcionModelo(texto: "Reintentar", esCorrecta: false, puntosCultura: 0, impactoCultural: 0, retroalimentacion: "Haz clic en Siguiente reto para reintentar"),
        OpcionModelo(texto: "Reintentar", esCorrecta: false, puntosCultura: 0, impactoCultural: 0, retroalimentacion: "Haz clic en Siguiente reto para reintentar"),
      ]
    );
  }

  EscenaModelo _escenaError() {
    return EscenaModelo(
      id: "err", personaje: "Sato-san", animo: "serio", 
      texto: "Error de conexión. Por favor, intenta de nuevo.",
      glosario: [], 
      opciones: [
        OpcionModelo(texto: "Reintentar", esCorrecta: true, puntosCultura: 0, impactoCultural: 0, retroalimentacion: ""),
        OpcionModelo(texto: "Reintentar", esCorrecta: false, puntosCultura: 0, impactoCultural: 0, retroalimentacion: ""),
        OpcionModelo(texto: "Reintentar", esCorrecta: false, puntosCultura: 0, impactoCultural: 0, retroalimentacion: ""),
        OpcionModelo(texto: "Reintentar", esCorrecta: false, puntosCultura: 0, impactoCultural: 0, retroalimentacion: ""),
      ]
    );
  }

  // --- 3. DICCIONARIO PERSONAL ---

  Future<void> guardarPalabraEnGlosarioPersonal(TerminoGlosario termino) async {
    print("💾 Guardando palabra: '${termino.termino}' | docId: $_userDocId");

    if (jugadorActual == null || _userDocId == null) {
      print("❌ ERROR: jugadorActual o _userDocId es null");
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('diccionario_personal')
          .add({
            'termino': termino.termino,
            'significado': termino.significado,
            'fecha': DateTime.now(),
          });
      print("✅ Palabra guardada correctamente");
    } catch (e) { 
      print("❌ Error saving word: $e"); 
    }
  }

  Future<List<Map<String, dynamic>>> obtenerDiccionarioPersonal() async {
    if (jugadorActual == null || _userDocId == null) return [];
    try {
      final docs = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('diccionario_personal')
          .orderBy('fecha', descending: true)
          .get();
      return docs.docs.map((d) => d.data()).toList();
    } catch (e) {
      print("Error getting dictionary: $e");
      return [];
    }
  }

  // --- 4. MÉTODO PARA EL MODO PRO ---

  Future<Map<String, dynamic>> evaluarRespuestaProIA(String situacion, String respuestaUsuario) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(temperature: 0.4),
      );
      
      final prompt = '''
        Eres Sato-san, experto en etiqueta japonesa.
        
        SITUACIÓN: "$situacion"
        RESPUESTA DEL ESTUDIANTE: "$respuestaUsuario"
        
        Evalúa si la respuesta es culturalmente correcta.
        - Si es CORRECTA: puntos positivos (10-30), impacto positivo
        - Si es INCORRECTA: puntos NEGATIVOS (-10), impacto negativo
        
        ⚠️ IDIOMA: Responde SIEMPRE en ESPAÑOL, aunque el estudiante haya escrito en japonés u otro idioma.
        Los términos japoneses (kanji, romaji) están permitidos dentro del feedback para ilustrar conceptos,
        pero el texto explicativo debe estar completamente en español.
        
        Evalúa si la respuesta es culturalmente correcta.
        - Si es CORRECTA: puntos positivos (10-30), impacto positivo
        - Si es INCORRECTA: puntos NEGATIVOS (-10), impacto negativo
        
        Responde SOLO con JSON, sin texto antes ni después:
        {
          "esCorrecta": true/false,
          "puntos": int,
          "feedback": "explicación cultural detallada EN ESPAÑOL",
          "animo": "feliz/serio/enfadado"
        }
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      String res = response.text!.trim();
      if (res.contains('{')) res = res.substring(res.indexOf('{'), res.lastIndexOf('}') + 1);
      
      return jsonDecode(res);
    } catch (e) {
      return {"esCorrecta": false, "puntos": -10, "feedback": "Error de conexión. Intenta de nuevo.", "animo": "serio"};
    }
  }
  
  Future<void> guardarRespuestaUsuario({
    required String situacion,
    required String respuesta,
    required bool fueCorrecta,
    required int puntosObtenidos,
    required double cambioImpacto,
    required String animo,
  }) async {
    print("💾 Guardando respuesta | correcta: $fueCorrecta | puntos: $puntosObtenidos");

    if (jugadorActual == null || _userDocId == null) {
      print("❌ ERROR: jugadorActual o _userDocId es null");
      return;
    }
    
    try {
      jugadorActual!.historialAnimos.add(animo);
      if (jugadorActual!.historialAnimos.length > 10) {
        jugadorActual!.historialAnimos.removeAt(0);
      }
      
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .update({
            'historialAnimos': jugadorActual!.historialAnimos,
            'totalRespuestas': FieldValue.increment(1),
            'respuestasCorrectas': fueCorrecta ? FieldValue.increment(1) : FieldValue.increment(0),
            'ultimaRespuesta': DateTime.now(),
          });

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('historial_respuestas')
          .add({
            'situacion': situacion,
            'respuesta': respuesta,
            'fueCorrecta': fueCorrecta,
            'puntosObtenidos': puntosObtenidos,
            'cambioImpacto': cambioImpacto,
            'animo': animo,
            'fecha': DateTime.now(),
          });

      print("✅ Respuesta guardada correctamente");
    } catch (e) {
      print("❌ Error saving response: $e");
    }
  }

  // --- 5. PERFIL Y PROGRESO ---

  Future<bool> actualizarNombreUsuario(String nuevoNombre) async {
    if (jugadorActual == null || _userDocId == null) return false;
    
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('nombre', isEqualTo: nuevoNombre)
          .get();
      
      if (query.docs.isNotEmpty) {
        print("El nombre $nuevoNombre ya existe");
        return false;
      }
      
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .update({'nombre': nuevoNombre});
      
      jugadorActual!.nombre = nuevoNombre;
      print("Nombre actualizado a: $nuevoNombre");
      return true;
      
    } catch (e) { 
      print("Error actualizando nombre: $e");
      return false; 
    }
  }

  Future<bool> verificarNombreExiste(String nombre) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('nombre', isEqualTo: nombre)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print("Error verificando nombre: $e");
      return false;
    }
  }

  String obtenerMedallaContexto(String contexto) {
    int pts = jugadorActual?.progresoContextos[contexto] ?? 0;
    if (pts >= 400) return "Maestro";
    if (pts >= 200) return "Avanzado";
    if (pts >= 50) return "Aprendiz";
    return "Iniciado";
  }

  String obtenerRangoActual() {
    if (jugadorActual == null) return "Invitado";
    int pts = jugadorActual!.puntosCultura;
    if (pts >= 600) return "Sensei 🌟";
    if (pts >= 300) return "Samurai 🗡️";
    if (pts >= 100) return "Aprendiz 📚";
    return "Gaijin 🎌";
  }

  void _aplicarCambioImpacto(double cambio) {
    if (jugadorActual != null) {
      double nuevoImpacto = jugadorActual!.impactoCultural + cambio;
      jugadorActual!.impactoCultural = nuevoImpacto.clamp(0.0, 1.0);
      print("📊 Impacto actualizado: ${jugadorActual!.impactoCultural}");
    }
  }

  void actualizarCultura(double cambio) => _aplicarCambioImpacto(cambio);

  Future<void> guardarProgresoEnNube(int puntosNuevos, double cambioImpacto) async {
    print("💾 Guardando progreso | puntos: $puntosNuevos | contexto: $contextoSeleccionado");

    if (jugadorActual == null || _userDocId == null) {
      print("❌ ERROR: jugadorActual o _userDocId es null");
      return;
    }
    
    try {
      jugadorActual!.puntosCultura += puntosNuevos;
      _aplicarCambioImpacto(cambioImpacto);
      
      int ptsAnteriores = jugadorActual!.progresoContextos[contextoSeleccionado] ?? 0;
      jugadorActual!.progresoContextos[contextoSeleccionado] = ptsAnteriores + puntosNuevos;

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .update({
            'puntosCultura': jugadorActual!.puntosCultura,
            'impactoCultural': jugadorActual!.impactoCultural,
            'progresoContextos': jugadorActual!.progresoContextos,
          });
          
      print("✅ Progreso guardado - Puntos totales: ${jugadorActual!.puntosCultura}, Impacto: ${jugadorActual!.impactoCultural}");
    } catch (e) {
      print("❌ Error saving progress: $e");
    }
  }

  Future<List<Map<String, dynamic>>> obtenerGuiaRepaso() async {
    if (jugadorActual == null || _userDocId == null) return [];
    try {
      final logs = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('guia_repaso')
          .orderBy('fecha', descending: true)
          .limit(50)
          .get();
      return logs.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print("Error getting review guide: $e");
      return [];
    }
  }

  /// Stream en tiempo real de la guía de repaso.
  /// Emite una nueva lista cada vez que Firestore cambia, sin necesidad
  /// de salir y volver a entrar en la pantalla.
  Stream<List<Map<String, dynamic>>> streamGuiaRepaso() {
    if (_userDocId == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userDocId)
        .collection('guia_repaso')
        .orderBy('fecha', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Stream en tiempo real del diccionario personal.
  Stream<List<Map<String, dynamic>>> streamDiccionarioPersonal() {
    if (_userDocId == null) return Stream.value([]);
    return FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_userDocId)
        .collection('diccionario_personal')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> registrarEnGuiaRepaso({
    required String situacion, 
    required String opcionElegida, 
    required String explicacion, 
    required bool esCorrecto,
    int puntosGanados = 0,
    double cambioImpacto = 0.0,
    String animoRespuesta = "feliz"
  }) async {
    if (jugadorActual == null || _userDocId == null) {
      print("❌ ERROR: null en registrarEnGuiaRepaso");
      return;
    }
    
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          .collection('guia_repaso')
          .add({
            'situacion': situacion, 
            'tu_respuesta': opcionElegida, 
            'explicacion_cultural': explicacion,
            'es_correcta': esCorrecto, 
            'puntos_ganados': puntosGanados,
            'cambio_impacto': cambioImpacto,
            'animo_sato_san': animoRespuesta,
            'categoria': contextoSeleccionado, 
            'fecha': DateTime.now(),
          });
      print("✅ Entrada guardada en guia_repaso");
    } catch (e) {
      print("❌ Error registering in review guide: $e");
    }
  }

  // --- 6. REINICIO COMPLETO DE PROGRESO ---

  Future<void> reiniciarProgreso() async {
    if (jugadorActual == null || _userDocId == null) return;

    try {
      final ref = FirebaseFirestore.instance.collection('usuarios').doc(_userDocId);

      // Resetear campos principales del documento
      await ref.update({
        'puntosCultura': 0,
        'impactoCultural': 0.5,
        'progresoContextos': {
          'templos': 0,
          'restaurante': 0,
          'amistad': 0,
          'trabajo': 0,
        },
        'historialAnimos': [],
        'totalRespuestas': 0,
        'respuestasCorrectas': 0,
      });

      // Borrar subcolecciones
      await _borrarSubcoleccion(ref.collection('historial_respuestas'));
      await _borrarSubcoleccion(ref.collection('guia_repaso'));
      await _borrarSubcoleccion(ref.collection('situaciones_jugadas'));
      await _borrarSubcoleccion(ref.collection('diccionario_personal'));

      // Resetear estado local en RAM
      jugadorActual!.puntosCultura = 0;
      jugadorActual!.impactoCultural = 0.5;
      jugadorActual!.progresoContextos = {
        'templos': 0,
        'restaurante': 0,
        'amistad': 0,
        'trabajo': 0,
      };
      jugadorActual!.historialAnimos = [];

      for (final key in _situacionesJugadasCache.keys) {
        _situacionesJugadasCache[key] = [];
      }

      print("✅ Progreso reiniciado completamente para ${jugadorActual!.nombre}");
    } catch (e) {
      print("❌ Error reiniciando progreso: $e");
      rethrow;
    }
  }

  /// Borra todos los documentos de una subcolección en lotes
  Future<void> _borrarSubcoleccion(CollectionReference colRef) async {
    const int lote = 100;
    QuerySnapshot snap;
    do {
      snap = await colRef.limit(lote).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } while (snap.docs.length == lote);
  }

  // --- UTILIDADES ---

  // --- ASSETS POR CONTEXTO ---

  /// Devuelve la ruta del fondo de pantalla según el contexto activo.
  String obtenerFondoContexto() {
    switch (contextoSeleccionado) {
      case 'restaurante':
        return 'assets/imagenes/izakaya.jpg';
      case 'trabajo':
        return 'assets/imagenes/oficina_japonesa2.jpg';
      case 'amistad':
        return 'assets/imagenes/hanami_social.jpg';
      case 'templos':
      default:
        return 'assets/imagenes/templo_asakusa.jpg';
    }
  }

  /// Devuelve la ruta del personaje irasutoya según el contexto activo.
  String obtenerPersonajeContexto() {
    switch (contextoSeleccionado) {
      case 'restaurante':
        return 'assets/imagenes/chef izakaya.png';
      case 'trabajo':
        return 'assets/imagenes/salary man.png';
      case 'amistad':
        return 'assets/imagenes/tomodachi.png';
      case 'templos':
      default:
        return 'assets/imagenes/monje otera.png';
    }
  }

  String _limpiarHTML(String texto) {
    return texto.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Future<String> procesarCierreDeEstancia() async {
    if (jugadorActual == null) return "Sesión finalizada.";
    
    try {
      final model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
      final prompt = '''
        Sato-san evalúa a ${jugadorActual!.nombre}:
        - Puntos: ${jugadorActual!.puntosCultura}
        - Impacto cultural: ${(jugadorActual!.impactoCultural * 100).toInt()}%
        
        Da un cierre formal pero cálido en japonés (máximo 2 oraciones).
      ''';
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? "Arigatou gozaimasu. Sayonara.";
    } catch (e) {
      return "Arigatou gozaimasu. Sayonara.";
    }
  }
  Future<void> actualizarFotoPerfil(String nuevaRuta) async {
    if (jugadorActual == null || _userDocId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_userDocId)
          // ✅ corrección
.update({'fotoPerfil': nuevaRuta});
      
      jugadorActual!.fotoPerfil = nuevaRuta;
      print("✅ Foto de perfil actualizada en la nube: $nuevaRuta");
    } catch (e) {
      print("❌ Error actualizando foto: $e");
    }
  }
}
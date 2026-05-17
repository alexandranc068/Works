class EscenaModelo {
  final String id;
  final String personaje;
  final String animo; // ✅ AÑADIDO: Para el mood visual
  final String texto;
  final List<OpcionModelo> opciones;
  final List<TerminoGlosario> glosario; // ✅ AÑADIDO: Para el vocabulario

  EscenaModelo({
    required this.id,
    required this.personaje,
    required this.animo,
    required this.texto,
    required this.opciones,
    required this.glosario,
  });

  factory EscenaModelo.desdeJson(Map<String, dynamic> json) {
    // Parseo seguro de opciones
    var listaOpciones = json['opciones'] as List? ?? [];
    List<OpcionModelo> listaDeOpciones =
        listaOpciones.map((i) => OpcionModelo.desdeJson(i)).toList();

    // Parseo seguro de glosario
    var listaGlosario = json['glosario'] as List? ?? [];
    List<TerminoGlosario> listaDeTerminos =
        listaGlosario.map((i) => TerminoGlosario.desdeJson(i)).toList();

    listaDeOpciones.shuffle();

    return EscenaModelo(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      personaje: json['personaje'] ?? 'Sato-san',
      animo: json['animo'] ?? 'serio',
      texto: json['texto'] ?? '',
      opciones: listaDeOpciones,
      glosario: listaDeTerminos,
    );
  }
}

class TerminoGlosario {
  final String termino;
  final String significado;

  TerminoGlosario({required this.termino, required this.significado});

  factory TerminoGlosario.desdeJson(Map<String, dynamic> json) {
    return TerminoGlosario(
      termino: json['termino'] ?? '',
      significado: json['significado'] ?? '',
    );
  }
}

class OpcionModelo {
  final String texto;
  final bool esCorrecta;
  final int puntosCultura;
  final double impactoCultural;
  final String retroalimentacion;

  OpcionModelo({
    required this.texto,
    required this.esCorrecta,
    required this.puntosCultura,
    required this.impactoCultural,
    required this.retroalimentacion,
  });

  factory OpcionModelo.desdeJson(Map<String, dynamic> json) {
    return OpcionModelo(
      texto: json['texto'] ?? '',
      esCorrecta: json['esCorrecta'] == true,
      puntosCultura: (json['puntosCultura'] as num?)?.toInt() ?? 0,
      impactoCultural: (json['impactoCultural'] as num?)?.toDouble() ?? 0.0,
      retroalimentacion: json['retroalimentacion'] ?? '',
    );
  }
}
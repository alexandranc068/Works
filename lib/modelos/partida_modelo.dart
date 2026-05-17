class PartidaModelo {
  final String nombreUsuario;
  final int puntosFinales;
  final double impactoFinal;
  final String dificultad;
  final DateTime fecha;
  final String veredictoIA;

  PartidaModelo({
    required this.nombreUsuario,
    required this.puntosFinales,
    required this.impactoFinal,
    required this.dificultad,
    required this.fecha,
    required this.veredictoIA,
  });

  // Para convertirlo a un formato que Firebase entienda
  Map<String, dynamic> toMap() {
    return {
      'nombreUsuario': nombreUsuario,
      'puntosFinales': puntosFinales,
      'impactoFinal': impactoFinal,
      'dificultad': dificultad,
      'fecha': fecha,
      'veredictoIA': veredictoIA,
    };
  }
}
class Usuario {
  String? id;
  String nombre;
  int puntosCultura;
  double impactoCultural;
  Map<String, int> progresoContextos;
  List<String> historialAnimos;
  DateTime? fechaCreacion;
  String fotoPerfil; // <--- NUEVO CAMPO

  Usuario({
    this.id,
    required this.nombre,
    this.puntosCultura = 0,
    this.impactoCultural = 0.5,
    this.fotoPerfil = 'assets/imagenes/foto_defecto_foto_perfil.png', // <--- DEFECTO
    Map<String, int>? progresoContextos,
    List<String>? historialAnimos,
    this.fechaCreacion,
  }) : 
    progresoContextos = progresoContextos ?? {
      'templos': 0, 'restaurante': 0, 'amistad': 0, 'trabajo': 0,
    },
    historialAnimos = historialAnimos ?? [];
}
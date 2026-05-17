import 'package:flutter/material.dart';
import '../controladores/logica_juego.dart';
import 'pantalla_juego_vista.dart';

class SelectorContextoVista extends StatefulWidget {
  final LogicaJuego controlador;
  const SelectorContextoVista({super.key, required this.controlador});

  @override
  State<SelectorContextoVista> createState() => _SelectorContextoVistaState();
}

class _SelectorContextoVistaState extends State<SelectorContextoVista> {

  void _seleccionarYJugar(BuildContext context, String contexto) {
    widget.controlador.contextoSeleccionado = contexto;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaJuegoVista(controlador: widget.controlador),
      ),
    ).then((_) {
      // Al volver del juego refrescar puntos y progreso en el selector
      if (mounted) setState(() {});
    });
  }

  void _confirmarReinicio(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("¿Reiniciar progreso?"),
          ],
        ),
        content: const Text(
          "Se borrarán todos tus puntos, historial, situaciones jugadas, diccionario y progreso de cada contexto.\n\nVolverás a la pantalla de inicio. Esta acción no se puede deshacer.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _ejecutarReinicio(context);
            },
            child: const Text("Sí, reiniciar"),
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarReinicio(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    try {
      await widget.controlador.reiniciarProgreso();

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      // Volver a la pantalla raíz (introducir usuario)
      Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Error al reiniciar. Inténtalo de nuevo."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int puntosTotales = widget.controlador.jugadorActual?.puntosCultura ?? 0;
    final String rango = widget.controlador.obtenerRangoActual();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Selector de Destino",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            tooltip: "Reiniciar progreso",
            onPressed: () => _confirmarReinicio(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/imagenes/izakaya_contexto.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "¿Qué aspecto cultural deseas practicar?",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Puntos Totales",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Text(
                              "$puntosTotales pts",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withOpacity(0.5)),
                          ),
                          child: Text(
                            rango,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _tarjetaContexto(context, "Módulo Espiritual", Icons.temple_hindu, "templos", Colors.orangeAccent),
                  _tarjetaContexto(context, "Restaurante y Comida", Icons.restaurant, "restaurante", Colors.greenAccent),
                  _tarjetaContexto(context, "Vida Social y Amistad", Icons.people, "amistad", Colors.blueAccent),
                  _tarjetaContexto(context, "Protocolo Laboral", Icons.business, "trabajo", Colors.blueGrey),
                  const SizedBox(height: 30),
                  TextButton.icon(
                    onPressed: () => _confirmarReinicio(context),
                    icon: const Icon(Icons.restart_alt, color: Colors.white54, size: 18),
                    label: const Text(
                      "Reiniciar progreso",
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaContexto(BuildContext context, String titulo, IconData icono, String key, Color color) {
    int puntos = widget.controlador.jugadorActual?.progresoContextos[key] ?? 0;
    double progreso = (puntos / 500).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: progreso,
              color: color,
              backgroundColor: color.withOpacity(0.1),
            ),
            Text("Puntos: $puntos / 500", style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.play_arrow),
        onTap: () => _seleccionarYJugar(context, key),
      ),
    );
  }
}
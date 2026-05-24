import 'dart:ui';
import 'package:flutter/material.dart';
import 'SelectorContextoVista.dart'; // Cambio clave: Navega al selector de contextos
import '../controladores/logica_juego.dart';
import '../vistas/menu_principal.dart';

class SelectorDificultadVista extends StatelessWidget {
  final LogicaJuego controlador;
  const SelectorDificultadVista({super.key, required this.controlador});

  @override
  Widget build(BuildContext context) {
     final alturaPantalla = MediaQuery.of(context).size.height;
  
  // 2. Factor de escala: 1.0 = pantalla base de ~720px
  final escala = (alturaPantalla / 720).clamp(0.65, 1.2);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/imagenes/pantalla_niveles.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          Positioned(
  top: MediaQuery.of(context).padding.top + 8,
  left: 16,
  child: GestureDetector(
    onTap: () => Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const MenuPrincipalVista()),
  (route) => false, // elimina todo lo que había antes
),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: 18,
      ),
    ),
  ),
),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "ELIGE TU NIVEL DE INMERSIÓN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w300,
                  ),
                ),
               SizedBox(height: 40 * escala),
                _botonDificultad(context, "FÁCIL", "2 opciones de respuesta", Colors.greenAccent, () => _irAlSiguientePaso(context, "facil")),
                _botonDificultad(context, "MEDIO", "4 opciones de respuesta", Colors.orangeAccent, () => _irAlSiguientePaso(context, "medio")),
                _botonDificultad(context, "MODO PRO", "Escribe tu respuesta (IA)", Colors.redAccent, () => _irAlSiguientePaso(context, "pro"), esPro: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonDificultad(BuildContext context, String titulo, String subtitulo, Color color, VoidCallback accion, {bool esPro = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          side: BorderSide(color: color, width: 1),
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: accion,
        child: Column(
          children: [
            Text(titulo, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(subtitulo, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (esPro) const Padding(padding: EdgeInsets.only(top: 8.0), child: Icon(Icons.auto_awesome, color: Colors.redAccent, size: 20)),
          ],
        ),
      ),
    );
  }

  void _irAlSiguientePaso(BuildContext context, String nivel) {
    controlador.nivelDificultad = nivel; 
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectorContextoVista(controlador: controlador)),
    );
  }
}
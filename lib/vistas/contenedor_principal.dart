import 'package:flutter/material.dart';
import '../controladores/logica_juego.dart';
import 'selector_dificultad_vista.dart';
import 'pantalla_diccionario_vista.dart';
import 'pantalla_repaso_vista.dart';
import 'pantalla_perfil_vista.dart';
import 'pantalla_explora_japon_vista.dart';

class ContenedorPrincipal extends StatefulWidget {
  final LogicaJuego controlador;
  const ContenedorPrincipal({super.key, required this.controlador});

  @override
  State<ContenedorPrincipal> createState() => _ContenedorPrincipalState();
}

class _ContenedorPrincipalState extends State<ContenedorPrincipal> {
  int _indiceActual = 0;

  late final List<Widget> _paginas;

  @override
  void initState() {
    super.initState();
    _paginas = [
      SelectorDificultadVista(controlador: widget.controlador),
      PantallaDiccionarioVista(controlador: widget.controlador),
      PantallaRepasoVista(controlador: widget.controlador),
      const PantallaExploraJapon(),                              // ← NUEVA
      PantallaPerfilVista(controlador: widget.controlador),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indiceActual,
        children: _paginas,
      ),
      bottomNavigationBar: SafeArea(
  child: Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A), // ← importante que esté aquí también
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      boxShadow: const [
        BoxShadow(color: Colors.black38, spreadRadius: 0, blurRadius: 10),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        currentIndex: _indiceActual,
        onTap: (indice) => setState(() => _indiceActual = indice),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.videogame_asset_rounded),
                label: 'Juego',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_rounded),
                label: 'Dicc',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_edu_rounded),
                label: 'Errores',
              ),
              BottomNavigationBarItem(         // ← NUEVA
                icon: Icon(Icons.explore_outlined),
                activeIcon: Icon(Icons.explore),
                label: 'Japón',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    ),
      );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para Firebase
import 'package:tfg_alexandra/vistas/menu_principal.dart';
import 'firebase_options.dart'; // Generado por FlutterFire CLI
import '../controladores/logica_juego.dart';
import 'vistas/contenedor_principal.dart'; 

// --- ESTO ES LO QUE TE FALTA ---
void main() async {
  // 1. Asegura que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase (imprescindible si usas auth o base de datos)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Arranca la aplicación
  runApp(const MyApp());
}

// Clase que configura el tema y la pantalla inicial
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sato-San: Inmersión Japón',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      // Aquí indicas que la primera pantalla sea tu vista de login
      home: const MenuPrincipalVista(), 
    );
  }
}


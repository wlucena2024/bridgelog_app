import 'package:flutter/material.dart';
import '../app/app_routes.dart'; // Importa o arquivo de rotas que acabamos de editar

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PonteLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF0D47A1), // Azul marinho para logística
        useMaterial3: false, // Opcional: mantém o visual clássico do TUF/Gaming que você gosta
      ),
      // Configuração das Rotas
      initialRoute: AppRoutes.splash, 
      routes: AppRoutes.routes,
    );
  }
}
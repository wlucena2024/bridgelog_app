import 'package:flutter/material.dart';
import 'app/app_widget.dart';
import 'services/supabase_client.dart'; 

Future<void> main() async {
  // Garante que os plugins (como Supabase) sejam inicializados antes do app rodar
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa a conexão com o Supabase
  await SupabaseConfig.init();

  // Chama o Widget principal que contém o MaterialApp e as Rotas
  runApp(const AppWidget());
}
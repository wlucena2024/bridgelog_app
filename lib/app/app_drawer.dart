import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final Map<String, dynamic>? userProfile;

  const AppDrawer({super.key, this.userProfile});

  @override
  Widget build(BuildContext context) {
    // Pegamos a primeira letra do nome ou 'U' se estiver vazio
    final String primeiraLetra = userProfile?['nome'] != null && userProfile!['nome'].isNotEmpty
        ? userProfile!['nome'][0].toString().toUpperCase()
        : 'U';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade900),
            accountName: Text(userProfile?['nome'] ?? 'Usuário'),
            accountEmail: Text(userProfile?['email'] ?? 'E-mail não cadastrado'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: userProfile?['foto_perfil_url'] != null
                  ? NetworkImage(userProfile!['foto_perfil_url'])
                  : null,
              child: userProfile?['foto_perfil_url'] == null
                  ? Text(
                      primeiraLetra,
                      style: TextStyle(fontSize: 24, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              Navigator.pop(context); // Fecha o drawer antes de navegar
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Minhas Diárias'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.myJobs);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Meu Perfil (Docs)'),
            onTap: () {
              Navigator.pop(context); 
              // Agora aponta para a rota de perfil que você criou
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
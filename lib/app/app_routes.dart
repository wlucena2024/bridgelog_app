import 'package:flutter/material.dart';
import '../modules/auth/pages/login_page.dart';
import '../modules/auth/pages/register_page.dart';
import '../modules/auth/pages/splash_page.dart';
import '../modules/auth/pages/recover_password_page.dart';
import '../home/home_page.dart';
import '../company/company_feed_page.dart';
import '../company/create_job_page.dart';
import '../modules/auth/pages/my_jobs_page.dart'; 
import '../modules/auth/pages/profile_page.dart';

class AppRoutes {
  // Definição das Strings de Rota
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String recoverPassword = '/recover-password';
  static const String home = '/home';
  static const String companyFeed = '/company-feed';
  static const String createJob = '/create-job';
  static const String profile = '/profile';

  
  // 1. DEFINIÇÃO DA NOVA STRING (Isso resolve o erro da HomePage)
  static const String myJobs = '/my-jobs';

  // Mapa de Rotas para o MaterialApp
  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashPage(),
        login: (context) => const LoginPage(),
        register: (context) => const RegisterPage(),
        recoverPassword: (context) => const RecoverPasswordPage(),
        home: (context) => const HomePage(),
        companyFeed: (context) => const CompanyFeedPage(),
        createJob: (context) => const CreateJobPage(),
        profile: (context) => const ProfilePage(),
        // 2. REGISTRO DA NOVA ROTA
        myJobs: (context) => const MyJobsPage(),
      };
}
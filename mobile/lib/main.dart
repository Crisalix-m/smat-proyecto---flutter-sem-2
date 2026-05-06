import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart'; 
import 'models/estacion.dart';
import 'screens/login_screen.dart'; 
import 'screens/add_estacion.dart';

void main() => runApp(const SMATApp());

class SMATApp extends StatelessWidget {
  const SMATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMAT - Monitoreo Móvil',
      debugShowCheckedModeBanner: false,
      // EL RETO: FutureBuilder decide si mostrar Login o HomePage al arrancar
      home: FutureBuilder<String?>(
        future: AuthService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          
          // Lógica de Redirección Automática
          if (snapshot.hasData && snapshot.data != null) {
            return const HomePage(); // Si hay token, entra directo
          } else {
            return const LoginScreen(); // Si no hay, pide login
          }
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Estacion>> futureEstaciones;

  @override
  void initState() {
    super.initState();
    futureEstaciones = ApiService().fetchEstaciones();
  }

  void _refresh() {
    setState(() {
      futureEstaciones = ApiService().fetchEstaciones();
    });
  }

  // EL RETO: Función para borrar el token y salir al Login
  void _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMAT - Monitoreo Móvil'),
        actions: [
          // EL RETO: Botón de Cerrar Sesión en la barra superior
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: FutureBuilder<List<Estacion>>(
        future: futureEstaciones,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('❌ Error de conexión o sesión expirada'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final est = snapshot.data![index];
                return ListTile(
                  leading: const Icon(Icons.satellite_alt),
                  title: Text(est.nombre),
                  subtitle: Text(est.ubicacion),
                );
              },
            );
          }
        },
      ),
      // Botones flotantes: Refrescar y Agregar Nueva Estación
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btnRefresh",
            onPressed: _refresh,
            mini: true,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "btnAdd",
            backgroundColor: Colors.green,
            onPressed: () async {
              final bool? result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEstacionScreen()),
              );
              if (result == true) _refresh(); // Auto-refresh al volver
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
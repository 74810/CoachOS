import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_os_app/config/theme.dart';

class PerfilEditView extends StatefulWidget {
  const PerfilEditView({super.key});

  @override
  State<PerfilEditView> createState() => _PerfilEditViewState();
}

class _PerfilEditViewState extends State<PerfilEditView> {
  // Conexión con Firebase
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // Estados
  bool _isLoading = true;
  bool _isSaving = false;
  TimeOfDay _inicio = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _fin = const TimeOfDay(hour: 21, minute: 30);

  @override
  void initState() {
    super.initState();
    _cargarDatosDeFirebase();
  }

  // 1. CARGAR DATOS DE LA COLECCIÓN ÚNICA 'usuarios'
  Future<void> _cargarDatosDeFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Apuntamos a la nueva colección centralizada
        DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();
        
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nombreController.text = data['nombre'] ?? "";
            _apellidosController.text = data['apellidos'] ?? "";
            _descController.text = data['descripcion'] ?? "";
            
            // Si quieres cargar los strings de hora y convertirlos a TimeOfDay:
            if (data['horario_inicio'] != null) {
              final partes = data['horario_inicio'].toString().split(':');
              _inicio = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
            }
            if (data['horario_fin'] != null) {
              final partes = data['horario_fin'].toString().split(':');
              _fin = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error al cargar perfil: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. GUARDAR CAMBIOS EN 'usuarios'
  Future<void> _guardarCambios() async {
    if (_nombreController.text.isEmpty) {
      _mostrarSnackBar("El nombre es obligatorio");
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Formateamos la hora para que sea un String limpio "HH:mm"
        String horaInicioStr = "${_inicio.hour.toString().padLeft(2, '0')}:${_inicio.minute.toString().padLeft(2, '0')}";
        String horaFinStr = "${_fin.hour.toString().padLeft(2, '0')}:${_fin.minute.toString().padLeft(2, '0')}";

        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre': _nombreController.text.trim(),
          'apellidos': _apellidosController.text.trim(),
          'descripcion': _descController.text.trim(),
          'horario_inicio': horaInicioStr,
          'horario_fin': horaFinStr,
          'ultimaActualizacion': FieldValue.serverTimestamp(),
          // No sobreescribimos el 'rol' ni el 'uid' para mayor seguridad
        }, SetOptions(merge: true));

        if (mounted) {
          _mostrarSnackBar("Perfil actualizado correctamente");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _mostrarSnackBar("Error al guardar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarSnackBar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Editar Perfil", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          _isSaving 
            ? const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: CupertinoActivityIndicator()))
            : TextButton(
                onPressed: _guardarCambios,
                child: const Text("Guardar", style: TextStyle(color: AppTheme.mediumBlue, fontWeight: FontWeight.bold, fontSize: 16)),
              )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CupertinoActivityIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar estático (Próximamente dinámico)
              const Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.mediumBlue,
                  child: Icon(CupertinoIcons.person_fill, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),

              _sectionTitle("DATOS PERSONALES"),
              _buildTextField("Nombre", _nombreController, icon: CupertinoIcons.person),
              const SizedBox(height: 15),
              _buildTextField("Apellidos", _apellidosController, icon: CupertinoIcons.person_2),
              const SizedBox(height: 15),
              _buildTextField("Descripción", _descController, icon: CupertinoIcons.doc_text, maxLines: 3),

              const SizedBox(height: 30),

              _sectionTitle("MI HORARIO"),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    _timeRow("Empiezo a las:", _inicio, (time) => setState(() => _inicio = time)),
                    const Divider(height: 1),
                    _timeRow("Termino a las:", _fin, (time) => setState(() => _fin = time)),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {required IconData icon, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.mediumBlue, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _timeRow(String label, TimeOfDay time, Function(TimeOfDay) onSelect) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Text(
        time.format(context), 
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)
      ),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onSelect(picked);
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:coach_os_app/config/theme.dart';

class PerfilEditView extends StatefulWidget {
  final String rol;
  const PerfilEditView({super.key, required this.rol});

  @override
  State<PerfilEditView> createState() => _PerfilEditViewState();
}

class _PerfilEditViewState extends State<PerfilEditView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Compartidos
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController(); 
  
  // Exclusivos Entrenador
  final TextEditingController _descController = TextEditingController();
  TimeOfDay _inicio = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _fin = const TimeOfDay(hour: 21, minute: 30);

  // Exclusivos Cliente
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _lesionesController = TextEditingController();
  final TextEditingController _alergiasController = TextEditingController();
  DateTime? _fechaNacimiento;

  bool _isLoading = true;
  bool _isSaving = false;
  late bool _esEntrenador; 

  @override
  void initState() {
    super.initState();
    _esEntrenador = widget.rol.toLowerCase() == 'entrenador';
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nombreController.text = data['nombre'] ?? "";
          _apellidosController.text = data['apellidos'] ?? "";
          _telefonoController.text = data['telefono'] ?? "";
          
          if (_esEntrenador) {
            _descController.text = data['descripcion'] ?? "";
            if (data['horario_inicio_h'] != null) {
              _inicio = TimeOfDay(hour: data['horario_inicio_h'], minute: data['horario_inicio_m']);
              _fin = TimeOfDay(hour: data['horario_fin_h'], minute: data['horario_fin_m']);
            }
          } else {
            // Cargar datos cliente
            _alturaController.text = data['altura']?.toString() ?? "";
            _lesionesController.text = data['lesiones'] ?? "";
            _alergiasController.text = data['alergias'] ?? "";
            if (data['fecha_nacimiento'] != null) {
              _fechaNacimiento = (data['fecha_nacimiento'] as Timestamp).toDate();
            }
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _guardar() async {
    setState(() => _isSaving = true);
    final user = _auth.currentUser;
    
    if (user != null) {
      Map<String, dynamic> dataToUpdate = {
        'nombre': _nombreController.text,
        'apellidos': _apellidosController.text,
        'telefono': _telefonoController.text,
      };

      if (_esEntrenador) {
        dataToUpdate['descripcion'] = _descController.text;
        dataToUpdate['horario'] = "De ${_inicio.format(context)} a ${_fin.format(context)}";
        dataToUpdate['horario_inicio_h'] = _inicio.hour;
        dataToUpdate['horario_inicio_m'] = _inicio.minute;
        dataToUpdate['horario_fin_h'] = _fin.hour;
        dataToUpdate['horario_fin_m'] = _fin.minute;
      } else {
        // Guardar datos cliente
        dataToUpdate['altura'] = _alturaController.text;
        dataToUpdate['lesiones'] = _lesionesController.text;
        dataToUpdate['alergias'] = _alergiasController.text;
        if (_fechaNacimiento != null) {
          dataToUpdate['fecha_nacimiento'] = Timestamp.fromDate(_fechaNacimiento!);
        }
      }

      await _firestore.collection('usuarios').doc(user.uid).update(dataToUpdate);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEntrenador ? "Perfil Profesional" : "Ficha Física"),
        actions: [
          if (!_isLoading) IconButton(
            icon: _isSaving ? const CupertinoActivityIndicator() : const Icon(Icons.check),
            onPressed: _isSaving ? null : _guardar,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CupertinoActivityIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionTitle("INFORMACIÓN BÁSICA"),
              _buildTextField("Nombre", _nombreController, icon: CupertinoIcons.person),
              const SizedBox(height: 15),
              _buildTextField("Apellidos", _apellidosController, icon: CupertinoIcons.person_2),
              const SizedBox(height: 15),
              _buildTextField("Teléfono", _telefonoController, icon: CupertinoIcons.phone, isNumeric: true),
              
              if (_esEntrenador) ...[
                const SizedBox(height: 30),
                _sectionTitle("SOBRE MÍ"),
                _buildTextField("Descripción profesional", _descController, icon: CupertinoIcons.doc_text, maxLines: 4),
                const SizedBox(height: 30),
                _sectionTitle("HORARIO DE ATENCIÓN"),
                _buildHorarioCard(),
              ] else ...[
                const SizedBox(height: 30),
                _sectionTitle("DATOS CLÍNICOS Y FÍSICOS"),
                _buildCard(
                  child: ListTile(
                    leading: const Icon(CupertinoIcons.calendar, color: AppTheme.mediumBlue),
                    title: const Text("Fecha de Nacimiento", style: TextStyle(fontSize: 14)),
                    trailing: Text(
                      _fechaNacimiento == null ? "Seleccionar" : "${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context, 
                        initialDate: _fechaNacimiento ?? DateTime(2000), 
                        firstDate: DateTime(1940), 
                        lastDate: DateTime.now()
                      );
                      if (date != null) setState(() => _fechaNacimiento = date);
                    },
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField("Altura (cm)", _alturaController, icon: CupertinoIcons.arrow_up_down, isNumeric: true),
                const SizedBox(height: 15),
                _buildTextField("Lesiones o patologías", _lesionesController, icon: CupertinoIcons.bandage, maxLines: 3),
                const SizedBox(height: 15),
                _buildTextField("Alergias / Intolerancias", _alergiasController, icon: CupertinoIcons.exclamationmark_triangle, maxLines: 3),
              ]
            ],
          ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {required IconData icon, int maxLines = 1, bool isNumeric = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.mediumBlue, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: child,
    );
  }

  Widget _buildHorarioCard() {
    return _buildCard(
      child: Column(
        children: [
          ListTile(
            title: const Text("Empiezo a las"),
            trailing: Text(_inicio.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            onTap: () async {
              final p = await showTimePicker(context: context, initialTime: _inicio);
              if (p != null) setState(() => _inicio = p);
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text("Termino a las"),
            trailing: Text(_fin.format(context), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            onTap: () async {
              final p = await showTimePicker(context: context, initialTime: _fin);
              if (p != null) setState(() => _fin = p);
            },
          ),
        ],
      ),
    );
  }
}
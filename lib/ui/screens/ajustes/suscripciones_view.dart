import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:coach_os_app/config/theme.dart';

class SuscripcionesView extends StatelessWidget {
  const SuscripcionesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Planes de Negocio", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppTheme.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Elige el nivel de tu academia", 
            style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),
          
          _buildPlanCard(
            context,
            title: "CANTERA",
            price: "GRATIS",
            limit: "Hasta 3 alumnos",
            desc: "Ideal para prácticas y tus primeros pasos.",
            color: Colors.grey,
            isCurrent: true,
          ),
          _buildPlanCard(
            context,
            title: "DRAFT",
            price: "14,90€/mes",
            limit: "Hasta 15 alumnos",
            desc: "Gestión total de tus asesorías y clientes.",
            color: AppTheme.mediumBlue,
          ),
          _buildPlanCard(
            context,
            title: "ALL-STAR",
            price: "29,90€/mes",
            limit: "Hasta 50 alumnos",
            desc: "Gestión total de tus asesorías y clientes.",
            color: Colors.orange,
            isFeatured: true, 
          ),
          _buildPlanCard(
            context,
            title: "HALL OF FAME",
            price: "59,90€/mes",
            limit: "Alumnos ilimitados",
            desc: "Gestión total de tus asesorías y clientes.",
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, {
    required String title, 
    required String price, 
    required String limit, 
    required String desc, 
    required Color color,
    bool isCurrent = false,
    bool isFeatured = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isFeatured ? Border.all(color: color, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              if (isCurrent) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Text("ACTUAL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(limit, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey[200] : color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isCurrent ? null : () => print("Cambiar a $title"),
              child: Text(isCurrent ? "Plan Actual" : "Subir a $title", 
                style: TextStyle(color: isCurrent ? Colors.grey : Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
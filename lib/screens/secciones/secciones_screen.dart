import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/seccion_model.dart';
import '../../providers/seccion_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/shimmer_list.dart';

class SeccionesScreen extends StatefulWidget {
  const SeccionesScreen({super.key});

  @override
  State<SeccionesScreen> createState() => _SeccionesScreenState();
}

class _SeccionesScreenState extends State<SeccionesScreen> {
  String _query = '';

  List<SeccionModel> _filtered(List<SeccionModel> todas) {
    if (_query.isEmpty) return todas;
    final q = _query.toLowerCase();
    return todas.where((s) {
      return s.nombre.toLowerCase().contains(q) ||
          s.codigo.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(
      BuildContext context, SeccionProvider provider, SeccionModel seccion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar seccion'),
        content: Text('¿Eliminar "${seccion.nombre}"? Esta accion no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await provider.deleteSeccion(seccion.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Seccion eliminada' : 'Error al eliminar'),
            backgroundColor: ok ? AppTheme.warningColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secciones')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.seccionesForm),
        child: const Icon(Icons.add),
      ),
      body: ResponsiveBody(child: Consumer<SeccionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const ShimmerList();
          }

          final filtered = _filtered(provider.secciones);

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o codigo...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.class_outlined,
                        title: _query.isEmpty
                            ? 'No hay secciones'
                            : 'Sin resultados para "$_query"',
                        subtitle: _query.isEmpty
                            ? 'Toca + para crear la primera seccion'
                            : null,
                        iconColor: AppTheme.colorSecciones,
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final seccion = filtered[index];
                          return Card(
                            child: ListTile(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.seccionesDetail,
                                arguments: seccion,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.colorSecciones,
                                child: Text(
                                  seccion.codigo.isNotEmpty
                                      ? seccion.codigo.substring(
                                          0, seccion.codigo.length.clamp(0, 2))
                                      : '?',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(seccion.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Turno: ${seccion.turno} · Ano: ${seccion.anioEscolar}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'detalle') {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.seccionesDetail,
                                      arguments: seccion,
                                    );
                                  } else if (value == 'editar') {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.seccionesForm,
                                      arguments: seccion,
                                    );
                                  } else if (value == 'eliminar') {
                                    _confirmDelete(context, provider, seccion);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'detalle',
                                      child: Text('Ver detalle')),
                                  PopupMenuItem(
                                      value: 'editar', child: Text('Editar')),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      )),
    );
  }
}

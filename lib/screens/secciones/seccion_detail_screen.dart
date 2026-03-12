import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/materia_model.dart';
import '../../models/seccion_model.dart';
import '../../providers/materia_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_list.dart';

class SeccionDetailScreen extends StatefulWidget {
  const SeccionDetailScreen({super.key});

  @override
  State<SeccionDetailScreen> createState() => _SeccionDetailScreenState();
}

class _SeccionDetailScreenState extends State<SeccionDetailScreen> {
  late SeccionModel _seccion;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _seccion =
          ModalRoute.of(context)!.settings.arguments as SeccionModel;
      context.read<MateriaProvider>().loadMaterias(_seccion.id);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_seccion.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.seccionesForm,
              arguments: _seccion,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.materiasForm,
          arguments: {'seccionId': _seccion.id},
        ),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(seccion: _seccion),
            const SizedBox(height: 16),
            _MateriasSection(seccion: _seccion),
          ],
        ),
      ),
    );
  }
}

// ─── Card de información general ───────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final SeccionModel seccion;
  const _InfoCard({required this.seccion});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.colorSecciones,
                  child: Text(
                    seccion.codigo.substring(
                        0, seccion.codigo.length.clamp(0, 2)),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seccion.nombre,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Código: ${seccion.codigo}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(
                icon: Icons.schedule, label: 'Turno', value: seccion.turno),
            const SizedBox(height: 8),
            _InfoRow(
                icon: Icons.calendar_today,
                label: 'Año escolar',
                value: seccion.anioEscolar.toString()),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Sección: Materias (subcolección) ──────────────────────────────────────

class _MateriasSection extends StatelessWidget {
  final SeccionModel seccion;
  const _MateriasSection({required this.seccion});

  Future<void> _confirmDelete(
      BuildContext context, MateriaProvider provider, MateriaModel materia) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar materia'),
        content: Text('¿Eliminar "${materia.nombre}" de esta sección?'),
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
      final ok = await provider.deleteMateria(seccion.id, materia.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Materia eliminada' : 'Error al eliminar'),
            backgroundColor: ok ? AppTheme.warningColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Materias',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Consumer<MateriaProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const ShimmerList(itemCount: 3);
            }

            final materias = provider.materias;

            if (materias.isEmpty) {
              return const EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No hay materias',
                subtitle: 'Toca + para agregar la primera materia',
                iconColor: AppTheme.colorMaterias,
              );
            }

            return Column(
              children: materias.map((materia) {
                return Card(
                  child: ListTile(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.materiaDetail,
                      arguments: {
                        'seccionId': seccion.id,
                        'materia': materia,
                      },
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.colorMaterias,
                      child: Text(
                        materia.codigo.isNotEmpty
                            ? materia.codigo
                                .substring(0, materia.codigo.length.clamp(0, 3))
                            : '?',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(materia.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: materia.docente != null
                        ? Text('Prof. ${materia.docente}')
                        : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.materiasForm,
                            arguments: {
                              'seccionId': seccion.id,
                              'materia': materia,
                            },
                          );
                        } else if (value == 'eliminar') {
                          _confirmDelete(context, provider, materia);
                        }
                      },
                      itemBuilder: (_) => const [
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
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

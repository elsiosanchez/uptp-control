import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../models/evaluacion_model.dart';
import '../../models/estudiante_model.dart';
import '../../models/materia_model.dart';
import '../../providers/evaluacion_provider.dart';
import '../../providers/estudiante_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_list.dart';

class MateriaDetailScreen extends StatefulWidget {
  const MateriaDetailScreen({super.key});

  @override
  State<MateriaDetailScreen> createState() => _MateriaDetailScreenState();
}

class _MateriaDetailScreenState extends State<MateriaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _seccionId;
  late MateriaModel _materia;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      _seccionId = args['seccionId'] as String;
      _materia = args['materia'] as MateriaModel;
      context
          .read<EvaluacionProvider>()
          .loadEvaluaciones(_seccionId, _materia.id);
      context
          .read<EstudianteProvider>()
          .loadEstudiantes(_seccionId, _materia.id);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_materia.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Resumen de notas',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.resumenMateria,
              arguments: {
                'seccionId': _seccionId,
                'materiaId': _materia.id,
                'materiaNombre': _materia.nombre,
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'Evaluaciones'),
            Tab(icon: Icon(Icons.people), text: 'Estudiantes'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.pushNamed(context, AppRoutes.evaluacionForm,
                arguments: {
                  'seccionId': _seccionId,
                  'materiaId': _materia.id,
                });
          } else {
            Navigator.pushNamed(context, AppRoutes.estudianteForm,
                arguments: {
                  'seccionId': _seccionId,
                  'materiaId': _materia.id,
                });
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _MateriaInfoCard(materia: _materia),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EvaluacionesTab(
                    seccionId: _seccionId, materiaId: _materia.id),
                _EstudiantesTab(
                    seccionId: _seccionId, materiaId: _materia.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ──────────────────────────────────────────────────────────────

class _MateriaInfoCard extends StatelessWidget {
  final MateriaModel materia;
  const _MateriaInfoCard({required this.materia});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.colorMaterias,
              child: Text(
                materia.codigo.isNotEmpty
                    ? materia.codigo.substring(0, materia.codigo.length.clamp(0, 3))
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(materia.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  if (materia.docente != null)
                    Text('Prof. ${materia.docente}',
                        style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Evaluaciones Tab ───────────────────────────────────────────────────────

class _EvaluacionesTab extends StatelessWidget {
  final String seccionId;
  final String materiaId;
  const _EvaluacionesTab(
      {required this.seccionId, required this.materiaId});

  @override
  Widget build(BuildContext context) {
    return Consumer<EvaluacionProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const ShimmerList(itemCount: 3);

        final evals = provider.evaluaciones;

        return Column(
          children: [
            _PorcentajeIndicator(
              total: provider.porcentajeTotal,
              completas: provider.evaluacionesCompletas,
            ),
            Expanded(
              child: evals.isEmpty
                  ? const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No hay evaluaciones',
                      subtitle: 'Toca + para crear la primera evaluación',
                      iconColor: AppTheme.colorNotas,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<EvaluacionProvider>().loadEvaluaciones(
                            seccionId, materiaId, forceReload: true);
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                      itemCount: evals.length,
                      itemBuilder: (context, index) {
                        final eval = evals[index];
                        return Card(
                          child: ListTile(
                            onTap: () {
                              if (!provider.evaluacionesCompletas) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Las evaluaciones deben sumar 100% para cargar notas'),
                                    backgroundColor: AppTheme.warningColor,
                                  ),
                                );
                                return;
                              }
                              Navigator.pushNamed(
                                  context, AppRoutes.cargaMasiva,
                                  arguments: {
                                    'seccionId': seccionId,
                                    'materiaId': materiaId,
                                    'evaluacion': eval,
                                  });
                            },
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.colorNotas.withOpacity(0.15),
                              child: Text(
                                '${eval.porcentaje.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: AppTheme.colorNotas,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(eval.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: eval.descripcion != null
                                ? Text(eval.descripcion!)
                                : null,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  Navigator.pushNamed(
                                      context, AppRoutes.evaluacionForm,
                                      arguments: {
                                        'seccionId': seccionId,
                                        'materiaId': materiaId,
                                        'evaluacion': eval,
                                      });
                                } else if (value == 'eliminar') {
                                  _confirmDelete(context, provider, eval);
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
                      },
                    ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      EvaluacionProvider provider, EvaluacionModel eval) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evaluación'),
        content: Text(
            '¿Eliminar "${eval.nombre}"? Las notas asociadas se perderán.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok =
          await provider.deleteEvaluacion(seccionId, materiaId, eval.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Evaluación eliminada' : 'Error al eliminar'),
            backgroundColor: ok ? AppTheme.warningColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class _PorcentajeIndicator extends StatelessWidget {
  final double total;
  final bool completas;
  const _PorcentajeIndicator(
      {required this.total, required this.completas});

  @override
  Widget build(BuildContext context) {
    final color = completas
        ? AppTheme.successColor
        : total > 100
            ? AppTheme.errorColor
            : AppTheme.warningColor;
    final message = completas
        ? 'Evaluaciones completas (100%)'
        : total > 100
            ? 'Excede 100% (${total.toStringAsFixed(1)}%)'
            : 'Asignado: ${total.toStringAsFixed(1)}% — Faltan ${(100 - total).toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            completas ? Icons.check_circle : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Estudiantes Tab ────────────────────────────────────────────────────────

class _EstudiantesTab extends StatefulWidget {
  final String seccionId;
  final String materiaId;
  const _EstudiantesTab(
      {required this.seccionId, required this.materiaId});

  @override
  State<_EstudiantesTab> createState() => _EstudiantesTabState();
}

class _EstudiantesTabState extends State<_EstudiantesTab> {
  String _query = '';

  String get seccionId => widget.seccionId;
  String get materiaId => widget.materiaId;

  List<EstudianteModel> _filtered(List<EstudianteModel> todos) {
    if (_query.isEmpty) return todos;
    final q = _query.toLowerCase();
    return todos.where((e) =>
        e.nombreCompleto.toLowerCase().contains(q) ||
        e.cedula.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EstudianteProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) return const ShimmerList(itemCount: 3);

        final todos = provider.estudiantes;
        final estudiantes = _filtered(todos);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${todos.length} estudiantes inscritos',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.importEstudiantes,
                      arguments: {
                        'seccionId': seccionId,
                        'materiaId': materiaId,
                      },
                    ),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Importar'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (todos.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o cédula...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Expanded(
              child: estudiantes.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_add_outlined,
                      title: 'No hay estudiantes',
                      subtitle: 'Toca + para agregar el primer estudiante',
                      iconColor: AppTheme.colorEstudiantes,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<EstudianteProvider>().loadEstudiantes(
                            seccionId, materiaId, forceReload: true);
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                      itemCount: estudiantes.length,
                      itemBuilder: (context, index) {
                        final est = estudiantes[index];
                        final initials = est.nombreCompleto
                            .split(' ')
                            .take(2)
                            .map((p) => p.isNotEmpty ? p[0] : '')
                            .join()
                            .toUpperCase();
                        return Card(
                          child: ListTile(
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.notasEstudiante,
                                arguments: {
                                  'seccionId': seccionId,
                                  'materiaId': materiaId,
                                  'estudiante': est,
                                }),
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.colorEstudiantes,
                              child: Text(initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                            title: Text(est.nombreCompleto,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(est.cedula),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'editar') {
                                  Navigator.pushNamed(
                                      context, AppRoutes.estudianteForm,
                                      arguments: {
                                        'seccionId': seccionId,
                                        'materiaId': materiaId,
                                        'estudiante': est,
                                      });
                                } else if (value == 'eliminar') {
                                  _confirmDelete(context, provider, est);
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
                      },
                    ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context,
      EstudianteProvider provider, EstudianteModel est) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar estudiante'),
        content: Text('¿Eliminar a "${est.nombreCompleto}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok =
          await provider.deleteEstudiante(seccionId, materiaId, est.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(ok ? 'Estudiante eliminado' : 'Error al eliminar'),
            backgroundColor: ok ? AppTheme.warningColor : AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

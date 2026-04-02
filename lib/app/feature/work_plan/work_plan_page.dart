import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/feature/work_plan/data/models/social_technology_one_model.dart';
import 'package:br_thp_meubenapp/app/feature/work_plan/data/repositories/i_work_plan_repository.dart';
import 'package:br_thp_meubenapp/app/feature/work_plan/data/repositories/work_plan_repository.dart';
import 'package:flutter/material.dart';

class WorkPlanPage extends StatefulWidget {
  const WorkPlanPage({super.key});

  @override
  State<WorkPlanPage> createState() => _WorkPlanPageState();
}

class _WorkPlanPageState extends State<WorkPlanPage> {
  late final IWorkPlanRepository _repository;
  Future<SocialTechnologyOneModel>? _futureWorkPlan;
  String? _socialTechnologyId;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _repository = WorkPlanRepository(apiClient: ApiClient());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureWorkPlan != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _socialTechnologyId = args;
      _futureWorkPlan = _repository.getSocialTechnologyOne(
        _socialTechnologyId!,
        _year,
      );
      return;
    }
    if (args is Map<String, dynamic>) {
      final stId = args['stId']?.toString();
      final year = int.tryParse(args['year']?.toString() ?? '');
      if (year != null) {
        _year = year;
      }
      if (stId != null && stId.isNotEmpty) {
        _socialTechnologyId = stId;
      }
    }
    if (_socialTechnologyId != null && _socialTechnologyId!.isNotEmpty) {
      _futureWorkPlan = _repository.getSocialTechnologyOne(
        _socialTechnologyId!,
        _year,
      );
      return;
    }
    _futureWorkPlan = Future.value(SocialTechnologyOneModel.empty());
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Plano de Trabalho',
      subtitle: 'Visualização dos planos de trabalho.',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<SocialTechnologyOneModel>(
          future: _futureWorkPlan,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro ao carregar plano de trabalho: ${snapshot.error}',
                ),
              );
            }

            if (_socialTechnologyId == null || _socialTechnologyId!.isEmpty) {
              return const Center(
                child: Text('Nenhuma tecnologia social foi informada.'),
              );
            }

            final workPlan = snapshot.data ?? SocialTechnologyOneModel.empty();
            final projects = workPlan.project;
            if (projects.isEmpty) {
              return const Center(
                child: Text('Nenhum plano de trabalho encontrado.'),
              );
            }

            return ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final item = projects[index];
                return CardComponents(
                  title: item.name.isEmpty ? 'Projeto' : item.name,
                  image: 'assets/image/logo_workplan.png',
                  subtitle:
                      'Aprovação: ${item.approvalPercentage.toStringAsFixed(0)}%',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/classroom',
                      arguments: {
                        'stId': _socialTechnologyId,
                        'projectId': item.id.toString(),
                        'year': _year,
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

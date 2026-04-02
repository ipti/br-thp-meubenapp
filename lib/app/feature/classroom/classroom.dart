import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/feature/classroom/data/models/classroom_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/classroom/data/repositories/classroom_repository.dart';
import 'package:br_thp_meubenapp/app/feature/classroom/data/repositories/i_classroom_repository.dart';
import 'package:flutter/material.dart';

class ClassroomPage extends StatefulWidget {
  const ClassroomPage({super.key});

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  late final IClassroomRepository _repository;
  Future<List<ClassroomItemModel>>? _futureClassrooms;
  String? _stId;
  String? _projectId;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _repository = ClassroomRepository(apiClient: ApiClient());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureClassrooms != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _stId = args['stId']?.toString();
      _projectId = args['projectId']?.toString();
      final year = int.tryParse(args['year']?.toString() ?? '');
      if (year != null) {
        _year = year;
      }
    }

    if ((_stId ?? '').isNotEmpty && (_projectId ?? '').isNotEmpty) {
      _futureClassrooms = _repository.getClassroomsByProject(
        year: _year,
        socialTechnologyId: _stId!,
        projectId: _projectId!,
      );
    } else {
      _futureClassrooms = Future.value(const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Turmas',
      subtitle: 'Visualização das turmas.',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<ClassroomItemModel>>(
          future: _futureClassrooms,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar turmas: ${snapshot.error}'),
              );
            }

            final classrooms = snapshot.data ?? const [];
            if (classrooms.isEmpty) {
              return const Center(
                child: Text('Nenhuma turma encontrada para este projeto.'),
              );
            }

            return ListView.builder(
              itemCount: classrooms.length,
              itemBuilder: (context, index) {
                final item = classrooms[index];
                return CardComponents(
                  title: item.name,
                  subtitle: 'Turma #${item.id}',
                  image: 'assets/image/logo_classroom.png',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/meeting',
                      arguments: {
                        'stId': _stId,
                        'projectId': _projectId,
                        'classroomId': item.id.toString(),
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

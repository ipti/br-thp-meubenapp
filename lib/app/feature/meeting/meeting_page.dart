import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/utils/formtDate.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/meeting_repository.dart';
import 'package:flutter/material.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  late final IMeetingRepository _repository;

  Future<List<MeetingItemModel>>? _futureMeetings;
  String? _stId;
  String? _projectId;
  String? _classroomId;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _repository = MeetingRepository(apiClient: ApiClient());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureMeetings != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _stId = args['stId']?.toString();
      _projectId = args['projectId']?.toString();
      _classroomId = args['classroomId']?.toString();
      final year = int.tryParse(args['year']?.toString() ?? '');
      if (year != null) {
        _year = year;
      }
    }

    if ((_stId ?? '').isNotEmpty &&
        (_projectId ?? '').isNotEmpty &&
        (_classroomId ?? '').isNotEmpty) {
      _futureMeetings = _repository.getMeetingsByClassroom(
        year: _year,
        socialTechnologyId: _stId!,
        projectId: _projectId!,
        classroomId: _classroomId!,
      );
    } else {
      _futureMeetings = Future.value(const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Encontros',
      subtitle: 'Visualização dos encontros da turma.',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ButtonDefault(
              onPressed: () {},
              iconLeft: Icons.add,
              text: 'Adicionar Encontro',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<MeetingItemModel>>(
                future: _futureMeetings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar encontros: ${snapshot.error}',
                      ),
                    );
                  }

                  final meetings = snapshot.data ?? const [];
                  if (meetings.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum encontro encontrado para esta turma.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      final item = meetings[index];
                      return CardComponents(
                        title: item.name,
                        subtitle:
                            'Data: ${FormtDate.formatDate(item.createdAt)} • Faltas: ${item.fouls}',
                        image: 'assets/image/logo_ts.png',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/meeting_detail',
                            arguments: {
                              'stId': _stId,
                              'projectId': _projectId,
                              'classroomId': _classroomId,
                              'meetingId': item.id.toString(),
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
          ],
        ),
      ),
    );
  }
}

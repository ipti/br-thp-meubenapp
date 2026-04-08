import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/utils/formtDate.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_create_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_item_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/meeting_repository.dart';
import 'package:flutter/material.dart';
import 'dart:io';

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

    _refreshMeetings();
  }

  void _refreshMeetings() {
    setState(() {
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
    });
  }

  Future<void> _openCreateMeetingDialog() async {
    final classroomId = int.tryParse(_classroomId ?? '');
    if (classroomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turma inválida para criar encontro.')),
      );
      return;
    }

    final online = await _checkOnlineStatus();
    var allowUserSelection = online;
    List<MeetingAssigneeModel> users = const [];

    if (online) {
      try {
        users = await _repository.getMeetingAssignableUsers();
      } catch (_) {
        allowUserSelection = false;
      }
    }

    if (!mounted) return;
    final request = await _showCreateMeetingForm(
      context: context,
      classroomId: classroomId,
      users: users,
      allowUserSelection: allowUserSelection,
    );

    if (request == null) return;

    try {
      final result = await _repository.createMeeting(request: request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                (result.createdOnline
                    ? 'Encontro criado com sucesso.'
                    : 'Encontro salvo para sincronização.'),
          ),
        ),
      );
      _refreshMeetings();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar encontro: $e')));
    }
  }

  Future<MeetingCreateRequestModel?> _showCreateMeetingForm({
    required BuildContext context,
    required int classroomId,
    required List<MeetingAssigneeModel> users,
    required bool allowUserSelection,
  }) {
    final nameController = TextEditingController();
    final themeController = TextEditingController();
    final workloadController = TextEditingController();

    DateTime? meetingDate;
    final selectedUsers = <int>{};

    return showDialog<MeetingCreateRequestModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Criar encontro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do encontro *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: workloadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Carga horária (horas) *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: themeController,
                      decoration: const InputDecoration(
                        labelText: 'Tema (opcional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Data do encontro *'),
                      subtitle: Text(
                        meetingDate == null
                            ? 'Selecione uma data'
                            : FormtDate.formatDate(meetingDate!),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: meetingDate ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 2),
                        );
                        if (picked != null) {
                          setModalState(() => meetingDate = picked);
                        }
                      },
                    ),
                    if (allowUserSelection) ...[
                      const SizedBox(height: 8),
                      const Text('Resposáveis vinculados'),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: users.isEmpty
                            ? const Text('Nenhum usuário disponível.')
                            : SingleChildScrollView(
                                child: Column(
                                  children: users.map((user) {
                                    final selected = selectedUsers.contains(
                                      user.id,
                                    );
                                    return CheckboxListTile(
                                      dense: true,
                                      value: selected,
                                      title: Text(user.name),
                                      subtitle: Text(_translateRole(user.role)),
                                      onChanged: (checked) {
                                        setModalState(() {
                                          if (checked == true) {
                                            selectedUsers.add(user.id);
                                          } else {
                                            selectedUsers.remove(user.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Offline: Os responsáveis não serão vinculados neste momento.',
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                ButtonDefault(
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                  text: 'Cancelar',
                ),
                const SizedBox(height: 8),
                ButtonDefault(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final workload =
                        int.tryParse(workloadController.text.trim()) ?? 0;

                    if (name.isEmpty || meetingDate == null || workload <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Preencha nome, data e carga horária.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      MeetingCreateRequestModel(
                        name: name,
                        meetingDate: meetingDate!,
                        workload: workload,
                        classroomId: classroomId,
                        theme: themeController.text.trim(),
                        users: selectedUsers.toList()..sort(),
                      ),
                    );
                  },
                  text: 'Salvar',
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _translateRole(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'USER':
        return 'Usuário';
      case 'REAPPLICATORS':
        return 'Reaplicador';
      case 'COORDINATORS':
        return 'Coordenador';
      default:
        return role;
    }
  }

  Future<bool> _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
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
              onPressed: _openCreateMeetingDialog,
              iconLeft: Icons.add,
              text: 'Adicionar Encontro',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/meeting_sync');
                  if (!mounted) return;
                  _refreshMeetings();
                },
                icon: const Icon(Icons.sync),
                label: const Text('Sincronizar pendências'),
              ),
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
                            'Data: ${FormtDate.formatDate(item.createdAt)} • Faltas: ${item.fouls}${item.isPendingSync ? ' • Pendente de sync' : ''}',
                        image: 'assets/image/logo_ts.png',
                        onTap: () async {
                          await Navigator.pushNamed(
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
                          if (!mounted) return;
                          _refreshMeetings();
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

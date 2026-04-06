import 'dart:io';

import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_detail_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/meeting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({super.key});

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  late final IMeetingRepository _repository;
  Future<MeetingDetailModel?>? _futureDetail;

  int _year = DateTime.now().year;
  String? _stId;
  String? _projectId;
  String? _classroomId;
  String? _meetingId;
  bool _isOnline = false;

  final Set<int> _absentStudentIds = <int>{};
  bool _saving = false;
  bool _uploadingArchive = false;
  final List<MeetingArchiveModel> _archives = [];

  @override
  void initState() {
    super.initState();
    _repository = MeetingRepository(apiClient: ApiClient());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureDetail != null) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _stId = args['stId']?.toString();
      _projectId = args['projectId']?.toString();
      _classroomId = args['classroomId']?.toString();
      _meetingId = args['meetingId']?.toString();
      final yearArg = int.tryParse(args['year']?.toString() ?? '');
      if (yearArg != null) _year = yearArg;
    }

    if ((_stId ?? '').isNotEmpty &&
        (_projectId ?? '').isNotEmpty &&
        (_classroomId ?? '').isNotEmpty &&
        (_meetingId ?? '').isNotEmpty) {
      _futureDetail = _repository.getMeetingDetail(
        year: _year,
        socialTechnologyId: _stId!,
        projectId: _projectId!,
        classroomId: _classroomId!,
        meetingId: _meetingId!,
      );
    } else {
      _futureDetail = Future.value(null);
    }

    _checkOnlineStatus();
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      if (!mounted) return;
      setState(() => _isOnline = result.isNotEmpty);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOnline = false);
    }
  }

  Future<void> _saveFouls(MeetingDetailModel detail) async {
    setState(() => _saving = true);
    try {
      await _repository.saveMeetingFouls(
        meetingId: detail.id,
        absentStudentIds: _absentStudentIds,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faltas salvas com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível enviar as faltas: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _uploadArchive(MeetingDetailModel detail) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fique online para enviar arquivos.'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.gallery);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Plugin de imagem não registrado. Rode um hot restart.',
          ),
        ),
      );
      return;
    }
    if (picked == null) return;

    setState(() => _uploadingArchive = true);
    try {
      final created = await _repository.uploadMeetingArchive(
        meetingId: detail.id,
        imageFile: File(picked.path),
      );
      if (!mounted) return;
      if (created != null) {
        setState(() {
          _archives.removeWhere((item) => item.id == created.id && created.id != 0);
          _archives.add(created);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto enviada com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingArchive = false);
    }
  }

  Future<void> _deleteArchive(int archiveId) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fique online para poder excluir o arquivo.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir arquivo'),
          content: const Text(
            'Tem certeza que deseja excluir este arquivo do encontro?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteMeetingArchive(archiveId: archiveId);
      if (!mounted) return;
      setState(() {
        _archives.removeWhere((item) => item.id == archiveId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo excluído com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir arquivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Detalhes do Encontro',
      subtitle: 'Marcação de presença/falta dos alunos.',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<MeetingDetailModel?>(
          future: _futureDetail,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Erro ao carregar detalhe do encontro: ${snapshot.error}',
                ),
              );
            }

            final detail = snapshot.data;
            if (detail == null) {
              return const Center(
                child: Text('Não foi possível carregar os dados do encontro.'),
              );
            }

            if (_absentStudentIds.isEmpty) {
              _absentStudentIds.addAll(detail.absentStudentIds);
            }
            if (_archives.isEmpty) {
              _archives.addAll(detail.archives);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView(
                    children: [
                      Text('Alunos (${detail.students.length})'),
                      const SizedBox(height: 12),
                      ...detail.students.map((student) {
                        final absent = _absentStudentIds.contains(student.id);

                        return Card(
                          child: CheckboxListTile(
                            value: absent,
                            title: Text(student.name),
                            subtitle: Text(absent ? 'Com falta' : 'Sem falta'),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _absentStudentIds.add(student.id);
                                } else {
                                  _absentStudentIds.remove(student.id);
                                }
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text(
                        'Arquivos do encontro',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _uploadingArchive
                              ? null
                              : () => _uploadArchive(detail),
                          icon: _uploadingArchive
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_a_photo),
                          label: const Text('Adicionar foto'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_archives.isEmpty)
                        const Text('Sem arquivos para este encontro.'),
                      ..._archives.map((archive) {
                        if (_isOnline) {
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  archive.archiveUrl,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return const SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Icon(Icons.link),
                                    );
                                  },
                                ),
                              ),
                              title: Text(archive.originalName),
                              trailing: archive.id > 0
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteArchive(archive.id),
                                    )
                                  : null,
                            ),
                          );
                        }

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.insert_drive_file_outlined,
                            ),
                            title: Text(archive.originalName),
                            subtitle: const Text(
                              'Arquivo disponível offline (nome).',
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ButtonDefault(
                    onPressed: _saving ? null : () => _saveFouls(detail),
                    isLoading: _saving,
                    text: 'Salvar faltas',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

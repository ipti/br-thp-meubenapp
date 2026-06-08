import 'dart:io';

import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/models/meeting_detail_model.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/meeting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({super.key});

  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  static const String _statusApprovedAsset = 'assets/image/status-approved.svg';
  static const String _statusDesapprovedAsset =
      'assets/image/status-desapproved.svg';

  late final IMeetingRepository _repository;
  Future<MeetingDetailModel?>? _futureDetail;

  int _year = DateTime.now().year;
  String? _stId;
  String? _projectId;
  String? _classroomId;
  String? _meetingId;
  bool _isOnline = false;

  final Set<int> _absentStudentIds = <int>{};
  final Set<int> _savedAbsentStudentIds = <int>{};
  bool _saving = false;
  bool _uploadingArchive = false;
  final List<MeetingArchiveModel> _archives = [];
  int? _stateInitializedForMeetingId;

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

    _futureDetail = _buildDetailFuture();

    _checkOnlineStatus();
  }

  Future<MeetingDetailModel?> _buildDetailFuture() {
    if ((_stId ?? '').isNotEmpty &&
        (_projectId ?? '').isNotEmpty &&
        (_classroomId ?? '').isNotEmpty &&
        (_meetingId ?? '').isNotEmpty) {
      return _repository.getMeetingDetail(
        year: _year,
        socialTechnologyId: _stId!,
        projectId: _projectId!,
        classroomId: _classroomId!,
        meetingId: _meetingId!,
      );
    }
    return Future.value(null);
  }

  void _refreshDetail() {
    setState(() {
      _futureDetail = _buildDetailFuture();
      _stateInitializedForMeetingId = null;
    });
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
      _savedAbsentStudentIds
        ..clear()
        ..addAll(_absentStudentIds);
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

  bool _hasUnsavedFoulsChanges() {
    if (_savedAbsentStudentIds.length != _absentStudentIds.length) {
      return true;
    }
    for (final id in _savedAbsentStudentIds) {
      if (!_absentStudentIds.contains(id)) return true;
    }
    return false;
  }

  Future<void> _uploadArchive(MeetingDetailModel detail) async {
    final picker = ImagePicker();
    final imageSource = await _showImageSourcePicker();
    if (imageSource == null) return;

    XFile? picked;
    try {
      picked = await picker.pickImage(source: imageSource);
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
          _archives.removeWhere(
            (item) => item.id == created.id && created.id != 0,
          );
          _archives.add(created);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created?.isPendingSync == true
                ? 'Arquivo salvo localmente e aguardando sincronização.'
                : 'Arquivo enviado com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $e')));
    } finally {
      if (mounted) setState(() => _uploadingArchive = false);
    }
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Selecionar da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar foto com a câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteArchive(int archiveId) async {
    if (archiveId > 0 && !_isOnline) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir arquivo: $e')));
    }
  }

  bool _hasLocalPreview(MeetingArchiveModel archive) {
    return (archive.localPath ?? '').trim().isNotEmpty;
  }

  bool _canPreviewArchive(MeetingArchiveModel archive) {
    return _hasLocalPreview(archive) ||
        (_isOnline && archive.archiveUrl.trim().isNotEmpty);
  }

  String _archiveSubtitle(MeetingArchiveModel archive) {
    if (archive.isPendingSync && _hasLocalPreview(archive)) {
      return 'Arquivo pendente de sincronização. Toque para ampliar.';
    }
    if (archive.isPendingSync) {
      return 'Arquivo pendente de sincronização.';
    }
    if (_hasLocalPreview(archive)) {
      return _isOnline
          ? 'Imagem local disponível. Toque para ampliar.'
          : 'Imagem local (offline). Toque para ampliar.';
    }
    if (_isOnline && archive.archiveUrl.isNotEmpty) {
      return 'Toque para ampliar.';
    }
    if (!_isOnline && archive.archiveUrl.isNotEmpty) {
      return 'Sem internet para carregar a imagem.';
    }
    return 'Arquivo disponível offline (nome).';
  }

  Widget _archiveLeading(MeetingArchiveModel archive) {
    if (_hasLocalPreview(archive)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(
          File(archive.localPath!),
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.image_not_supported_outlined),
            );
          },
        ),
      );
    }

    if (_isOnline && archive.archiveUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          archive.archiveUrl,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              width: 42,
              height: 42,
              child: Icon(Icons.link),
            );
          },
        ),
      );
    }

    if (!_isOnline && archive.archiveUrl.isNotEmpty) {
      return const Icon(Icons.cloud_off_outlined, color: Colors.orange);
    }

    return const Icon(Icons.insert_drive_file_outlined);
  }

  Future<void> _openArchivePreview(MeetingArchiveModel archive) async {
    if (!_canPreviewArchive(archive)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem conexão para visualizar este arquivo agora.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        final imageWidget = _hasLocalPreview(archive)
            ? Image.file(
                File(archive.localPath!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white70,
                      size: 56,
                    ),
                  );
                },
              )
            : Image.network(
                archive.archiveUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, size: 56),
                  );
                },
              );

        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(child: imageWidget),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
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

            if (_stateInitializedForMeetingId != detail.id) {
              _stateInitializedForMeetingId = detail.id;
              _absentStudentIds.clear();
              _absentStudentIds.addAll(detail.absentStudentIds);
              _savedAbsentStudentIds.clear();
              _savedAbsentStudentIds.addAll(detail.absentStudentIds);
              _archives.clear();
              _archives.addAll(detail.archives);
            }

            final hasUnsavedChanges = _hasUnsavedFoulsChanges();

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
                Text(
                  _isOnline
                      ? 'Status de rede: online'
                      : 'Status de rede: offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasUnsavedChanges
                        ? Colors.orange.withValues(alpha: 0.14)
                        : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasUnsavedChanges
                          ? Colors.orange.withValues(alpha: 0.5)
                          : Colors.green.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasUnsavedChanges
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        color: hasUnsavedChanges
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasUnsavedChanges
                              ? 'Você alterou faltas. Toque em "Salvar faltas" para confirmar.'
                              : 'Faltas sincronizadas com o último salvamento.',
                          style: TextStyle(
                            color: hasUnsavedChanges
                                ? Colors.orange.shade900
                                : Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      Text('Alunos (${detail.students.length})'),
                      const SizedBox(height: 8),
                      _buildAttendanceLegend(),
                      const SizedBox(height: 12),
                      ...detail.students.map((student) {
                        final absent = _absentStudentIds.contains(student.id);

                        return Card(
                          child: ListTile(
                            onTap: () => _toggleStudentAbsence(
                              student.id,
                              isAbsent: absent,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueGrey.withValues(
                                alpha: 0.12,
                              ),
                              child: const Icon(Icons.person_outline),
                            ),
                            title: Text(student.name),
                            subtitle: Text(absent ? 'Faltou' : 'Presença'),
                            trailing: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _toggleStudentAbsence(
                                student.id,
                                isAbsent: absent,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: SvgPicture.asset(
                                  absent
                                      ? _statusDesapprovedAsset
                                      : _statusApprovedAsset,
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                            ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo),
                          label: const Text('Adicionar foto'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/meeting_sync');
                            if (!mounted) return;
                            await _checkOnlineStatus();
                            _refreshDetail();
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Abrir fila de sincronização'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_archives.isEmpty)
                        const Text('Sem arquivos para este encontro.'),
                      ..._archives.map((archive) {
                        final canPreview = _canPreviewArchive(archive);
                        final canDelete =
                            archive.isPendingSync ||
                            (_isOnline && archive.id > 0);
                        return Card(
                          child: ListTile(
                            onTap: canPreview
                                ? () => _openArchivePreview(archive)
                                : null,
                            leading: _archiveLeading(archive),
                            title: Text(
                              archive.originalName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _archiveSubtitle(archive),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                if (canPreview)
                                  IconButton(
                                    icon: const Icon(Icons.zoom_in),
                                    tooltip: 'Visualizar imagem',
                                    onPressed: () =>
                                        _openArchivePreview(archive),
                                  ),
                                if (canDelete)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteArchive(archive.id),
                                  ),
                              ],
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
                    onPressed: (_saving || !hasUnsavedChanges)
                        ? null
                        : () => _saveFouls(detail),
                    isLoading: _saving,
                    text: hasUnsavedChanges
                        ? 'Salvar faltas'
                        : 'Faltas já salvas',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttendanceLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem(assetPath: _statusApprovedAsset, label: 'Presença'),
        _buildLegendItem(assetPath: _statusDesapprovedAsset, label: 'Faltou'),
      ],
    );
  }

  Widget _buildLegendItem({required String assetPath, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(assetPath, width: 18, height: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _toggleStudentAbsence(int studentId, {required bool isAbsent}) {
    setState(() {
      if (isAbsent) {
        _absentStudentIds.remove(studentId);
      } else {
        _absentStudentIds.add(studentId);
      }
    });
  }
}

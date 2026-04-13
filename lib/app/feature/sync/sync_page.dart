import 'dart:io';

import 'package:br_thp_meubenapp/app/core/components/button/button_default.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/i_meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/meeting/data/repositories/meeting_repository.dart';
import 'package:br_thp_meubenapp/app/feature/sync/data/models/sync_queue_item_model.dart';
import 'package:flutter/material.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  late final IMeetingRepository _repository;

  bool _loading = true;
  bool _syncing = false;
  int? _removingLocalId;
  bool _isOnline = false;
  List<SyncQueueItemModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _repository = MeetingRepository(apiClient: ApiClient());
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _loading = true);
    final online = await _checkOnlineStatus();
    final items = await _repository.getSyncQueueItems();
    if (!mounted) return;
    setState(() {
      _items = items;
      _isOnline = online;
      _loading = false;
    });
  }

  Future<bool> _checkOnlineStatus() async {
    try {
      final result = await InternetAddress.lookup('one.one.one.one');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);

    try {
      final result = await _repository.syncPendingActions();
      if (!mounted) return;

      if (result.requiresLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sessao expirada durante a sincronizacao. Faça login novamente.',
            ),
          ),
        );
        return;
      }

      final message =
          'Sincronizados: ${result.successCount} | '
          'Falhas: ${result.failedCount} | '
          'Pendentes: ${result.remainingCount}';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao sincronizar: $e')));
    } finally {
      await _loadQueue();
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _removeSyncItem(SyncQueueItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir sincronização'),
          content: Text(
            'Deseja excluir esta ação da fila?\n\n"${item.description}"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _removingLocalId = item.localId);
    try {
      await _repository.deleteSyncQueueItem(item);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronização removida da fila.')),
      );
      await _loadQueue();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao excluir item: $e')));
    } finally {
      if (mounted) {
        setState(() => _removingLocalId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items
        .where((item) => item.status == SyncQueueStatus.pending)
        .length;
    final failed = _items
        .where((item) => item.status == SyncQueueStatus.failed)
        .length;
    final synced = _items
        .where((item) => item.status == SyncQueueStatus.synced)
        .length;

    return PageDefault(
      title: 'Sincronização Offline',
      subtitle: 'Acompanhe e envie faltas/arquivos pendentes.',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _isOnline ? Icons.wifi : Icons.wifi_off,
                        color: _isOnline ? Colors.green : Colors.orange,
                      ),
                      title: Text(_isOnline ? 'Online' : 'Offline'),
                      subtitle: Text(
                        _isOnline
                            ? 'Você já pode sincronizar agora.'
                            : 'Sem internet, a fila permanece local.',
                      ),
                      trailing: IconButton(
                        onPressed: _loadQueue,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Resumo da fila',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCounterChip(
                        'Pendentes',
                        pending,
                        backgroundColor: Colors.orange.withValues(alpha: 0.18),
                        textColor: Colors.orange.shade900,
                      ),
                      _buildCounterChip(
                        'Falharam',
                        failed,
                        backgroundColor: Colors.red.withValues(alpha: 0.14),
                        textColor: Colors.red.shade800,
                      ),
                      _buildCounterChip(
                        'Sincronizados',
                        synced,
                        backgroundColor: Colors.green.withValues(alpha: 0.16),
                        textColor: Colors.green.shade800,
                      ),
                      _buildCounterChip(
                        'Total',
                        _items.length,
                        backgroundColor: Colors.blueGrey.withValues(
                          alpha: 0.14,
                        ),
                        textColor: Colors.blueGrey.shade800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ButtonDefault(
                    onPressed: _syncing ? null : _syncNow,
                    text: 'Sincronizar agora',
                    iconLeft: Icons.sync,
                    isLoading: _syncing,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _items.isEmpty
                        ? const Center(
                            child: Text('Nenhuma ação registrada na fila.'),
                          )
                        : ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final statusColor = _statusColor(item.status);
                              final isRemoving =
                                  _removingLocalId == item.localId;
                              return Card(
                                child: ListTile(
                                  leading: Icon(_typeIcon(item.type)),
                                  title: Text(item.description),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.14,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(item.status),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        tooltip: 'Excluir da fila',
                                        onPressed: (_syncing || isRemoving)
                                            ? null
                                            : () => _removeSyncItem(item),
                                        icon: isRemoving
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                              ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Criado por: ${item.createdBy}\n'
                                    'Em: ${_formatDate(item.createdAt)}'
                                    '${item.errorMessage == null ? '' : '\nErro: ${item.errorMessage}'}',
                                  ),
                                  isThreeLine: true,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCounterChip(
    String label,
    int value, {
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Chip(
      backgroundColor: backgroundColor,
      side: BorderSide(color: textColor.withValues(alpha: 0.25)),
      label: Text(
        '$label: $value',
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  IconData _typeIcon(SyncQueueType type) {
    switch (type) {
      case SyncQueueType.fouls:
        return Icons.fact_check_outlined;
      case SyncQueueType.archives:
        return Icons.photo_library_outlined;
      case SyncQueueType.meetingCreate:
        return Icons.event_note_outlined;
    }
  }

  String _statusLabel(SyncQueueStatus status) {
    switch (status) {
      case SyncQueueStatus.pending:
        return 'Pendente';
      case SyncQueueStatus.processing:
        return 'Processando';
      case SyncQueueStatus.synced:
        return 'Sincronizado';
      case SyncQueueStatus.failed:
        return 'Falhou';
    }
  }

  Color _statusColor(SyncQueueStatus status) {
    switch (status) {
      case SyncQueueStatus.pending:
        return Colors.orange.shade800;
      case SyncQueueStatus.processing:
        return Colors.blue.shade800;
      case SyncQueueStatus.synced:
        return Colors.green.shade800;
      case SyncQueueStatus.failed:
        return Colors.red.shade700;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

import 'package:br_thp_meubenapp/app/feature/sync/data/local/sync_queue_local_datasource.dart';
import 'package:br_thp_meubenapp/app/core/service/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:br_thp_meubenapp/app/core/theme/app_colors.dart';

class PageDefault extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final Widget body;
  const PageDefault({super.key, this.title, this.subtitle, required this.body});

  @override
  State<PageDefault> createState() => _PageDefaultState();
}

class _PageDefaultState extends State<PageDefault> {
  late final SyncQueueLocalDatasource _syncQueueLocalDatasource;

  @override
  void initState() {
    super.initState();
    _syncQueueLocalDatasource = SyncQueueLocalDatasource();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppUpdateService.checkAndPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtitle =
        widget.subtitle != null && widget.subtitle!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: Image.asset('assets/image/logo.png', height: 32),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: _syncQueueLocalDatasource.watchPendingCount(),
            initialData: 0,
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              return IconButton(
                tooltip: pendingCount > 0
                    ? '$pendingCount sincronizações pendentes'
                    : 'Sincronização',
                onPressed: () async {
                  await Navigator.pushNamed(context, '/meeting_sync');
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.sync),
                    if (pendingCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            pendingCount > 99 ? '99+' : '$pendingCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Perfil',
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.title ?? '',
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          if (hasSubtitle) const SizedBox(height: 8),
          if (hasSubtitle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(widget.subtitle!),
            ),
          Expanded(child: widget.body),
        ],
      ),
    );
  }
}

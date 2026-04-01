import 'dart:convert';

import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/network/api_exception.dart';
import 'package:br_thp_meubenapp/app/core/network/api_response.dart';
import 'package:br_thp_meubenapp/app/feature/api_examples/data/repositories/api_examples_repository.dart';
import 'package:br_thp_meubenapp/app/feature/api_examples/data/repositories/i_api_examples_repository.dart';
import 'package:flutter/material.dart';

class ApiExamplesPage extends StatefulWidget {
  const ApiExamplesPage({super.key});

  @override
  State<ApiExamplesPage> createState() => _ApiExamplesPageState();
}

class _ApiExamplesPageState extends State<ApiExamplesPage> {
  late final IApiExamplesRepository _repository;
  bool _loading = false;
  String _responseText = 'Nenhuma chamada executada ainda.';

  @override
  void initState() {
    super.initState();
    _repository = ApiExamplesRepository(apiClient: ApiClient());
  }

  Future<void> _execute(
    Future<ApiResponse> Function() request, {
    required String successMessage,
  }) async {
    setState(() => _loading = true);
    try {
      final response = await request();
      final prettyJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(response.data);

      setState(() {
        _responseText = 'Status: ${response.statusCode}\n\n$prettyJson';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _responseText = e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro na API: ${e.toString()}')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _responseText = 'Erro inesperado na requisicao.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado na requisicao.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Exemplos de API',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('GET, POST, PUT, PATCH e DELETE com try/catch'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _execute(
                          _repository.getWorkPlans,
                          successMessage: 'GET executado com sucesso.',
                        ),
                  child: const Text('GET /api/work-plans'),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _execute(
                          _repository.createWorkPlan,
                          successMessage: 'POST executado com sucesso.',
                        ),
                  child: const Text('POST /api/work-plans'),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _execute(
                          () => _repository.updateWorkPlanPut(1),
                          successMessage: 'PUT executado com sucesso.',
                        ),
                  child: const Text('PUT /api/work-plans/1'),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _execute(
                          () => _repository.updateWorkPlanPatch(1),
                          successMessage: 'PATCH executado com sucesso.',
                        ),
                  child: const Text('PATCH /api/work-plans/1'),
                ),
                ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _execute(
                          () => _repository.deleteWorkPlan(1),
                          successMessage: 'DELETE executado com sucesso.',
                        ),
                  child: const Text('DELETE /api/work-plans/1'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(_responseText),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

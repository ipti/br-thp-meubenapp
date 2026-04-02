import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:br_thp_meubenapp/app/core/network/api_client.dart';
import 'package:br_thp_meubenapp/app/core/utils/enum/areaOfActivitity.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/models/social_technology_model.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/repositories/i_social_tecnology_repository.dart';
import 'package:br_thp_meubenapp/app/feature/social_tecnology/data/repositories/social_tecnology_repository.dart';
import 'package:flutter/material.dart';

class SocialTecnollogyPage extends StatefulWidget {
  const SocialTecnollogyPage({super.key, required this.title});

  final String title;

  @override
  State<SocialTecnollogyPage> createState() => _SocialTecnollogyPageState();
}

class _SocialTecnollogyPageState extends State<SocialTecnollogyPage> {
  late final ISocialTecnollogyRepository _repository;
  late Future<List<SocialTechnologyModel>> _futureSocialTechnologies;
  late int _selectedYear;
  late List<int> _yearOptions;

  @override
  void initState() {
    super.initState();
    final nowYear = DateTime.now().year;
    _selectedYear = nowYear;
    _yearOptions = List<int>.generate(7, (index) => nowYear - 3 + index);
    _repository = SocialTecnollogyRepository(apiClient: ApiClient());
    _futureSocialTechnologies = _repository.getSocialTechnologyUser(
      year: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: widget.title,
      subtitle: 'Visualização das tecnologias sociais.',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Ano:'),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _selectedYear,
                  items: _yearOptions
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedYear = value;
                      _futureSocialTechnologies =
                          _repository.getSocialTechnologyUser(
                        year: _selectedYear,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<SocialTechnologyModel>>(
                future: _futureSocialTechnologies,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar tecnologias: ${snapshot.error}'),
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma tecnologia social encontrada.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final socialTechnology = items[index];
                      return CardComponents(
                        title: socialTechnology.name,
                        subtitle: AreaOfActivity.fromString(
                          socialTechnology.areaOfActivity,
                        ).label,
                        image: 'assets/image/logo_ts.png',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/work_plan',
                            arguments: {
                              'stId': socialTechnology.id.toString(),
                              'year': _selectedYear,
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

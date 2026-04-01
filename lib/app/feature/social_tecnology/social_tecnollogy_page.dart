import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:flutter/material.dart';

class SocialTecnollogyPage extends StatefulWidget {
  const SocialTecnollogyPage({super.key, required this.title});

  final String title;

  @override
  State<SocialTecnollogyPage> createState() => _SocialTecnollogyPageState();
}

class _SocialTecnollogyPageState extends State<SocialTecnollogyPage> {
  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: widget.title,
      subtitle: 'Visualização das tecnologias sociais.',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/api_examples');
                },
                child: const Text('Abrir exemplos da API'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return CardComponents(
                    title: 'Card $index',
                    subtitle: 'Subtitle $index',
                    image: 'assets/image/logo_ts.png',
                    onTap: () {
                      Navigator.pushNamed(context, '/work_plan');
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

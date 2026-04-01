import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:br_thp_meubenapp/app/core/components/page_default/page_default.dart';
import 'package:flutter/material.dart';

class WorkPlanPage extends StatefulWidget {
  const WorkPlanPage({super.key});

  @override
  State<WorkPlanPage> createState() => _WorkPlanPageState();
}

class _WorkPlanPageState extends State<WorkPlanPage> {
  @override
  Widget build(BuildContext context) {
    return PageDefault(
      title: 'Plano de Trabalho',
      subtitle: 'Visualização dos planos de trabalho.',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return CardComponents(
              title: 'Card $index',
              subtitle: 'Subtitle $index',
              image: 'assets/image/logo_workplan.png',
              onTap: () {
                Navigator.pushNamed(context, '/classroom');
              },
            );
          },
        ),
      ),
    );
  }
}

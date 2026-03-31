import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:flutter/material.dart';

class ClassroomPage extends StatefulWidget {
  const ClassroomPage({super.key});

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

class _ClassroomPageState extends State<ClassroomPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Turmas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            return CardComponents(
              title: 'Card $index',
              subtitle: 'Subtitle $index',
              image: 'assets/image/logo_classroom.png',
            );
          },
        ),
      ),
    );
  }
}

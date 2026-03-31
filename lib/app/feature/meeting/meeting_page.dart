import 'package:br_thp_meubenapp/app/core/components/card/card_components.dart';
import 'package:flutter/material.dart';

class MeetingPage extends StatefulWidget {
  const MeetingPage({super.key});

  @override
  State<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Encontros'),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: Text('Adicionar Encontro')),
            SizedBox(height: 16),
            ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return CardComponents(
                  title: 'Card $index',
                  subtitle: 'Subtitle $index',
                  image: 'assets/image/logo_meeting.png',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

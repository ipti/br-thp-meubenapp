import 'package:br_thp_meubenapp/app/feature/social_tecnology/social_tecnollogy_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return SocialTecnollogyPage(title: 'Tecnologias Sociais');
  }
}

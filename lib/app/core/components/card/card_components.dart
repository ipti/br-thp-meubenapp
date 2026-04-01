import 'package:flutter/material.dart';

class CardComponents extends StatefulWidget {
  const CardComponents({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String image;
  final VoidCallback? onTap;

  @override
  State<CardComponents> createState() => _CardComponentsState();
}

class _CardComponentsState extends State<CardComponents> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Image.asset(widget.image),
              const SizedBox(width: 16),
              Column(children: [Text(widget.title), Text(widget.subtitle)]),
            ],
          ),
        ),
      ),
    );
  }
}

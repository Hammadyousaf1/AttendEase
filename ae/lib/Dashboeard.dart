import 'package:flutter/material.dart';

class Dashboeard extends StatefulWidget {
  const Dashboeard({super.key});

  @override
  State<Dashboeard> createState() => _DashboeardState();
}

class _DashboeardState extends State<Dashboeard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text('Dashboard'),
    );
  }
}

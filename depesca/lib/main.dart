import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class BackgroundScaffold extends StatelessWidget {
  const BackgroundScaffold({
    required this.title,
    required this.body,
    super.key,
    this.showBack = false,
  });

  final String title;
  final Widget body;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(title),
        leading: showBack ? const BackButton() : null,
      ),
      drawer: isDesktop ? null : const _MainMenu(),
      drawerScrimColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            if (isDesktop) const SizedBox(width: 280, child: _MainMenu()),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _MainMenu extends StatelessWidget {
  const _MainMenu();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Menú',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              initiallyExpanded: false,
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              title: const Text(
                'Herramientas',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                ListTile(
                  title: const Text(
                    'Calendario lunar',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LunarCalendarScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BackgroundScaffold(title: 'Inicio', body: Center());
  }
}

class LunarCalendarScreen extends StatefulWidget {
  const LunarCalendarScreen({super.key});

  @override
  State<LunarCalendarScreen> createState() => _LunarCalendarScreenState();
}


class _MoonPhaseViewData {
  const _MoonPhaseViewData({
    required this.phase,
    required this.dateTime,
    this.imageAsset,
  });

  final String phase;
  final DateTime dateTime;
  final String? imageAsset;
}

class _LunarCalendarScreenState extends State<LunarCalendarScreen> {
  late int _selectedYear;
  late int _selectedMonth;
  bool _loading = false;
  String? _error;
  List<_MoonPhaseViewData> _results = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  Future<void> _loadMoonPhases() async {
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    final uri = Uri.parse(
      'https://aa.usno.navy.mil/api/moon/phases/year?year=$_selectedYear',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Error HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final phaseData = (data['phasedata'] as List<dynamic>? ?? []);
      final filtered = phaseData.where((item) {
        final map = item as Map<String, dynamic>;
        return map['month'] == _selectedMonth;
      }).map((item) {
        final map = item as Map<String, dynamic>;
        final day = map['day'] as int? ?? 1;
        final time = map['time'] as String? ?? '00:00';
        final parts = time.split(':');
        final hour = int.tryParse(parts.first) ?? 0;
        final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
        final phase = map['phase'] as String? ?? '';

        return _MoonPhaseViewData(
          phase: phase,
          dateTime: DateTime(_selectedYear, _selectedMonth, day, hour, minute),
          imageAsset: _assetForPhase(phase),
        );
      }).toList();

      setState(() {
        _results = filtered;
      });
    } catch (e) {
      setState(() {
        _error = 'No se pudieron obtener los datos: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }



  String? _assetForPhase(String phase) {
    switch (phase) {
      case 'New Moon':
        return 'assets/images/m1.png';
      case 'First Quarter':
        return 'assets/images/m2.png';
      case 'Full Moon':
        return 'assets/images/m3.png';
      case 'Last Quarter':
        return 'assets/images/m4.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      title: 'Calendario lunar',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildForm(), const SizedBox(height: 24), _buildResults()],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consultar fases lunares',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    initialValue: '$_selectedYear',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final year = int.tryParse(value);
                      if (year != null) _selectedYear = year;
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Mes',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem<int>(
                        value: month,
                        child: Text(month.toString().padLeft(2, '0')),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      }
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _loading ? null : _loadMoonPhases,
                  child: const Text('Aceptar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.redAccent));
    }
    if (_results.isEmpty) {
      return const Text(
        'No hay datos para el período seleccionado.',
        style: TextStyle(color: Colors.white),
      );
    }

    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth >= 700;
        return Wrap(
          direction: isLarge ? Axis.horizontal : Axis.vertical,
          spacing: 12,
          runSpacing: 12,
          children: _results.map((item) {
            return SizedBox(
              width: isLarge ? 220 : constraints.maxWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.phase, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(dateFormatter.format(item.dateTime)),
                      if (item.imageAsset != null) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: Image.asset(item.imageAsset!, height: 90, fit: BoxFit.contain),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

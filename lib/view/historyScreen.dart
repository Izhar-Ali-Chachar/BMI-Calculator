import 'package:flutter/material.dart';
import '../data/bmi_database.dart';
import '../model/BmiRecord.dart';

class HistoryScreen extends StatefulWidget {
  final List<BMIRecord>? initialRecords;
  const HistoryScreen({Key? key, this.initialRecords}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<BMIRecord>> _futureRecords;

  @override
  void initState() {
    super.initState();
    // use prefetched records if provided, otherwise fetch now
    _futureRecords = widget.initialRecords != null
        ? Future.value(widget.initialRecords!)
        : BMIDatabase.instance.getRecords();
  }

  void _reload() {
    setState(() {
      _futureRecords = BMIDatabase.instance.getRecords();
    });
  }

  Future<void> _clearAll() async {
    await BMIDatabase.instance.deleteAll();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI History'),
        backgroundColor: const Color(0xFFFF6B35),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Clear history'),
                  content: const Text('Delete all saved BMI records?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirmed == true) {
                await _clearAll();
              }
            },
          )
        ],
      ),
      body: FutureBuilder<List<BMIRecord>>(
        future: _futureRecords,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }
          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = records[index];
              final date = DateTime.tryParse(r.createdAt);
              final dateStr = date != null ? '${date.toLocal()}' : r.createdAt;
              return ListTile(
                title: Text('${r.bmi.toStringAsFixed(1)} — ${r.category}'),
                subtitle: Text('H: ${r.height.toInt()} cm • W: ${r.weight.toInt()} kg • ${r.gender}\n$dateStr'),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}

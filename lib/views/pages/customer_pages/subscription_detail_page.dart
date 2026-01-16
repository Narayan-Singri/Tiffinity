import 'package:flutter/material.dart';

class SubscriptionDetailPage extends StatefulWidget {
  final String messName;
  final String nextDay;
  final List<String> items;

  const SubscriptionDetailPage({
    super.key,
    required this.messName,
    required this.nextDay,
    required this.items,
  });

  @override
  State<SubscriptionDetailPage> createState() => _SubscriptionDetailPageState();
}

class _SubscriptionDetailPageState extends State<SubscriptionDetailPage> {
  late Map<String, bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (final item in widget.items) item: true};
  }

  void _toggle(String item, bool value) {
    setState(() {
      _selected[item] = value;
    });
  }

  void _save() {
    final chosen = _selected.entries.where((e) => e.value).map((e) => e.key).toList();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved next day items: ${chosen.join(', ')}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.messName} - ${widget.nextDay}'),
        backgroundColor: const Color.fromARGB(255, 27, 84, 78),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select items for next day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: _selected.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _selected.keys.elementAt(index);
                  final checked = _selected[item] ?? false;
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) => _toggle(item, v ?? false),
                    title: Text(item),
                    activeColor: const Color.fromARGB(255, 27, 84, 78),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 27, 84, 78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save for next day',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

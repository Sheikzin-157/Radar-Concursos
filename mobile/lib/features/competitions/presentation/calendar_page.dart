import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';

final calendarEventsProvider = FutureProvider.autoDispose<List<CalendarEvent>>((ref) async {
  final result = await ApiClient().getMap('/competition-events');
  final items = result['items'];
  if (items is! List) throw const FormatException('Lista de eventos inválida');
  return items.map((item) {
    final map = Map<String, dynamic>.from(item as Map);
    return CalendarEvent(
      competitionId: map['competitionId'] as String,
      competitionTitle: map['competitionTitle'] as String,
      title: map['title'] as String,
      startsAt: DateTime.parse(map['startsAt'] as String),
    );
  }).toList();
});

class CalendarEvent {
  const CalendarEvent({
    required this.competitionId,
    required this.competitionTitle,
    required this.title,
    required this.startsAt,
  });
  final String competitionId;
  final String competitionTitle;
  final String title;
  final DateTime startsAt;
}

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(calendarEventsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário de concursos')),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(calendarEventsProvider),
            child: const Text('Não foi possível carregar as datas. Tentar novamente'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ainda não há eventos oficiais cadastrados para os próximos 90 dias.'),
              ))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(calendarEventsProvider);
                  await ref.read(calendarEventsProvider.future);
                },
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final event = items[index];
                    return ListTile(
                      leading: const Icon(Icons.event),
                      title: Text(event.title),
                      subtitle: Text(
                        '${event.competitionTitle}\n${DateFormat('dd/MM/yyyy HH:mm').format(event.startsAt.toLocal())}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/competitions/${event.competitionId}'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

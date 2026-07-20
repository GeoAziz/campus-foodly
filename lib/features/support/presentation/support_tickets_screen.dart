import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../core/routes.dart';
import '../../../data/providers/auth_provider.dart';

class SupportTicket {
  final String id;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'];
    return SupportTicket(
      id: doc.id,
      subject: data['subject'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.now(),
    );
  }
}

final _supportTicketsProvider = StreamProvider<List<SupportTicket>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('supportTickets')
      .where('userId', isEqualTo: user.id)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SupportTicket.fromFirestore(doc))
          .toList(growable: false));
});

class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(_supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Support Tickets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.supportTicketNew),
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: ticketsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (tickets) {
          if (tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No support tickets yet.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to create one.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                defaultPadding, defaultPadding, defaultPadding, 80),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              final isOpen = ticket.status == 'open';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    isOpen
                        ? Icons.radio_button_on_rounded
                        : Icons.check_circle_rounded,
                    color: isOpen ? Colors.orange : Colors.green,
                  ),
                  title: Text(
                    ticket.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    ticket.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDate(ticket.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

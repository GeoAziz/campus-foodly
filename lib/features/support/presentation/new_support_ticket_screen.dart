import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../data/providers/auth_provider.dart';

class NewSupportTicketScreen extends ConsumerStatefulWidget {
  const NewSupportTicketScreen({super.key});

  @override
  ConsumerState<NewSupportTicketScreen> createState() =>
      _NewSupportTicketScreenState();
}

class _NewSupportTicketScreenState
    extends ConsumerState<NewSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'Order Issue';
  bool _submitting = false;

  static const _categories = [
    'Order Issue',
    'Payment Issue',
    'Delivery Issue',
    'Account Issue',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null) throw StateError('Not authenticated');

      await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': user.id,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _category,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support ticket submitted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Support Ticket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _categories
                    .map((cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              Text('Subject', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                maxLength: 100,
                decoration: const InputDecoration(
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Subject is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text('Message', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Describe your issue in detail',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 20) {
                    return 'Please provide at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: defaultPadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

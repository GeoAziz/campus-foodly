import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/order_provider.dart';

class ReviewOrderScreen extends ConsumerStatefulWidget {
  const ReviewOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends ConsumerState<ReviewOrderScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(String restaurantId) async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null) throw StateError('Not authenticated');

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('reviews')
          .add({
        'orderId': widget.orderId,
        'userId': user.id,
        'rating': _rating,
        'comment': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to submit review. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Your Order')),
      body: FutureBuilder(
        future: orderAsync.fetchOrderById(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }

          if (_submitted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 72),
                  const SizedBox(height: 16),
                  Text('Thank you for your review!',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How was your experience?',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Order from ${order.restaurantId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: defaultPadding),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(order.restaurantId),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Review'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

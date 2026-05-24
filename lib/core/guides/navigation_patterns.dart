/// Navigation Pattern Guide for Campus Foodly
///
/// This document standardizes when to use modal sheets vs full screens
/// for consistent UX and maintainability.

/// Use MODAL SHEET (showModalBottomSheet or showDialog) when:
/// - Content is temporary/transient (quick action, confirmation, selection)
/// - Content is secondary/optional (filters, preferences, details)
/// - Content should NOT be in browser history/deep link
/// - User should be able to dismiss easily (swipe down, tap outside)
/// - Content height is less than 80% of screen
///
/// Examples:
/// - Add to cart dialog
/// - Select payment method
/// - Filter restaurants
/// - Confirmation dialogs
/// - Share menu items
/// - Report issue form

/// Use FULL SCREEN when:
/// - Content is primary/essential (main workflow)
/// - Content has significant height/complexity
/// - Content should be in browser history/deep link capable
/// - Multiple steps/navigation within the screen
/// - User should use back button to dismiss
/// - Content height is more than 80% of screen
///
/// Examples:
/// - Restaurant details screen
/// - Restaurant menu/categories
/// - Cart/checkout flow
/// - Order history
/// - Profile edit
/// - Search results

/// Navigation Implementation Patterns:

class NavigationPatterns {
  /// Pattern 1: Modal Bottom Sheet for simple selection
  /// ```dart
  /// showModalBottomSheet<T>(
  ///   context: context,
  ///   builder: (context) => Column(
  ///     mainAxisSize: MainAxisSize.min,
  ///     children: [
  ///       ListTile(
  ///         title: Text('Option 1'),
  ///         onTap: () => Navigator.pop(context, option1),
  ///       ),
  ///     ],
  ///   ),
  /// );
  /// ```

  /// Pattern 2: Dialog for confirmations
  /// ```dart
  /// showDialog(
  ///   context: context,
  ///   builder: (context) => AlertDialog(
  ///     title: Text('Confirm'),
  ///     content: Text('Are you sure?'),
  ///     actions: [
  ///       TextButton(onPressed: ..., child: Text('Cancel')),
  ///       ElevatedButton(onPressed: ..., child: Text('Confirm')),
  ///     ],
  ///   ),
  /// );
  /// ```

  /// Pattern 3: Full screen via GoRouter
  /// ```dart
  /// GoRouter:
  ///   routes: [
  ///     GoRoute(
  ///       path: '/restaurant/:id',
  ///       builder: (context, state) => RestaurantDetailsScreen(
  ///         restaurantId: state.pathParameters['id']!,
  ///       ),
  ///     ),
  ///   ]
  /// ```

  /// Pattern 4: Named modal for complex selection (Modal with appbar)
  /// ```dart
  /// showModalBottomSheet(
  ///   context: context,
  ///   isScrollControlled: true,
  ///   builder: (context) => DraggableScrollableSheet(
  ///     expand: false,
  ///     builder: (context, controller) => Column(
  ///       children: [
  ///         Padding(
  ///           padding: EdgeInsets.all(16),
  ///           child: Text('Select Payment Method',
  ///             style: Theme.of(context).textTheme.titleLarge,
  ///           ),
  ///         ),
  ///         // content
  ///       ],
  ///     ),
  ///   ),
  /// );
  /// ```
}

/// Current Navigation Usage in Campus Foodly:

/// MODALS:
/// - Add to Cart → Modal with quantity/special instructions
/// - Order Confirmation → Alert dialog
/// - Filter Restaurants → Bottom sheet
/// - Sort Options → Bottom sheet
/// - Report Issue → Bottom sheet

/// FULL SCREENS:
/// - Restaurant Details → Full screen (GoRouter)
/// - Menu/Categories → Full screen (tabs within details)
/// - Cart/Checkout → Full screen flow
/// - Order History → Full screen list
/// - Profile Edit → Full screen form
/// - Order Tracking → Full screen with map
/// - Search Results → Full screen with filters

/// CONSISTENCY CHECKLIST:
/// ✓ Simple confirmations → AlertDialog
/// ✓ Multiple options < 5 → showModalBottomSheet
/// ✓ Multiple options > 5 → Full screen search/filter
/// ✓ Forms → Full screen if > 3 fields
/// ✓ Lists > 10 items → Full screen with pagination
/// ✓ Real-time updates needed → Full screen
/// ✓ Back button expected → Full screen
/// ✓ Dismiss by swiping → Modal

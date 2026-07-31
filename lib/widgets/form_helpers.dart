import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

/// Every stage screen's submit button goes through this, so the pattern
/// stays identical everywhere: disable the button and show a spinner while
/// the request is in flight, then surface the backend's actual message on
/// failure instead of silently doing nothing.
///
/// The two error cases that matter most here are the ones CaseService's
/// assertTransition produces server-side:
/// - 409 Conflict — the case has already moved to a different stage
///   (someone else acted on it, or this screen's data is stale).
/// - 403 Forbidden — the logged-in role no longer owns this action.
/// Both come back with a human-readable message from the backend, so this
/// just displays it rather than re-deriving anything client-side.
mixin SubmitStateMixin<T extends StatefulWidget> on State<T> {
  bool submitting = false;

  Future<void> submitAction(
    Future<void> Function() action, {
    required String successMessage,
    bool popOnSuccess = true,
  }) {
    return submitActionWithResult<void>(
      action,
      successMessage: (_) => successMessage,
      popOnSuccess: popOnSuccess,
    );
  }

  Future<void> submitActionWithResult<R>(
    Future<R> Function() action, {
    required String Function(R result) successMessage,
    bool popOnSuccess = true,
  }) async {
    setState(() => submitting = true);
    try {
      final result = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage(result))));
      if (popOnSuccess) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: (e.isForbidden || e.isConflict) ? AppTheme.danger : null,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryDark,
          fontSize: 15,
        ),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const DateField({super.key, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Select date' : fmt.format(value!),
          style: TextStyle(color: value == null ? Colors.grey : Colors.black87),
        ),
      ),
    );
  }
}

/// Read-only label/value row for detail & summary screens (Purchase Invoice
/// auto-pulled data, timeline, receipts, etc).
class LabeledValue extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const LabeledValue({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
              fontSize: emphasize ? 16 : 14,
              color: emphasize ? AppTheme.primaryDark : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

String? requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  return null;
}

String? numericValidator(String? value) {
  if (value == null || value.trim().isEmpty) return 'Required';
  if (double.tryParse(value.trim()) == null) return 'Must be a number';
  return null;
}

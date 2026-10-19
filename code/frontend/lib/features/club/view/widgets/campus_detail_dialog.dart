import 'package:flutter/material.dart';
import 'package:uniconnect/features/authentication/model/auth_failure.dart';

/// Re-fetches details so hidden or removed publications are not opened from cache.
class CampusDetailDialog<T> extends StatefulWidget {
  const CampusDetailDialog({
    required this.load,
    required this.builder,
    super.key,
  });
  final Future<T> Function() load;
  final Widget Function(T) builder;

  @override
  State<CampusDetailDialog<T>> createState() => _CampusDetailDialogState<T>();
}

class _CampusDetailDialogState<T> extends State<CampusDetailDialog<T>> {
  late Future<T> _request = widget.load();

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Theme.of(context).colorScheme.surface,
    title: const Text('Campus details'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: FutureBuilder<T>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error is AuthFailure
                        ? error.message
                        : 'Unable to load details.',
                  ),
                  TextButton(
                    onPressed: () => setState(() => _request = widget.load()),
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return widget.builder(snapshot.data as T);
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  );
}

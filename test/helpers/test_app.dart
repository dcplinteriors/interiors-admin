import 'package:dcpl_admin/core/core.dart';
import 'package:flutter/material.dart';

/// Wraps [home] in a MaterialApp with the l10n delegates and the global snackbar
/// key, so views, dialogs, and snackbars render the same way as in the real app.
Widget testApp(Widget home) => MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

/// A Scaffold with a button that opens [builder] as a dialog — lets dialog tests
/// mount the dialog through `showDialog`, exactly as the app does.
Widget dialogHost(WidgetBuilder builder) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(context: context, builder: builder),
            child: const Text('__open__'),
          ),
        ),
      ),
    );

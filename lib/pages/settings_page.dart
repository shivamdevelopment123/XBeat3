import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xbeat3/themes/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('S E T T I N G S'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.all(14),
        margin: EdgeInsets.all(12),
        child: Row(
          children: [
            Text("Dark Mode", style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary, fontSize: 18, fontWeight: FontWeight.bold)),

            Spacer(),

            CupertinoSwitch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false)
                  .toggleTheme(),
            ),
          ],
        ),
      )
    );
  }
}

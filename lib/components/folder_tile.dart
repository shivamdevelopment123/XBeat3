import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/folder_provider.dart';

class FolderTile extends StatelessWidget {
  final String path;
  const FolderTile({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(path.split('/').last),
      onTap: () =>
          context.read<FolderProvider>().openFolder(path),
    );
  }
}

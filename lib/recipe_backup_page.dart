import 'dart:io';
import 'package:flutter/material.dart';
import 'package:recipe/database_helper.dart';
import 'package:file_picker/file_picker.dart';

class RecipeBackupPage extends StatefulWidget {
  final Function reload;
  const RecipeBackupPage({super.key, required this.reload});

  @override
  State<RecipeBackupPage> createState() => _RecipeBackupPageState();
}

class _RecipeBackupPageState extends State<RecipeBackupPage> {
  String json = "[]";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Backups"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final db = DatabaseHelper.instance;
                json = await db.generateBackup();
                debugPrint(json);
                File file = await File(
                        "/storage/emulated/0/Download/recipe_backup_${DateTime.now().toUtc().millisecondsSinceEpoch}.json")
                    .create();
                file.writeAsString(json);
              },
              child: const Text("Backup speichern"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final db = DatabaseHelper.instance;
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                    initialDirectory: "/storage/emulated/0/Download",
                    type: FileType.custom,
                    allowedExtensions: ["json"]);

                if (result != null) {
                  File file = File(result.files.single.path!);
                  await db.restoreBackup(file.readAsStringSync());
                  widget.reload();
                }
              },
              child: const Text("Backup wiederherstellen"),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final db = DatabaseHelper.instance;
                await db.clearAllTables();
                widget.reload();
              },
              child: const Text("Daten löschen"),
            ),
          ],
        ),
      ),
    );
  }
}

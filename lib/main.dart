import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:recipe/database_helper.dart';
import 'package:recipe/recipe_add_page.dart';
import 'package:recipe/recipe_backup_page.dart';
import 'package:recipe/recipe_edit_page.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecipeMainPage(),
    );
  }
}

class RecipeMainPage extends StatefulWidget {
  const RecipeMainPage({super.key});

  @override
  State<RecipeMainPage> createState() => _RecipeMainPageState();
}

class _RecipeMainPageState extends State<RecipeMainPage> {
  var _categoryOn = false;
  String _selectedCategory = "Mamis Rezepte";
  var _selectedCategoryIndex = 0;
  final _categoryItems = [
    'Mamis Rezepte',
    'Fleisch',
    'Apéro',
    'Fisch',
    'Dessert',
    'Kuchen',
    'Vegi'
  ];

  var _listEmpty = false;

  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _currentRecipeData = [];

  // Initialize a list to hold the recipes from the database
  List<Map<String, dynamic>> _recipes = [];

  List<Map<String, dynamic>> filteredRecipes = [];

  late MultiImageProvider multiImageProvider;

  @override
  void initState() {
    super.initState();
    // Retrieve the recipes when the app starts
    _query();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => RecipeBackupPage(
                    reload: _query,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.import_export),
          )
        ],
        title: Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(5)),
          child: Center(
            child: TextField(
              onChanged: (value) => _runFilter(value),
              controller: searchController,
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _categoryOn = !_categoryOn;
                        _runFilter(searchController.text);
                      });
                    },
                    icon: const Icon(Icons.filter_alt),
                  ),
                  hintText: 'Suchen...',
                  border: InputBorder.none),
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_categoryOn)
            Container(
              padding: const EdgeInsets.all(2.0),
              width: double.infinity,
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (BuildContext context, int index) {
                  return GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedCategoryIndex == index
                              ? Colors.blue
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                          _selectedCategory = _categoryItems[index];
                          _runFilter(searchController.text);
                        },
                        child: Text(_categoryItems[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredRecipes.length,
              itemBuilder: (BuildContext context, int index) => ListTile(
                onTap: () {
                  if (filteredRecipes[index][DatabaseHelper.columnImagePath] !=
                      "") {
                    List<String> tmp = filteredRecipes[index]
                            [DatabaseHelper.columnImagePath]
                        .split(";");
                    List<ImageProvider> imageProviders = [];
                    for (final path in tmp) {
                      if (File(path).existsSync()) {
                        imageProviders.add(Image.file(File(path)).image);
                      }
                    }
                    if (imageProviders.isNotEmpty) {
                      multiImageProvider = MultiImageProvider(imageProviders);
                      showImageViewerPager(context, multiImageProvider,
                          doubleTapZoomable: true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.red,
                          content: Text('Kein Bild vorhanden.'),
                        ),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Kein Bild vorhanden.'),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  _initRecipeData(
                    filteredRecipes[index][DatabaseHelper.columnId],
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => RecipeEditPage(
                        reload: _query,
                        data: _currentRecipeData[0],
                      ),
                    ),
                  );
                },
                key: ValueKey(filteredRecipes[index][DatabaseHelper.columnId]),
                title: Text(filteredRecipes[index][DatabaseHelper.columnTitle]),
                subtitle: Text(
                    filteredRecipes[index][DatabaseHelper.columnDescription]),
              ),
            ),
          ),
          if (_listEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "Keine Ergebnisse",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => AddRecipePage(reload: _query),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _query() async {
    var db = DatabaseHelper.instance;
    final allRows = await db.queryAllRows();
    _recipes = allRows;
    setState(() {
      filteredRecipes = _recipes;
    });
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _recipes;
    } else {
      results = _recipes
          .where(((element) => (element[DatabaseHelper.columnTitle] +
                  element[DatabaseHelper.columnSearchKeywords])
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase())))
          .toList();
    }
    if (_categoryOn) {
      results = results
          .where((element) =>
              element[DatabaseHelper.columnCategory] == _selectedCategory)
          .toList();
    }

    setState(() {
      filteredRecipes = results;
      if (results.isEmpty) {
        _listEmpty = true;
      } else {
        _listEmpty = false;
      }
    });
  }

  void _initRecipeData(int id) async {
    var db = DatabaseHelper.instance;
    _currentRecipeData = await db.getById(id);
    //debugPrint(_currentRecipeData.toString());
  }
}

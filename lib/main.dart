import 'dart:convert';

import 'package:answer/niam.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class Todo {
  final String title;
  final DateTime? startTime;
  final DateTime? finishingTime;
  bool isDone;
  Color backgroundColor;

  Todo({
    required this.title,
    this.startTime,
    this.finishingTime,
    this.isDone = false,
    this.backgroundColor = Colors.white,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime?.toIso8601String(),
      'finishingTime': finishingTime?.toIso8601String(),
      'isDone': isDone,
      'backgroundColor': backgroundColor.value,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      startTime:
          json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      finishingTime: json['finishingTime'] != null
          ? DateTime.parse(json['finishingTime'])
          : null,
      isDone: json['isDone'],
      backgroundColor: Color(json['backgroundColor']),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Todo> _todos = [];
  late TextEditingController _searchController;
  late List<Todo> _originalTodos;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _originalTodos = List.from(_todos);
    _loadTodoList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? todoListJson = prefs.getString('todoList');
    if (todoListJson != null) {
      List<dynamic> todoList = jsonDecode(todoListJson);
      setState(() {
        _todos.clear();
        _todos.addAll(todoList.map((todo) => Todo.fromJson(todo)).toList());
        _originalTodos = List.from(_todos);
      });
    }
  }

  void _saveTodoList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String todoListJson =
        jsonEncode(_todos.map((todo) => todo.toJson()).toList());
    prefs.setString('todoList', todoListJson);
  }

  void _addTodo() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _titleController = TextEditingController();
        DateTime? _startTime;
        DateTime? _finishingTime;
        Color _selectedColor = Colors.white;

        return AlertDialog(
          title: Text('Add Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'Enter your todo'),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleButton(
                    Colors.yellow,
                    'Middle',
                    () {
                      setState(() {
                        _selectedColor = Colors.yellow;
                      });
                    },
                  ),
                  _buildCircleButton(
                    Colors.green,
                    'Easy',
                    () {
                      setState(() {
                        _selectedColor = Colors.green;
                      });
                    },
                  ),
                  _buildCircleButton(
                    Colors.red,
                    'Hard',
                    () {
                      setState(() {
                        _selectedColor = Colors.red;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _startTime = picked;
                        });
                      }
                    },
                    child: Text(
                        _startTime != null ? '$_startTime' : 'Add Start Time'),
                  ),
                  SizedBox(width: 20),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _finishingTime = picked;
                        });
                      }
                    },
                    child: Text(_finishingTime != null
                        ? '$_finishingTime'
                        : 'Add Finishing Time'),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    _todos.add(Todo(
                      title: _titleController.text,
                      startTime: _startTime,
                      finishingTime: _finishingTime,
                      backgroundColor: _selectedColor,
                    ));
                    _originalTodos = List.from(_todos);
                    _saveTodoList();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Add'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCircleButton(Color color, String text, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(Icons.circle),
          color: color,
        ),
        Text(text),
      ],
    );
  }

  void _toggleTodoStatus(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
      _saveTodoList();
    });
  }

  void _deleteTodo(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text(' After complete the next task'),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _todos.removeAt(index);
                  _originalTodos = List.from(_todos);
                  _saveTodoList();
                  Navigator.pop(context); // Close the dialog
                });
                // Show a snackbar indicating the deletion
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Todo deleted'),
                  duration: Duration(seconds: 1),
                ));
                // Proceed to the next exercise
                // You can add your logic here
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _editTodo(int index) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController _titleController =
            TextEditingController(text: _todos[index].title);
        DateTime? _startTime = _todos[index].startTime;
        DateTime? _finishingTime = _todos[index].finishingTime;
        Color _selectedColor = _todos[index].backgroundColor;

        return AlertDialog(
          title: Text('Edit Todo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'Enter your todo'),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleButton(
                    Colors.yellow,
                    'Middle',
                    () {
                      setState(() {
                        _selectedColor = Colors.yellow;
                      });
                    },
                  ),
                  _buildCircleButton(
                    Colors.green,
                    'Easy',
                    () {
                      setState(() {
                        _selectedColor = Colors.green;
                      });
                    },
                  ),
                  _buildCircleButton(
                    Colors.red,
                    'Hard',
                    () {
                      setState(() {
                        _selectedColor = Colors.red;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startTime ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _startTime = picked;
                        });
                      }
                    },
                    child: Text(
                        _startTime != null ? '$_startTime' : 'Add Start Time'),
                  ),
                  SizedBox(width: 20),
                  TextButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _finishingTime ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _finishingTime = picked;
                        });
                      }
                    },
                    child: Text(_finishingTime != null
                        ? '$_finishingTime'
                        : 'Add Finishing Time'),
                  ),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  setState(() {
                    _todos[index] = Todo(
                      title: _titleController.text,
                      startTime: _startTime,
                      finishingTime: _finishingTime,
                      backgroundColor: _selectedColor,
                    );
                    _originalTodos = List.from(_todos);
                    _saveTodoList();
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _filterTodos(String query) {
    setState(() {
      _todos.clear();
      _todos.addAll(_originalTodos.where(
          (todo) => todo.title.toLowerCase().contains(query.toLowerCase())));
    });
  }

  List<Widget> _buildFilteredTodoList(Color color) {
    List<Widget> filteredTodos = [];
    for (int i = 0; i < _todos.length; i++) {
      if (_todos[i].backgroundColor == color) {
        filteredTodos.add(
          Card(
            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            color: _todos[i].backgroundColor,
            child: ListTile(
              title: Text(
                _todos[i].title,
                style: TextStyle(
                  decoration: _todos[i].isDone
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_todos[i].startTime != null)
                    Text('Start Time: ${_todos[i].startTime}'),
                  if (_todos[i].finishingTime != null)
                    Text('Finishing Time: ${_todos[i].finishingTime}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editTodo(i),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTodo(i),
                  ),
                ],
              ),
              onTap: () => _toggleTodoStatus(i),
            ),
          ),
        );
      }
    }
    return filteredTodos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Todo List',
              style: TextStyle(fontSize: 20),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => NiamTrad()));
              },
              icon: Icon(
                Icons.arrow_circle_right_outlined,
                size: 30,
              ),
            )
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search todos...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterTodos,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_todos
                        .any((todo) => todo.backgroundColor == Colors.red))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Very Hard Exercises',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ..._buildFilteredTodoList(Colors.red),
                    if (_todos
                        .any((todo) => todo.backgroundColor == Colors.yellow))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Middle Exercises',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ..._buildFilteredTodoList(Colors.yellow),
                    if (_todos
                        .any((todo) => todo.backgroundColor == Colors.green))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Easy Exercises',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ..._buildFilteredTodoList(Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: Icon(Icons.add),
      ),
    );
  }
}

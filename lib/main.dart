import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

enum TaskPriority { low, medium, high }

/// Represents a single to-do task with enhanced features
class Task {
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  bool isCompleted;

  Task({
    required this.description,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
  });

  Task copyWith({
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return Task(
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ToDoListModel extends ChangeNotifier {
  final List<Task> _tasks;
  TaskPriority? _filterPriority;
  bool _showCompleted = true;

  ToDoListModel()
      : _tasks = [
          Task(
            description: 'Buy groceries',
            dueDate: DateTime.now().add(const Duration(days: 1)),
            priority: TaskPriority.high,
          ),
          Task(
            description: 'Finish project report',
            dueDate: DateTime.now().add(const Duration(days: 3)),
            priority: TaskPriority.high,
          ),
          Task(
            description: 'Call mom',
            dueDate: DateTime.now(),
            priority: TaskPriority.medium,
            isCompleted: true,
          ),
          Task(
            description: 'Go for a run',
            priority: TaskPriority.low,
          ),
          Task(
            description: 'Read a book',
            priority: TaskPriority.low,
          ),
        ];

  List<Task> get filteredTasks {
    return _tasks.where((task) {
      if (!_showCompleted && task.isCompleted) return false;
      if (_filterPriority != null) {
        return task.priority == _filterPriority;
      }
      return true;
    }).toList();
  }

  void toggleShowCompleted() {
    _showCompleted = !_showCompleted;
    notifyListeners();
  }

  void setFilterPriority(TaskPriority? priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void addTask(String description, {DateTime? dueDate, TaskPriority? priority}) {
    if (description.trim().isEmpty) return;
    _tasks.add(Task(
      description: description,
      dueDate: dueDate,
      priority: priority ?? TaskPriority.medium,
    ));
    notifyListeners();
  }

  void editTask(Task oldTask, String newDescription, {DateTime? newDueDate, TaskPriority? newPriority}) {
    final int index = _tasks.indexOf(oldTask);
    if (index != -1) {
      _tasks[index] = oldTask.copyWith(
        description: newDescription,
        dueDate: newDueDate,
        priority: newPriority,
      );
      notifyListeners();
    }
  }

  void toggleTaskCompletion(Task task) {
    final int index = _tasks.indexOf(task);
    if (index != -1) {
      _tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      notifyListeners();
    }
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notifyListeners();
  }

  void reinsertTask(int index, Task task) {
    if (index >= 0 && index <= _tasks.length) {
      _tasks.insert(index, task);
    } else {
      _tasks.add(task);
    }
    notifyListeners();
  }

  // Statistics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  double get completionRate => totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ToDoListModel>(
      create: (context) => ToDoListModel(),
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'To-Do List',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.blue,
            brightness: Brightness.dark,
          ),
          home: const ToDoListPage(),
        );
      },
    );
  }
}

class ToDoListPage extends StatefulWidget {
  const ToDoListPage({super.key});

  @override
  State<ToDoListPage> createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDate;
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red.shade200;
      case TaskPriority.medium:
        return Colors.orange.shade200;
      case TaskPriority.low:
        return Colors.green.shade200;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    _taskController.clear();
    _selectedDate = null;
    _selectedPriority = TaskPriority.medium;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _taskController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter task description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(
                        _selectedDate == null
                            ? 'No date selected'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getPriorityText(priority)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (TaskPriority? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                Consumer<ToDoListModel>(
                  builder: (context, todoListModel, child) {
                    return FilledButton(
                      onPressed: _taskController.text.trim().isEmpty
                          ? null
                          : () {
                              todoListModel.addTask(
                                _taskController.text,
                                dueDate: _selectedDate,
                                priority: _selectedPriority,
                              );
                              Navigator.of(dialogContext).pop();
                            },
                      child: const Text('Add'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditTaskDialog(BuildContext context, Task task) async {
    _taskController.text = task.description;
    _selectedDate = task.dueDate;
    _selectedPriority = task.priority;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _taskController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter task description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Due Date'),
                      subtitle: Text(
                        _selectedDate == null
                            ? 'No date selected'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getPriorityText(priority)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (TaskPriority? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPriority = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                Consumer<ToDoListModel>(
                  builder: (context, todoListModel, child) {
                    return FilledButton(
                      onPressed: _taskController.text.trim().isEmpty
                          ? null
                          : () {
                              todoListModel.editTask(
                                task,
                                _taskController.text,
                                newDueDate: _selectedDate,
                                newPriority: _selectedPriority,
                              );
                              Navigator.of(dialogContext).pop();
                            },
                      child: const Text('Save'),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do List'),
        actions: [
          Consumer<ToDoListModel>(
            builder: (context, model, child) {
              return IconButton(
                icon: Icon(
                  model._showCompleted ? Icons.check_circle : Icons.check_circle_outline,
                ),
                onPressed: model.toggleShowCompleted,
                tooltip: model._showCompleted ? 'Hide completed' : 'Show completed',
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter tasks',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Priorities'),
              ),
              PopupMenuItem(
                value: TaskPriority.high,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(TaskPriority.high),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('High Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TaskPriority.medium,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(TaskPriority.medium),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Medium Priority'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: TaskPriority.low,
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(TaskPriority.low),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Low Priority'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              final model = context.read<ToDoListModel>();
              if (value == 'all') {
                model.setFilterPriority(null);
              } else if (value is TaskPriority) {
                model.setFilterPriority(value);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<ToDoListModel>(
            builder: (context, model, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${model.totalTasks}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Text('Total Tasks'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${model.completedTasks}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Text('Completed'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${model.completionRate.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const Text('Completion'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: Consumer<ToDoListModel>(
              builder: (BuildContext context, ToDoListModel todoListModel, Widget? child) {
                final tasks = todoListModel.filteredTasks;
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tasks yet! Add one using the + button.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Task task = tasks[index];
                    return Dismissible(
                      key: ValueKey<Task>(task),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (DismissDirection direction) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Task "${task.description}" deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                todoListModel.reinsertTask(index, task);
                              },
                            ),
                          ),
                        );
                        todoListModel.removeTask(task);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            task.description,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: task.isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: task.dueDate != null
                              ? Text(
                                  'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                                  style: TextStyle(
                                    color: task.dueDate!.isBefore(DateTime.now())
                                        ? Colors.red
                                        : null,
                                  ),
                                )
                              : null,
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                todoListModel.toggleTaskCompletion(task);
                              }
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(task.priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditTaskDialog(context, task),
                              ),
                            ],
                          ),
                          onTap: () {
                            todoListModel.toggleTaskCompletion(task);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        tooltip: 'Add New Task',
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> data = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final url = Uri.parse("https://jsonplaceholder.typicode.com/posts");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (error) {
      print("Error fetching data: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateTitle(int id, String newTitle) async {
    final url = Uri.parse("https://jsonplaceholder.typicode.com/posts/$id");

    try {
      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "title": newTitle,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = data.indexWhere((post) => post['id'] == id);
          if (index != -1) {
            data[index]['title'] = newTitle; // Update title locally
          }
        });
      } else {
        throw Exception("Failed to update title");
      }
    } catch (error) {
      print("Error updating title: $error");
    }
  }

  Future<void> deletePost(int id) async {
    final url = Uri.parse("https://jsonplaceholder.typicode.com/posts/$id");

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        setState(() {
          data.removeWhere((post) => post['id'] == id); // Remove locally
        });
      } else {
        throw Exception("Failed to delete post");
      }
    } catch (error) {
      print("Error deleting post: $error");
    }
  }

  Future<void> addPost(String title, String body) async {
    final url = Uri.parse("https://jsonplaceholder.typicode.com/posts");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "userId": 1, // Assuming userId is always 1 (based on the API's format)
          "title": title,
          "body": body,

        }),
      );

      if (response.statusCode == 201) {
        final newPost = json.decode(response.body);
        print(newPost);
        setState(() {
          data.add(newPost); // Add new post locally
        });
      } else {
        throw Exception("Failed to add post");
      }
    } catch (error) {
      print("Error adding post: $error");
    }
  }

  // Show a dialog to create a new post
  void showAddPostDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(labelText: 'Body'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    bodyController.text.isNotEmpty) {
                  addPost(titleController.text,
                      bodyController.text);
                }
                Navigator.pop(context);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Show a dialog to edit the title
  void showEditTitleDialog(int id, String currentTitle) {
    final titleController = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Title'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                updateTitle(id, titleController.text);
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              icon: Icon(
                Icons.add,
                size: 30,
                color: Colors.white,
              ),
              color: Colors.white,
              onPressed: () {
                showAddPostDialog();
              },
            ),
          ),
        ],
        backgroundColor: Colors.red,
        title: Text(
          "${widget.title}",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Row(
                    children: [
                      Text("${data[index]['id']}. "),
                      Expanded(
                        child: Text(
                          data[index]['title'],
                          overflow: TextOverflow
                              .ellipsis, // Adds ellipsis for long text
                          maxLines: 1,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data[index]['body']),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          deletePost(data[index]['id']);
                        },
                        child: Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Divider(
                        color: Colors.grey,
                        thickness: 1,
                      ),
                    ],
                  ),
                  onTap: () {
                    showEditTitleDialog(
                        data[index]['id'], data[index]['title']);
                  },
                );
              },
            ),
    );
  }
}

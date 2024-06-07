import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BodyPage extends StatefulWidget {
  const BodyPage({super.key});

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  final List<Map<String, String>> contacts = [];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedContacts = prefs.getStringList('contacts');
    if (savedContacts != null) {
      setState(() {
        contacts.clear();
        for (var contact in savedContacts) {
          final splitContact = contact.split('|');
          contacts.add({'name': splitContact[0], 'number': splitContact[1]});
        }
      });
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> contactStrings = contacts.map((contact) {
      return '${contact['name']}|${contact['number']}';
    }).toList();
    await prefs.setStringList('contacts', contactStrings);
  }

  void addContact() async {
    if (nameController.text.isNotEmpty && numberController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      await Future.delayed(Duration(seconds: 1)); // Simulate a network call

      setState(() {
        contacts.add({
          'name': nameController.text,
          'number': numberController.text,
        });
        isLoading = false;
      });

      await _saveContacts(); // Save contacts to shared preferences

      nameController.clear();
      numberController.clear();
    }
  }

  void deleteContact(int index) async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1)); // Simulate a network call

    setState(() {
      contacts.removeAt(index);
      isLoading = false;
    });

    await _saveContacts(); // Save contacts to shared preferences
  }

  void callContact(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $number')),
      );
    }
  }

  void showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Contact'),
          content: Text('Are you sure you want to delete this contact?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteContact(index);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: nameController,
                  textAlign: TextAlign.start,
                  decoration: const InputDecoration(
                    hintText: 'Enter Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 60,
              width: 400,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: numberController,
                  textAlign: TextAlign.start,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Enter Phone Number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              width: 300,
              child: ElevatedButton(
                onPressed: addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple, // Background color
                  foregroundColor: Colors.white, // Text color
                ),
                child: const Text('Add'),
              ),
            ),
            SizedBox(
              height: 500, // Adjusted height to fit ListView.builder properly
              child: isLoading
                  ? Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: ListView.builder(
                  itemCount: 5, // Simulated item count for shimmer effect
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        width: double.infinity,
                        height: 60.0,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              )
                  : ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.person), // Person icon added here
                    title: Text(contacts[index]['name']!),
                    subtitle: Text(contacts[index]['number']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.call),
                          onPressed: () =>
                              callContact(contacts[index]['number']!),
                        ),
                      ],
                    ),
                    onLongPress: () => showDeleteDialog(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

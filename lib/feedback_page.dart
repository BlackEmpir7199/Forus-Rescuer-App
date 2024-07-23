import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'database_helper.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  String _location = '';
  String _event = '';
  String _issues = '';
  String _additionalInfo = '';
  final _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadFeedbacks();
  }

  Future<void> _getCurrentLocation() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();

    setState(() {
      _location = '${_locationData.latitude}, ${_locationData.longitude}';
    });
  }

  Future<void> _loadFeedbacks() async {
    final feedbacks = await _databaseHelper.getFeedbacks();
    setState(() {
      _feedbacks = feedbacks;
    });
  }

  void _submitFeedback() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final feedback = {
        'location': _location,
        'event': _event,
        'issues': _issues,
        'additional_info': _additionalInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _databaseHelper.insertFeedback(feedback);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback submitted successfully')),
      );
      _loadFeedbacks();
      Navigator.pop(context);
    }
  }

  void _showFeedbackForm({Map<String, dynamic>? feedback}) {
    if (feedback != null) {
      _location = feedback['location'];
      _event = feedback['event'];
      _issues = feedback['issues'];
      _additionalInfo = feedback['additional_info'];
    } else {
      _getCurrentLocation();
      _event = '';
      _issues = '';
      _additionalInfo = '';
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Location'),
                  initialValue: _location,
                  readOnly: true,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Event'),
                  initialValue: _event,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter an event' : null,
                  onSaved: (value) => _event = value ?? '',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Issues'),
                  initialValue: _issues,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter any issues' : null,
                  onSaved: (value) => _issues = value ?? '',
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Additional Info'),
                  initialValue: _additionalInfo,
                  onSaved: (value) => _additionalInfo = value ?? '',
                ),
                SizedBox(height: 20),
                MaterialButton(
                  onPressed: feedback == null ? _submitFeedback : () => _updateFeedback(feedback['id']),
                  child: Text(feedback == null ? 'Submit Feedback' : 'Update Feedback', style: TextStyle(color: Colors.white)),
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateFeedback(int id) async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final feedback = {
        'location': _location,
        'event': _event,
        'issues': _issues,
        'additional_info': _additionalInfo,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await _databaseHelper.updateFeedback(id, feedback);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback updated successfully')),
      );
      _loadFeedbacks();
      Navigator.pop(context);
    }
  }

  void _deleteFeedback(int id) async {
    await _databaseHelper.deleteFeedback(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback deleted successfully')),
    );
    _loadFeedbacks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback'),
        actions: [
          IconButton(
            onPressed: () => _showFeedbackForm(),
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: _feedbacks.isEmpty
          ? Center(child: Text('No feedbacks available'))
          : ListView.builder(
              itemCount: _feedbacks.length,
              itemBuilder: (context, index) {
                final feedback = _feedbacks[index];
                return ListTile(
                  title: Text(feedback['event']),
                  subtitle: Text(feedback['location']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showFeedbackForm(feedback: feedback),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteFeedback(feedback['id']),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

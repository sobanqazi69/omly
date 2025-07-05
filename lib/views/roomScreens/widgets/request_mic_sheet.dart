import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RequestMicSheet extends StatelessWidget {
  final VoidCallback onRequestMic;

  const RequestMicSheet({Key? key, required this.onRequestMic}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Request Microphone Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Would you like to request microphone access from the room admin?',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  onRequestMic();
                  Get.back();
                },
                child: Text('Request Access'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
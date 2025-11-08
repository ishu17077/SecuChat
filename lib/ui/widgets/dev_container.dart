import 'package:flutter/material.dart';

class DevBatch extends StatelessWidget {
  const DevBatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10.0, vertical: 6.0), // Padding inside the container
      decoration: BoxDecoration(
        color: Colors.deepPurple, // Background color
        borderRadius: BorderRadius.circular(20.0), // Rounded corners
        boxShadow: [
          // A subtle shadow for depth
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            spreadRadius: 3,
            blurRadius: 7,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
        border: Border.all(
          // A subtle border
          color: Colors.deepPurple.shade200,
          width: 1.5,
        ),
        gradient: const LinearGradient(
          // A gradient for a more modern look
          colors: [Colors.deepPurple, Colors.indigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Text(
        'DEV',
        style: TextStyle(
          color: Colors.white, // Text color
          fontSize: 12.0, // Font size
          fontWeight: FontWeight.bold, // Bold text
          letterSpacing: 3.0, // Space between letters
          fontFamily: 'RobotoMono', // A common dev-friendly font
        ),
      ),
    );
  }
}

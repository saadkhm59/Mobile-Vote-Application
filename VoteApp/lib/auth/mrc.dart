import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: ThankYouPage(),
  ));
}

class ThankYouPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
      
      ),
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.thumb_up,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Merci pour votre vote',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

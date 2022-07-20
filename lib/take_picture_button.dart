import 'package:flutter/material.dart';

class TakePictureButton extends StatefulWidget {
  final VoidCallback onTap;

  const TakePictureButton({Key? key, required this.onTap}) : super(key: key);

  @override
  State<TakePictureButton> createState() => _TakePictureButtonState();
}

class _TakePictureButtonState extends State<TakePictureButton> {
  bool isPressed = false;

  void onTapUp(TapUpDetails details) {
    setState(() => isPressed = false);
    widget.onTap();
  }

  void onTapDown(TapDownDetails details) {
    setState(() => isPressed = true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: onTapUp,
      onTapDown: onTapDown,
      child: Container(
        width: MediaQuery.of(context).size.width / 4.5,
        height: MediaQuery.of(context).size.width / 4.5,
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.pink, width: 2),
            borderRadius: BorderRadius.circular(100)),
        child: Container(
          decoration: BoxDecoration(
              color: isPressed ? Colors.pink.shade800 : Colors.pink,
              borderRadius: BorderRadius.circular(100)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class DialogActivityCreator extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  const DialogActivityCreator(
      {Key? key, required this.textController, required this.hintText})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      controller: textController,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        hintText: hintText,
      ),
    );
  }
}

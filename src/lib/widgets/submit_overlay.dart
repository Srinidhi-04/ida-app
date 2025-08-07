// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SubmitOverlay extends StatelessWidget {
  bool submitted;
  SubmitOverlay({super.key, required this.submitted});

  @override
  Widget build(BuildContext context) {
    return (submitted) ? Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      color: Color(0x99FFFFFF),
      child: LoadingAnimationWidget.threeArchedCircle(
        color: Theme.of(context).primaryColorLight,
        size: 100,
      ),
    ) : SizedBox.shrink();
  }
}

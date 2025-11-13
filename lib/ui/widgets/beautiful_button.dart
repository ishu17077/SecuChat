import 'package:flutter/material.dart';

class BeautifulButton extends StatefulWidget {
  final String? text;
  final Color? color;
  final Color? textColor;
  final String? imagePath;
  final double? spaceBetween;
  final double? heightImage;
  final double? widthFactor;
  final double? widthImage;
  final Future<void> Function()? onPressed;
  const BeautifulButton(
      {this.text,
      this.color,
      this.textColor,
      this.imagePath,
      this.spaceBetween,
      this.heightImage,
      this.widthFactor,
      this.widthImage,
      this.onPressed,
      super.key});

  @override
  State<BeautifulButton> createState() => _BeautifulButtonState();
}

class _BeautifulButtonState extends State<BeautifulButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: () async {
          if (widget.onPressed != null && !isLoading) {
            setState(() {
              isLoading = true;
            });
            await widget.onPressed!();
            setState(() {
              isLoading = false;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: widget.color,
          minimumSize: Size(
              MediaQuery.of(context).size.width *
                  0.80 *
                  (widget.widthFactor ?? 1.0),
              MediaQuery.of(context).size.height * 0.05),
          maximumSize: Size(
              MediaQuery.of(context).size.width *
                  0.80 *
                  (widget.widthFactor ?? 1.0),
              MediaQuery.of(context).size.height * 0.055),
        ),
        child: isLoading
            ? Center(heightFactor: 1.4, child: CircularProgressIndicator())
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  widget.imagePath != null
                      ? Image.asset(widget.imagePath!,
                          height: widget.heightImage ?? 38.0,
                          width: widget.widthImage ?? 38.0)
                      : const SizedBox(),
                  SizedBox(width: widget.spaceBetween ?? 5.0),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      widget.text ?? 'How about continuing with some brain ;D',
                      style: TextStyle(
                        color: widget.textColor,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
    ;
  }
}

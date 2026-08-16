import 'package:flutter/material.dart';

/// Detects whether [text] should render right-to-left based on its first
/// strongly-directional character (Hebrew/Arabic ranges), so Hebrew task
/// titles/descriptions align and read correctly instead of being forced
/// into the app's default LTR layout.
TextDirection detectTextDirection(String text) {
  for (final rune in text.runes) {
    final isRtl = (rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
        (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
        (rune >= 0x0750 && rune <= 0x077F); // Arabic Supplement
    if (isRtl) return TextDirection.rtl;
    final isLtr = (rune >= 0x0041 && rune <= 0x007A) || // basic Latin letters
        (rune >= 0x00C0 && rune <= 0x024F); // Latin extended
    if (isLtr) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}

/// A [Text] that auto-aligns and auto-directs based on the content's
/// script, so RTL languages (Hebrew, Arabic) read correctly without
/// forcing the whole app into RTL mode.
class BidiText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const BidiText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final direction = detectTextDirection(text);
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: direction,
      textAlign: direction == TextDirection.rtl ? TextAlign.right : TextAlign.left,
    );
  }
}

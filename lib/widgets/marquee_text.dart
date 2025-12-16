import 'package:flutter/material.dart';

/// A simple marquee text widget that scrolls text once, pauses, then resets.
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double velocity;
  final Duration startDelay;
  final Duration endPause;
  final double? height;
  final bool centerWhenFits;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.velocity = 30.0,
    this.startDelay = const Duration(seconds: 3),
    this.endPause = const Duration(seconds: 3),
    this.height,
    this.centerWhenFits = false,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late final ScrollController _scrollController;
  double _opacity = 1.0;
  String? _lastText;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _lastText = widget.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarqueeLoop());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _lastText) {
      _lastText = widget.text;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      setState(() {
        _opacity = 1.0;
      });
    }
  }

  Future<void> _startMarqueeLoop() async {
    while (mounted) {
      await Future.delayed(widget.startDelay);
      if (!mounted) break;

      final widths = _measureWidths();
      if (widths != null && widths.$1 > widths.$2) {
        final distance = widths.$1 - widths.$2;
        final duration = Duration(
          milliseconds: (distance / widget.velocity * 1000).toInt(),
        );
        setState(() {
          _opacity = 1.0;
        });
        if (_scrollController.hasClients) {
          await _scrollController.animateTo(
            distance,
            duration: duration,
            curve: Curves.linear,
          );
        }
        await Future.delayed(widget.endPause);
        if (!mounted) break;
        // Fade out
        setState(() => _opacity = 0.0);
        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) break;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        // Fade in
        setState(() => _opacity = 1.0);
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  (double, double)? _measureWidths() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    final box = context.findRenderObject();
    if (box is RenderBox) {
      return (textPainter.width, box.size.width);
    }
    return null;
  }

  /// Builds the widget tree for the marquee text.
  @override
  Widget build(BuildContext context) {
    final height =
        widget.height ??
        (widget.style?.fontSize != null ? widget.style!.fontSize! * 1.4 : 28);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);
        final textWidth = painter.width;
        final containerWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // Center text when it fits
        if (widget.centerWhenFits && textWidth <= containerWidth) {
          return SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Text(
                widget.text,
                style: widget.style,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Scrollable marquee
        return SizedBox(
          height: height,
          width: double.infinity,
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: widget.style,
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
// Optional: Uncomment if you have the lottie package
// import 'package:lottie/lottie.dart';

class TAnimationLoaderWidget extends StatefulWidget {
  final String text;
  final String? animation;      // Asset path for image or Lottie
  final bool isLottie;          // Set true if animation is a Lottie file
  final double? height;
  final double? width;

  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    this.animation,
    this.isLottie = false,
    this.height,
    this.width,
  });

  @override
  State<TAnimationLoaderWidget> createState() => _TAnimationLoaderWidgetState();
}

class _TAnimationLoaderWidgetState extends State<TAnimationLoaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subtle scale animation for the visual element
    final scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated visual (image, Lottie, or default spinner)
          AnimatedBuilder(
            animation: scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              height: widget.height ?? 180,
              width: widget.width ?? 180,
              decoration: BoxDecoration(
                // Optional subtle shadow / glass effect
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _buildVisual(),
            ),
          ),
          const SizedBox(height: 32),

          // Text with modern styling
          Text(
            widget.text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  // Optional gradient text (uncomment if desired)
                  // foreground: Paint()
                  //   ..shader = const LinearGradient(
                  //     colors: [Colors.blue, Colors.purple],
                  //   ).createShader(const Rect.fromLTWH(0, 0, 200, 50)),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisual() {
    // If animation path is provided
    if (widget.animation != null && widget.animation!.isNotEmpty) {
      if (widget.isLottie) {
        // Lottie animation (requires lottie package)
        // return Lottie.asset(widget.animation!, fit: BoxFit.contain);
      }
      // Static image asset
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          widget.animation!,
          fit: BoxFit.contain,
        ),
      );
    }

    // Fallback: modern circular progress indicator with styling
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
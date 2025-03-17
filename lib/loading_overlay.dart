import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Duration duration;
  final Widget? child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.duration = const Duration(milliseconds: 1500),
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && child != null) {
      return child!;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: isLoading
          ? Scaffold(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              body: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    'assets/load.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
              ),
            )
          : child ?? Container(),
    );
  }
}

class FutureLoadingBuilder extends StatefulWidget {
  final Future<void> Function() future;
  final Duration loadingDuration;
  final Widget child;

  const FutureLoadingBuilder({
    super.key,
    required this.future,
    this.loadingDuration = const Duration(milliseconds: 1000),
    required this.child,
  });

  @override
  State<FutureLoadingBuilder> createState() => _FutureLoadingBuilderState();
}

class _FutureLoadingBuilderState extends State<FutureLoadingBuilder> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWithMinimumDuration();
  }

  Future<void> _loadWithMinimumDuration() async {
    final start = DateTime.now();
    
    // Execute the future
    await widget.future();
    
    // Calculate how much time has passed
    final elapsed = DateTime.now().difference(start);
    
    // If the future completed too quickly, wait until minimum duration
    if (elapsed < widget.loadingDuration) {
      await Future.delayed(widget.loadingDuration - elapsed);
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: widget.child,
    );
  }
}
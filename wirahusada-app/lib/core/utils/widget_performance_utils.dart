import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Utility class for widget performance optimizations
class WidgetPerformanceUtils {
  /// Creates an optimized SliverList that prevents unnecessary rebuilds
  static Widget optimizedSliverList<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    String? debugName,
  }) {
    return SliverList.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return RepaintBoundary(
          child: Builder(
            builder: (context) {
              if (kDebugMode && debugName != null) {
                debugPrint('Building $debugName item $index');
              }
              return itemBuilder(context, item, index);
            },
          ),
        );
      },
    );
  }

  /// Creates an optimized GridView for large datasets
  static Widget optimizedGridView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    String? debugName,
  }) {
    return GridView.builder(
      controller: controller,
      gridDelegate: gridDelegate,
      itemCount: items.length,
      cacheExtent: 250.0,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false, // We handle manually
      itemBuilder: (context, index) {
        final item = items[index];
        return RepaintBoundary(
          child: Builder(
            builder: (context) {
              if (kDebugMode && debugName != null) {
                debugPrint('Building $debugName grid item $index');
              }
              return itemBuilder(context, item, index);
            },
          ),
        );
      },
    );
  }

  /// Creates a performance-optimized AnimatedBuilder
  static Widget optimizedAnimatedBuilder({
    required Animation<double> animation,
    required Widget Function(BuildContext, Animation<double>) builder,
    String? debugName,
    bool useRepaintBoundary = true,
  }) {
    final animatedWidget = AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        if (kDebugMode && debugName != null) {
          debugPrint('Animating $debugName');
        }
        return builder(context, animation);
      },
    );

    return useRepaintBoundary 
        ? RepaintBoundary(child: animatedWidget)
        : animatedWidget;
  }

  /// Wraps a widget with conditional RepaintBoundary based on complexity
  static Widget conditionalRepaintBoundary({
    required Widget child,
    required bool shouldUse,
    String? debugName,
  }) {
    if (!shouldUse) return child;

    return RepaintBoundary(
      child: kDebugMode && debugName != null
          ? Builder(
              builder: (context) {
                debugPrint('RepaintBoundary for $debugName');
                return child;
              },
            )
          : child,
    );
  }

  /// Creates an optimized CustomScrollView with performance considerations
  static Widget optimizedCustomScrollView({
    required List<Widget> slivers,
    ScrollController? controller,
    ScrollPhysics? physics,
    double cacheExtent = 250.0,
    String? debugName,
  }) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      cacheExtent: cacheExtent,
      slivers: slivers.map((sliver) {
        return conditionalRepaintBoundary(
          shouldUse: true,
          debugName: debugName != null ? '$debugName sliver' : null,
          child: sliver,
        );
      }).toList(),
    );
  }

  /// Creates a debounced callback for input fields
  static VoidCallback debounceCallback({
    required VoidCallback callback,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, callback);
    };
  }

  /// Creates a throttled callback for scroll events
  static VoidCallback throttleCallback({
    required VoidCallback callback,
    Duration interval = const Duration(milliseconds: 16), // ~60fps
  }) {
    bool isThrottled = false;
    return () {
      if (isThrottled) return;
      isThrottled = true;
      callback();
      Timer(interval, () => isThrottled = false);
    };
  }

  /// Memory-efficient image loading with proper cache management
  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext)? placeholder,
    Widget Function(BuildContext, String)? errorBuilder,
  }) {
    return RepaintBoundary(
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: frame != null ? child : placeholder?.call(context) ?? const SizedBox(),
          );
        },
        errorBuilder: errorBuilder != null 
            ? (context, error, stackTrace) => errorBuilder(context, error.toString())
            : null,
        // Optimize memory usage
        cacheWidth: width?.round(),
        cacheHeight: height?.round(),
      ),
    );
  }
}
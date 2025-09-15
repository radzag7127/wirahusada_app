import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Optimized BlocBuilder that prevents unnecessary rebuilds by implementing
/// smart build conditions and RepaintBoundary
class OptimizedBlocBuilder<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  const OptimizedBlocBuilder({
    super.key,
    required this.builder,
    this.bloc,
    this.buildWhen,
    this.useRepaintBoundary = true,
    this.debugName,
  });

  /// The [Bloc] that the [OptimizedBlocBuilder] will interact with.
  final B? bloc;

  /// The builder function which will be invoked on each widget build.
  final BlocWidgetBuilder<S> builder;

  /// An optional [BlocBuilderCondition] which takes the previous state and the current state
  /// and returns a bool which determines whether or not to rebuild the widget
  final BlocBuilderCondition<S>? buildWhen;

  /// Whether to wrap the built widget with RepaintBoundary for better performance
  final bool useRepaintBoundary;

  /// Optional debug name for performance profiling
  final String? debugName;

  @override
  Widget build(BuildContext context) {
    final widget = BlocBuilder<B, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      builder: (context, state) {
        if (kDebugMode && debugName != null) {
          // Simple debug logging without Timeline for better compatibility
          debugPrint('Building $debugName with state: ${state.runtimeType}');
        }
        return builder(context, state);
      },
    );

    return useRepaintBoundary ? RepaintBoundary(child: widget) : widget;
  }

  /// Default build condition that prevents rebuilds for identical states
  bool _defaultBuildWhen(S previous, S current) {
    // Use object equality if states are value objects (Equatable)
    if (previous.runtimeType == current.runtimeType) {
      try {
        return previous != current;
      } catch (e) {
        // Fallback to reference equality if comparison fails
        return !identical(previous, current);
      }
    }
    // Different types always trigger rebuild
    return true;
  }
}

/// Optimized BlocConsumer that prevents unnecessary rebuilds
class OptimizedBlocConsumer<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  const OptimizedBlocConsumer({
    super.key,
    required this.builder,
    required this.listener,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    this.useRepaintBoundary = true,
    this.debugName,
  });

  final B? bloc;
  final BlocWidgetBuilder<S> builder;
  final BlocWidgetListener<S> listener;
  final BlocBuilderCondition<S>? buildWhen;
  final BlocListenerCondition<S>? listenWhen;
  final bool useRepaintBoundary;
  final String? debugName;

  @override
  Widget build(BuildContext context) {
    final widget = BlocConsumer<B, S>(
      bloc: bloc,
      buildWhen: buildWhen ?? _defaultBuildWhen,
      listenWhen: listenWhen,
      listener: listener,
      builder: (context, state) {
        if (kDebugMode && debugName != null) {
          debugPrint('Building $debugName consumer with state: ${state.runtimeType}');
        }
        return builder(context, state);
      },
    );

    return useRepaintBoundary ? RepaintBoundary(child: widget) : widget;
  }

  bool _defaultBuildWhen(S previous, S current) {
    if (previous.runtimeType == current.runtimeType) {
      try {
        return previous != current;
      } catch (e) {
        return !identical(previous, current);
      }
    }
    return true;
  }
}

/// Mixin for state classes to optimize widget building performance
mixin PerformantWidget<T extends StatefulWidget> on State<T> {
  /// Override to provide custom rebuild conditions
  bool shouldRebuild(covariant oldWidget) {
    return widget != oldWidget;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!shouldRebuild(oldWidget)) {
      // Skip expensive operations if widget hasn't meaningfully changed
      return;
    }
  }

  /// Wrap widgets that update frequently with RepaintBoundary
  Widget withRepaintBoundary(Widget child, {String? debugName}) {
    return RepaintBoundary(
      child: kDebugMode && debugName != null
          ? Builder(
              builder: (context) {
                debugPrint('Repainting $debugName');
                return child;
              },
            )
          : child,
    );
  }
}

/// Performance-optimized ListView builder for large lists
class OptimizedListView extends StatelessWidget {
  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.cacheExtent = 250.0,
    this.semanticChildCount,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Axis scrollDirection;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final double cacheExtent;
  final int? semanticChildCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      scrollDirection: scrollDirection,
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      cacheExtent: cacheExtent,
      semanticChildCount: semanticChildCount,
      // Optimize item building with RepaintBoundary
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
      // Optimize memory usage
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false, // We handle this manually above
      addSemanticIndexes: true,
    );
  }
}
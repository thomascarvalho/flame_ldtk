import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_ldtk/flame_ldtk.dart';

/// Player component with platformer physics.
class Player extends PositionComponent {
  final LdtkEntity entity;
  final LdtkLevel level;

  // Physics constants
  static const double moveSpeed = 100.0;
  static const double jumpForce = -300.0;
  static const double gravity = 800.0;
  static const double maxFallSpeed = 400.0;

  // State
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;

  // Input state
  bool _isMovingLeft = false;
  bool _isMovingRight = false;
  bool _wantsToJump = false;

  Player(this.entity, this.level) {
    position = entity.position;
    size = entity.size;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Render the player using sprite if available, otherwise use colored rectangle
    if (entity.sprite != null) {
      final spriteComponent = SpriteComponent(
        sprite: entity.sprite,
        size: size,
      );
      await add(spriteComponent);
    } else {
      final color = entity.color ?? Colors.blue;
      final rect = RectangleComponent(
        size: size,
        paint: Paint()..color = color,
      );
      await add(rect);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final collisions = level.intGrids['Collisions'];
    if (collisions == null) return;

    _updateHorizontalMovement(dt, collisions);
    _updateVerticalMovement(dt, collisions);
    _keepWithinBounds();
  }

  void _updateHorizontalMovement(double dt, LdtkIntGrid collisions) {
    // Apply horizontal velocity
    velocity.x = 0;
    if (_isMovingLeft) velocity.x = -moveSpeed;
    if (_isMovingRight) velocity.x = moveSpeed;

    // Apply horizontal movement with collision detection
    final newX = position.x + velocity.x * dt;
    if (_canMoveTo(collisions, newX, position.y)) {
      position.x = newX;
    } else {
      velocity.x = 0;
    }
  }

  void _updateVerticalMovement(double dt, LdtkIntGrid collisions) {
    // Jump
    if (_wantsToJump && isOnGround) {
      velocity.y = jumpForce;
      isOnGround = false;
    }

    // Apply gravity
    velocity.y += gravity * dt;
    if (velocity.y > maxFallSpeed) {
      velocity.y = maxFallSpeed;
    }

    // Apply vertical movement with collision detection
    final newY = position.y + velocity.y * dt;
    if (_canMoveTo(collisions, position.x, newY)) {
      position.y = newY;
      isOnGround = false;
    } else {
      if (velocity.y > 0) {
        isOnGround = true;
      }
      velocity.y = 0;
    }
  }

  void _keepWithinBounds() {
    // Horizontal bounds
    if (position.x < 0) position.x = 0;
    if (position.x > level.width - size.x) {
      position.x = level.width - size.x;
    }

    // Vertical bounds
    if (position.y < 0) {
      position.y = 0;
      velocity.y = 0;
    }
    if (position.y >= level.height - size.y) {
      position.y = level.height - size.y;
      velocity.y = 0;
      isOnGround = true;
    }
  }

  /// Checks if the player can move to the given position.
  bool _canMoveTo(LdtkIntGrid collisions, double x, double y) {
    // Check all four corners of the player hitbox
    final corners = [
      (x, y), // Top-left
      (x + size.x - 1, y), // Top-right
      (x, y + size.y - 1), // Bottom-left
      (x + size.x - 1, y + size.y - 1), // Bottom-right
    ];

    for (final (cornerX, cornerY) in corners) {
      if (collisions.isSolidAtPixel(cornerX, cornerY)) {
        return false;
      }
    }
    return true;
  }

  /// Handle keyboard input.
  void handleInput(Set<LogicalKeyboardKey> keysPressed) {
    _isMovingLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    _isMovingRight = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);
    _wantsToJump = keysPressed.contains(LogicalKeyboardKey.space) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);
  }
}

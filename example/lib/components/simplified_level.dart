import 'package:flame_ldtk/flame_ldtk.dart';
import 'player.dart';

/// Custom level component that handles entity instantiation.
class SimplifiedLevel extends LdtkLevelComponent {
  Player? player;

  SimplifiedLevel(super.world);

  @override
  Future<void> onEntitiesLoaded(List<LdtkEntity> entities) async {
    for (final entity in entities) {
      // Instantiate entities based on their type
      switch (entity.identifier) {
        case 'Player':
          player = Player(entity, levelData!);
          await add(player!);
          break;

        // Add more entity types here as needed
        // case 'Enemy':
        //   final enemy = Enemy(entity, levelData!);
        //   await add(enemy);
        //   break;
      }
    }
  }
}

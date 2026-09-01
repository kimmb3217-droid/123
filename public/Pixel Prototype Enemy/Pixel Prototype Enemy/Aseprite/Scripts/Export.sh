
#!/bin/bash

ASEPRITE_PATH="Aseprite"
ENEMY_PATH="../Enemy.aseprite"
PLAYER_FISHING_PATH="../EnemyFishing.aseprite"
COMBAT_PATH="../EnemyCombat.aseprite"
EFFECTS_PATH="../Effects.aseprite"
WEAPONS_PATH="../Weapons.aseprite"
PREVIEW_PATH="../../../AssetPage/PreviewAnimations.aseprite"
PLAYER_WITH_EFFECTS_PATH="../../../AssetPage/EnemyAnimationsWithEffects.aseprite"
SPRITES_FOLDER="../../Sprites/"
SPRITES_SEPARATED_FOLDER="../../SpritesSeparated/"
PREVIEW_FOLDER="../../../Preview"
PARAMS="--script-param sprites-folder=$SPRITES_FOLDER"
BACKGROUND_LAYER="Background"
REFERENCE_LAYER="Reference"
DEFAULT_PARAMS="--ignore-layer "Background" --ignore-layer "Reference" --ignore-layer "NormalMap""

display_menu() {
  echo "Please choose an option:"
  echo "1. Enemy"
  echo "2. Enemy Parts"
  echo "3. Effects"
  echo "4. Previews"
  echo "5. All"
  echo "6. Exit"
}

export_enemy() {
  echo "Exporting Enemy"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --save-as $SPRITES_FOLDER/{tag}/{tag}{frame01}.png --split-tags
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --sheet $SPRITES_FOLDER/EnemySheet.png --data $SPRITES_FOLDER/EnemySheet.json --split-tags
  echo "Exported Enemy"
  
  # "$ASEPRITE_PATH" -b "$ENEMY_PATH" --save-as %UNITY_PATH%/Aseprite/EnemyAnimations.aseprite
}

export_effects() {
  echo "Exporting Effects"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$EFFECTS_PATH" --save-as $SPRITES_FOLDER/Effects/{tag}/{tag}{frame01}.png --split-tags
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$EFFECTS_PATH" --sheet $SPRITES_FOLDER/EffectsSheet.png --data $SPRITES_FOLDER/EffectsSheet.json --split-tags
  echo "Exported Enemy"
  
  # "$ASEPRITE_PATH" -b "$ENEMY_PATH" --save-as %UNITY_PATH%/Aseprite/EnemyAnimations.aseprite
}

export_enemy_parts() {
  echo "Exporting Enemy Parts"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/RightArm" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/RightArm/{tag}{frame01}.png
  echo "Exported Right Arm"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/LeftArm" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/LeftArm/{tag}{frame01}.png
  echo "Exported Left Arm"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/Head" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/Head/{tag}{frame01}.png
  echo "Exported Head"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/RightLeg" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/RightLeg/{tag}{frame01}.png
  echo "Exported Right Leg"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/LeftLeg" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/LeftLeg/{tag}{frame01}.png
  echo "Exported Left Leg"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/Torso" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/Torso/{tag}{frame01}.png
  echo "Exported Torso"
  "$ASEPRITE_PATH" -b $DEFAULT_PARAMS "$ENEMY_PATH" --layer "Enemy/Smoke" --layer "Enemy/Flame" --layer "Enemy/VFX" --save-as $SPRITES_SEPARATED_FOLDER/{tag}/Effects/{tag}{frame01}.png
  echo "Exported Effeccts"
  echo "Exported Enemy Parts"
}

export_preview() {
  echo "Exporting Previews"
  "$ASEPRITE_PATH" -b "$PREVIEW_PATH" --scale 2 --save-as $PREVIEW_FOLDER/PreviewAnimations.gif
  "$ASEPRITE_PATH" -b "$PLAYER_WITH_EFFECTS_PATH" --scale 2 --save-as $PREVIEW_FOLDER/{tag}.gif
  "$ASEPRITE_PATH" -b -ignore-layer "Background" -ignore-layer "Ref" -ignore-layer "BackgroundElements" -ignore-layer "Ground" -ignore-layer "EnemyReflection" -ignore-layer "BackgroundOverlay" -ignore-layer "Frame" -ignore-layer "Reflection" "$PLAYER_WITH_EFFECTS_PATH" --scale 2 --save-as $PREVIEW_FOLDER/Transparent/{tag}.gif
  "$ASEPRITE_PATH" -b -layer "BackgroundElements" "$PLAYER_WITH_EFFECTS_PATH" --scale 2 --save-as $PREVIEW_FOLDER/BackgroundElements/{tag}.gif
  echo "Exported Previews"
}

while true; do
  display_menu
  read -p "Enter your choice [1-9]: " choice

  case $choice in
    1)
      export_enemy
      ;;
    2)
      export_enemy_parts
      ;;
    3)
      export_effects
      ;;
    4)
      # export_preview
      ;;
    5)
      export_enemy
      export_enemy_parts
      # export_preview
      ;;
    6)
      echo "Exiting..."
      break
      ;;
    *)
      echo "Invalid option. Please try again."
      ;;
  esac

  echo ""
done
import 'dart:ui';

import 'package:flame/components/component.dart';
import 'package:flame/components/resizable.dart';
import 'package:flame/position.dart';
import 'package:flame/sprite.dart';

import '../audio.dart';
import '../components/coin.dart';
import '../constants.dart';
import '../data.dart';
import '../mixins/has_game_ref.dart';
import '../palette.dart';

class BaseBlock {
  int slot;

  bool upper() {
    return slot <= 3;
  }

  bool lower() {
    return slot > 3;
  }
}

class BlockTween extends SpriteComponent with BaseBlock, HasGameRef, Resizable {
  static const TIME_TWEEN = 0.5;
  static const TIME_UP = 0.5;
  static const TIME_DOWN = 0.1;
  static const TOTAL_TIME = TIME_TWEEN + TIME_UP + TIME_DOWN;
  static const MAX_SCALE = 1.25;

  bool done = false;
  Position src, dest = new Position.empty();
  double clock = 0.0;
  bool _played = false;

  BlockTween(this.src, int slot) : super.fromSprite(16.0, 16.0, new Sprite('block.png')) {
    this.slot = slot;
  }

  @override
  void update(double t) {
    if (done) {
      return;
    }

    clock += t;

    double tweenProgress = clock.clamp(0, TIME_TWEEN) / TIME_TWEEN;
    x = src.x + (dest.x - src.x) * tweenProgress;
    y = src.y + (dest.y - src.y) * tweenProgress;

    if (clock >= TIME_TWEEN && clock < TIME_TWEEN + TIME_UP) {
      double animationProgress = (clock - TIME_TWEEN).clamp(0, TIME_UP) / TIME_UP;
      double currentScale = 1 + (MAX_SCALE - 1) * animationProgress;
      setScale(currentScale);
    } else if (clock >= TIME_TWEEN + TIME_UP) {
      if (!_played) {
        _played = true;
        Audio.playSfx('block.wav');
      }
      double animationProgress = (clock - TIME_TWEEN - TIME_UP).clamp(0, TIME_DOWN) / TIME_DOWN;
      double currentScale = MAX_SCALE - (MAX_SCALE - 1) * animationProgress;
      setScale(currentScale);
    }

    if (clock >= TOTAL_TIME) {
      gameRef.addLater(Block(slot, false));
      gameRef.addLater(
          CoinTrace(true, dest, gameRef.hud.getActualCoinPosition(), doAfter: () => gameRef.currentCoins += Data.currentOptions.coinsAwardedPerBlock));
      done = true;
    }
  }

  void setScale(double currentScale) {
    width = sizeTenth(size) * currentScale;
    height = sizeTenth(size) * currentScale;
    x -= (currentScale - 1) * width / 2;
    y -= (currentScale - 1) * height / 2;
  }

  @override
  void resize(Size size) {
    super.resize(size);
    this.width = this.height = sizeTenth(size);
    this.dest.x = size.width - this.width;
    this.dest.y = sizeTop(size) + this.slot * this.height;
  }

  @override
  bool isHud() => true;

  @override
  bool destroy() => done;
}

class Block extends SpriteComponent with BaseBlock, HasGameRef {
  static int minUp(int currentSlot) {
    if (currentSlot <= 0 || currentSlot == 7) {
      return 1;
    } else if (currentSlot == 1 || currentSlot == 6) {
      return 2;
    } else if (currentSlot == 2 || currentSlot == 5) {
      return 3;
    } else {
      return null;
    }
  }

  static int maxDown(int currentSlot) {
    if (currentSlot <= 1 || currentSlot == 7) {
      return 6;
    } else if (currentSlot == 6 || currentSlot == 2) {
      return 5;
    } else if (currentSlot == 5 || currentSlot == 3) {
      return 4;
    } else {
      return null;
    }
  }

  static const List<int> SLOT_ORDER = [0, 7, 1, 6, 2, 5, 3, 4];

  static int orderToSlot(int amountBlocks) {
    return SLOT_ORDER[amountBlocks];
  }

  bool eternal;
  double clock = 0.0;
  bool _destroy = false;

  Block(slot, this.eternal) : super.fromSprite(16.0, 16.0, new Sprite('block.png')) {
    this.slot = slot;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!eternal && Data.currentOptions.blockLifespan != -1) {
      double frac = clock / Data.currentOptions.blockLifespan;
      canvas.drawRect(Rect.fromLTWH(0.0, height - 6.0, width, 6.0), Palette.grey.paint);
      canvas.drawRect(Rect.fromLTWH(1.0, height - 5.0, (width - 2.0) * (1 - frac), 4.0), Palette.green.paint);
    }
  }

  @override
  void update(double t) {
    if (eternal || _destroy) {
      return;
    }

    clock += t;
    clock = clock.clamp(0, Data.currentOptions.blockLifespan);

    if (clock == Data.currentOptions.blockLifespan) {
      _destroy = true;
    }
  }

  @override
  void resize(Size size) {
    this.width = this.height = sizeTenth(size);
    this.x = size.width - this.width;
    this.y = sizeTop(size) + this.slot * this.height;
  }

  @override
  bool isHud() => true;

  @override
  bool destroy() => _destroy;
}

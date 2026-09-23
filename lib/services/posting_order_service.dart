import 'dart:ui' as ui;

/// Single source of truth for turning visual tiles (reading order:
/// left-to-right, top-to-bottom) into the order they must actually be
/// posted in, since platforms like Instagram display the newest post
/// first (top-left) — posting order is the reverse of reading order.
/// Every export path (Save, Share, and any future export) must call
/// this rather than reordering independently, so they can never
/// disagree with each other or with the "Your Grids" numbering.
class PostingOrderService {
  static List<ui.Image> getPostingOrderedTiles(List<ui.Image> visualTiles) {
    return visualTiles.reversed.toList();
  }
}

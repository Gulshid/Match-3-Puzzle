import 'package:match3_puzzle/features/game/domain/enums/tile_type.dart';

/// A single tile on the board.
///
/// `row`/`col` are the tile's *current* logical position — they change as
/// tiles swap and fall, but `id` stays fixed so animations (Phase 6) can
/// track a specific tile across state updates.
class TileModel {
  final String id;
  final TileType type;
  final int row;
  final int col;

  /// Set true when this tile has been matched and is pending removal.
  /// Not used for match-detection logic itself (that's Phase 3), just for
  /// marking state between "matched" and "cleared".
  final bool isMatched;

  const TileModel({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.isMatched = false,
  });

  TileModel copyWith({
    String? id,
    TileType? type,
    int? row,
    int? col,
    bool? isMatched,
  }) {
    return TileModel(
      id: id ?? this.id,
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  @override
  bool operator ==(Object other) => other is TileModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tile($id, $type, r:$row, c:$col)';
}

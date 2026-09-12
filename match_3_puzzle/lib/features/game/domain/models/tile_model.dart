import '../enums/tile_type.dart';

/// A single tile on the board.
///
/// Phase 9 additions:
/// - [specialType]: null for a normal tile; set to one of the
///   [SpecialTileType] variants when created from a big match.
/// - [stripeDirection]: only meaningful when [specialType] is
///   [SpecialTileType.striped]; records whether the stripe fires
///   horizontally or vertically.
/// - [isActivating]: set true for one state update right before the
///   special tile's effect fires, so the widget can play a pop/flash.
class TileModel {
  final String id;
  final TileType type;
  final int row;
  final int col;
  final bool isMatched;

  // Phase 9 fields
  final SpecialTileType? specialType;
  final StripeDirection? stripeDirection;
  final bool isActivating;

  const TileModel({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.isMatched = false,
    this.specialType,
    this.stripeDirection,
    this.isActivating = false,
  });

  bool get isSpecial => specialType != null;

  TileModel copyWith({
    String? id,
    TileType? type,
    int? row,
    int? col,
    bool? isMatched,
    SpecialTileType? specialType,
    bool clearSpecial = false,
    StripeDirection? stripeDirection,
    bool? isActivating,
  }) {
    return TileModel(
      id: id ?? this.id,
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
      isMatched: isMatched ?? this.isMatched,
      specialType: clearSpecial ? null : (specialType ?? this.specialType),
      stripeDirection: clearSpecial
          ? null
          : (stripeDirection ?? this.stripeDirection),
      isActivating: isActivating ?? this.isActivating,
    );
  }

  @override
  bool operator ==(Object other) => other is TileModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Tile($id, $type${specialType != null ? ', $specialType' : ''}, r:$row, c:$col)';
}

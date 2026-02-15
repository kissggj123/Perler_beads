import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/animations.dart';

class InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  final int lowStockThreshold;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(int) onQuantityChanged;
  final int? index;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.lowStockThreshold,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = item.quantity <= lowStockThreshold && item.quantity > 0;
    final isOutOfStock = item.quantity <= 0;

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _buildColorPreview(context),
            const SizedBox(width: 12),
            _buildCodeColumn(context),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildNameColumn(context)),
            Expanded(child: _buildBrandColumn(context)),
            Expanded(child: _buildCategoryColumn(context)),
            SizedBox(
              width: 100,
              child: _buildQuantityControl(context, isLowStock, isOutOfStock),
            ),
            SizedBox(width: 100, child: _buildActionButtons(context)),
          ],
        ),
      ),
    );

    if (index != null) {
      return AnimatedListItem(index: index!, child: card);
    }
    return card;
  }

  Widget _buildColorPreview(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: item.beadColor.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: item.beadColor.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: item.beadColor.isLight
          ? null
          : Icon(Icons.check, color: Colors.white.withOpacity(0.5), size: 20),
    );
  }

  Widget _buildCodeColumn(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.beadColor.code,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            item.beadColor.hexCode,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameColumn(BuildContext context) {
    return Text(
      item.beadColor.name,
      style: Theme.of(context).textTheme.bodyMedium,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBrandColumn(BuildContext context) {
    return Text(
      _getBrandName(item.beadColor.brand),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCategoryColumn(BuildContext context) {
    return Text(
      item.beadColor.category ?? '未分类',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildQuantityControl(
    BuildContext context,
    bool isLowStock,
    bool isOutOfStock,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isOutOfStock
            ? colorScheme.errorContainer
            : isLowStock
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: item.quantity > 0
                ? () => onQuantityChanged(item.quantity - 1)
                : null,
          ),
          Text(
            '${item.quantity}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isOutOfStock
                  ? colorScheme.onErrorContainer
                  : isLowStock
                  ? colorScheme.onTertiaryContainer
                  : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: '编辑',
          onPressed: onEdit,
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: Theme.of(context).colorScheme.error,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: '删除',
          onPressed: onDelete,
        ),
      ],
    );
  }

  String _getBrandName(BeadBrand brand) {
    switch (brand) {
      case BeadBrand.perler:
        return 'Perler';
      case BeadBrand.hama:
        return 'Hama';
      case BeadBrand.artkal:
        return 'Artkal';
      case BeadBrand.taobao:
        return '淘宝';
      case BeadBrand.pinduoduo:
        return '拼多多';
      case BeadBrand.generic:
        return '通用';
    }
  }
}

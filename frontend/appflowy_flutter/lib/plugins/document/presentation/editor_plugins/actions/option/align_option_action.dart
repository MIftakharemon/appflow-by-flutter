import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum OptionAlignType {
  left,
  center,
  right;

  static OptionAlignType fromString(String? value) {
    switch (value) {
      case 'left':
        return OptionAlignType.left;
      case 'center':
        return OptionAlignType.center;
      case 'right':
        return OptionAlignType.right;
      default:
        return OptionAlignType.center;
    }
  }

  FlowySvgData get svg {
    switch (this) {
      case OptionAlignType.left:
        return FlowySvgs.table_align_left_s;
      case OptionAlignType.center:
        return FlowySvgs.table_align_center_s;
      case OptionAlignType.right:
        return FlowySvgs.table_align_right_s;
    }
  }

  String get description {
    switch (this) {
      case OptionAlignType.left:
        return LocaleKeys.document_plugins_optionAction_left.tr();
      case OptionAlignType.center:
        return LocaleKeys.document_plugins_optionAction_center.tr();
      case OptionAlignType.right:
        return LocaleKeys.document_plugins_optionAction_right.tr();
    }
  }
}

class AlignOptionAction extends PopoverActionCell {
  AlignOptionAction({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget? leftIcon(Color iconColor) {
    return FlowySvg(
      align.svg,
      size: const Size.square(18),
    );
  }

  @override
  String get name {
    return LocaleKeys.document_plugins_optionAction_align.tr();
  }

  @override
  PopoverActionCellBuilder get builder =>
      (context, parentController, controller) {
        final selection = editorState.selection?.normalized;
        if (selection == null) {
          return const SizedBox.shrink();
        }
        final node = editorState.getNodeAtPath(selection.start.path);
        if (node == null) {
          return const SizedBox.shrink();
        }
        final children = buildAlignOptions(context, (align) async {
          await onAlignChanged(align);
          controller.close();
          parentController.close();
        });
        return IntrinsicHeight(
          child: IntrinsicWidth(
            child: Column(
              children: children,
            ),
          ),
        );
      };

  List<Widget> buildAlignOptions(
    BuildContext context,
    void Function(OptionAlignType) onTap,
  ) {
    return OptionAlignType.values.map((e) => OptionAlignWrapper(e)).map((e) {
      final leftIcon = e.leftIcon(Theme.of(context).colorScheme.onSurface);
      final rightIcon = e.rightIcon(Theme.of(context).colorScheme.onSurface);
      return HoverButton(
        onTap: () => onTap(e.inner),
        itemHeight: ActionListSizes.itemHeight,
        leftIcon: SizedBox(
          width: 16,
          height: 16,
          child: leftIcon,
        ),
        name: e.name,
        rightIcon: rightIcon,
      );
    }).toList();
  }

  OptionAlignType get align {
    final selection = editorState.selection;
    if (selection == null) {
      return OptionAlignType.center;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final align = node?.type == SimpleTableBlockKeys.type
        ? node?.tableAlign.key
        : node?.attributes[blockComponentAlign];
    return OptionAlignType.fromString(align);
  }

  Future<void> onAlignChanged(OptionAlignType align) async {
    if (align == this.align) {
      return;
    }
    final selection = editorState.selection;
    if (selection == null) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    // the align attribute for simple table is not same as the align type,
    // so we need to convert the align type to the align attribute
    if (node.type == SimpleTableBlockKeys.type) {
      await editorState.updateTableAlign(
        tableNode: node,
        align: TableAlign.fromString(align.name),
      );
    } else {
      final transaction = editorState.transaction;
      transaction.updateNode(node, {
        blockComponentAlign: align.name,
      });
      await editorState.apply(transaction);
    }
  }
}

class OptionAlignWrapper extends ActionCell {
  OptionAlignWrapper(this.inner);

  final OptionAlignType inner;

  @override
  Widget? leftIcon(Color iconColor) => FlowySvg(inner.svg);

  @override
  String get name => inner.description;
}

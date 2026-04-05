import 'package:flutter/material.dart';

import '../services/mention_service.dart';

class MentionTextField extends StatefulWidget {
  const MentionTextField({
    super.key,
    required this.controller,
    required this.candidates,
    required this.decoration,
    this.excludeUserId,
    this.minLines,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.sentences,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final List<MentionCandidate> candidates;
  final InputDecoration decoration;
  final String? excludeUserId;
  final int? minLines;
  final int? maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  List<MentionCandidate> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant MentionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
    _handleTextChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final selection = widget.controller.selection;
    final cursorIndex = selection.baseOffset;
    final query = MentionService.currentMentionQuery(
      widget.controller.text,
      cursorIndex,
    );
    final safeCursor = cursorIndex < 0
        ? 0
        : (cursorIndex > widget.controller.text.length
            ? widget.controller.text.length
            : cursorIndex);

    if (query.isEmpty &&
        !widget.controller.text.substring(0, safeCursor).endsWith('@')) {
      if (_suggestions.isNotEmpty) {
        setState(() {
          _suggestions = const [];
        });
      }
      return;
    }

    final normalizedQuery = query.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );

    final matches = widget.candidates
        .where((candidate) {
          if (candidate.userId == widget.excludeUserId) {
            return false;
          }

          final normalizedName = candidate.name
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '');

          return normalizedQuery.isEmpty ||
              normalizedName.contains(normalizedQuery);
        })
        .take(5)
        .toList();

    setState(() {
      _suggestions = matches;
    });
  }

  void _selectMention(MentionCandidate candidate) {
    final selection = widget.controller.selection;
    final cursorIndex = selection.baseOffset;
    final updatedText = MentionService.insertMention(
      text: widget.controller.text,
      cursorIndex: cursorIndex,
      mentionName: candidate.name,
    );

    widget.controller.value = TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(
        offset: updatedText.length,
      ),
    );

    setState(() {
      _suggestions = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          textCapitalization: widget.textCapitalization,
          decoration: widget.decoration,
          onSubmitted: widget.onSubmitted,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Column(
              children: _suggestions
                  .map(
                    (candidate) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        child: Text(
                          candidate.name.isNotEmpty
                              ? candidate.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(candidate.name),
                      subtitle: candidate.role.isNotEmpty
                          ? Text(candidate.role)
                          : null,
                      onTap: () => _selectMention(candidate),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

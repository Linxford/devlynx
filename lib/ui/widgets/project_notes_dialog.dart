import 'package:flutter/material.dart';
import '../../data/project_scanner.dart';
import '../../data/project_notes.dart';

class ProjectNotesDialog extends StatefulWidget {
  final Project project;
  final ProjectNote? existingNote;

  const ProjectNotesDialog({
    super.key,
    required this.project,
    this.existingNote,
  });

  @override
  State<ProjectNotesDialog> createState() => _ProjectNotesDialogState();
}

class _ProjectNotesDialogState extends State<ProjectNotesDialog> {
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  List<String> _tags = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
    _tagController = TextEditingController();
    _tags = List.from(widget.existingNote?.tags ?? []);
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note content cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notesManager = ProjectNotesManager();
      await notesManager.saveNote(
        widget.project.path,
        _contentController.text.trim(),
        tags: _tags,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save note: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteNote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);

      try {
        final notesManager = ProjectNotesManager();
        await notesManager.deleteNote(widget.project.path);

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete note: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colorScheme = Theme.of(context).colorScheme;
    final isTablet = screenSize.width > 800;
    final isMobile = screenSize.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile 
            ? screenSize.width * 0.95 
            : (isTablet ? screenSize.width * 0.7 : screenSize.width * 0.8),
        height: isMobile 
            ? screenSize.height * 0.85 
            : screenSize.height * 0.75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface.withOpacity(0.95),
              colorScheme.surfaceContainerHighest.withOpacity(0.9),
              colorScheme.primaryContainer.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, colorScheme, isMobile),
              SizedBox(height: isMobile ? 16 : 24),

            // Content Input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface.withOpacity(0.8),
                      colorScheme.surfaceContainerHighest.withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: isMobile
                        ? '📝 Write your notes here...'
                        : '📝 Write your notes here...\n\n💡 Project ideas\n✅ TODO items\n⚡ Important commands\n🐛 Debugging notes',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: isMobile ? 14 : 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
                  ),
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    height: 1.5,
                  ),
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Tags Section
            Row(
              children: [
                const Text('🏷️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),

            // Add Tag Input
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.surface.withOpacity(0.8),
                          colorScheme.surfaceContainerHighest.withOpacity(0.6),
                        ],
                      ),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: '✨ Add tag...',
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 6 : 8),
                Tooltip(
                  message: 'Add new tag',
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: _addTag,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('➕', style: TextStyle(fontSize: 14)),
                          if (!isMobile) ...[
                            const SizedBox(width: 4),
                            const Text('Add'),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 12),

            // Tags Display
            if (_tags.isNotEmpty)
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tags
                      .map(
                        (tag) => Tooltip(
                          message: 'Remove tag: $tag',
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colorScheme.primaryContainer.withOpacity(0.8),
                                  colorScheme.primaryContainer.withOpacity(0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Chip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isMobile ? 12 : 13,
                                ),
                              ),
                              deleteIcon: const Text('❌', style: TextStyle(fontSize: 12)),
                              onDeleted: () => _removeTag(tag),
                              backgroundColor: Colors.transparent,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            SizedBox(height: isMobile ? 16 : 24),

            // Action Buttons
            _buildActionButtons(context, colorScheme, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.8),
                colorScheme.primary.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            widget.project.icon,
            style: TextStyle(fontSize: isMobile ? 20 : 24),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes for ${widget.project.displayName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 18 : 22,
                  letterSpacing: -0.5,
                ),
              ),
              if (!isMobile)
                Tooltip(
                  message: widget.project.path,
                  child: Text(
                    widget.project.path,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        Tooltip(
          message: 'Close dialog',
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Text('❌', style: TextStyle(fontSize: 16)),
              padding: EdgeInsets.all(isMobile ? 8 : 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme, bool isMobile) {
    return Row(
      children: [
        if (widget.existingNote != null)
          Tooltip(
            message: 'Delete this note permanently',
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.1),
                    Colors.red.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: _isSaving ? null : _deleteNote,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🗑️', style: TextStyle(fontSize: 16)),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const Spacer(),
        Tooltip(
          message: 'Cancel without saving',
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextButton(
              onPressed: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 8 : 12),
        Tooltip(
          message: _isSaving ? 'Saving note...' : 'Save note',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: _isSaving ? null : _saveNote,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20,
                  vertical: isMobile ? 8 : 12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('💾', style: TextStyle(fontSize: 16)),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    Text(
                      _isSaving ? 'Saving...' : 'Save',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

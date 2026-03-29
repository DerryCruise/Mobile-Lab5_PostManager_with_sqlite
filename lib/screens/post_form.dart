import 'package:flutter/material.dart';
import 'package:posts_manager_with_sqlite/database/database_helper.dart';
import 'package:posts_manager_with_sqlite/models/post.dart';

class PostForm extends StatefulWidget {
  final Post? post;
  
  const PostForm({super.key, this.post});

  @override
  State<PostForm> createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.post != null;
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _savePost() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final post = Post(
        id: widget.post?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
      );

      if (_isEditing) {
        final result = await DatabaseHelper.instance.updatePost(post);
        if (result == 0) {
          // No changes were made
          _showSnackBar('No changes were made to the post', isError: false);
          Navigator.pop(context, false);
        } else {
          _showSnackBar('Post updated successfully!');
          Navigator.pop(context, true);
        }
      } else {
        await DatabaseHelper.instance.insertPost(post);
        _showSnackBar('Post created successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Post' : 'Create New Post',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_hasChanges()) {
              _showDiscardDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: _isLoading ? null : _deleteWithConfirmation,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter post title',
                  prefixIcon: const Icon(Icons.title),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  if (value.trim().length > 100) {
                    return 'Title must not exceed 100 characters';
                  }
                  return null;
                },
                maxLength: 100,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              ),
            ),
            const SizedBox(height: 20),
            
            // Content Field
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter post content',
                  prefixIcon: const Icon(Icons.article),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter content';
                  }
                  if (value.trim().length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  if (value.trim().length > 500) {
                    return 'Content must not exceed 500 characters';
                  }
                  return null;
                },
                maxLines: 8,
                maxLength: 500,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '$currentLength/$maxLength',
                      style: TextStyle(
                        fontSize: 12,
                        color: currentLength > 450 ? Colors.orange : Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _savePost,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isEditing ? 'Update Post' : 'Create Post',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            if (_isEditing) ...[
              const SizedBox(height: 12),
              // Cancel Button
              TextButton(
                onPressed: () {
                  if (_hasChanges()) {
                    _showDiscardDialog();
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
            
            // Info Text
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditing 
                          ? 'Post will only be updated if changes are detected'
                          : 'All fields are required. Minimum 3 characters for title and 10 for content.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasChanges() {
    if (_isEditing) {
      return _titleController.text.trim() != widget.post!.title ||
             _contentController.text.trim() != widget.post!.content;
    } else {
      return _titleController.text.trim().isNotEmpty ||
             _contentController.text.trim().isNotEmpty;
    }
  }

  Future<void> _showDiscardDialog() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    if (shouldDiscard == true) {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteWithConfirmation() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${widget.post!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await DatabaseHelper.instance.deletePost(widget.post!.id!);
        _showSnackBar('Post deleted successfully');
        Navigator.pop(context, true);
      } catch (e) {
        _showSnackBar('Error deleting post: ${e.toString()}', isError: true);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
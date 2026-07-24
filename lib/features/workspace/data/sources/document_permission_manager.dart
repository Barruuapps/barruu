import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/sources/document_metadata_service.dart';
import 'package:barruu/features/workspace/data/sources/permission_service.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';

/// Manages document permission operations.
///
/// This service handles:
/// - Permission level management (owner, editor, viewer)
/// - Password protection
/// - Access control checks
/// - Edit permission verification
/// - Delete permission verification
///
/// Permissions are stored in document metadata and managed through
/// the PermissionService.
class DocumentPermissionManager {
  final PermissionService _permissionService;
  final DocumentMetadataService _metadataService;

  DocumentPermissionManager(
    this._permissionService,
    this._metadataService,
  );

  /// Updates document permissions.
  ///
  /// Sets the permission level and allowed users for a document.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  /// - [permissionLevel]: The permission level to set
  /// - [allowedUsers]: List of user IDs allowed to access (optional)
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> updateDocumentPermissions(
    Directory doc,
    PermissionLevel permissionLevel, {
    List<String>? allowedUsers,
  }) async {
    try {
      final metadata = await _metadataService.getDocumentMetadata(doc);
      if (metadata == null) {
        logger.w('Cannot update permissions: metadata not found for ${doc.path}');
        return false;
      }

      // Update permission fields
      metadata[MetaFile.permissionLevelKey] = permissionLevel.name;
      if (allowedUsers != null) {
        metadata[MetaFile.allowedUsersKey] = allowedUsers;
      }
      metadata[MetaFile.updatedAtKey] = DateTime.now().toIso8601String();

      // Write updated metadata
      await _metadataService.writeDocumentMetadata(doc, metadata);

      logger.i('Updated permissions for document: ${doc.path} to level: ${permissionLevel.name}');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to update document permissions: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if user can edit a document.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  ///
  /// Returns true if the user has edit permissions, false otherwise.
  Future<bool> canEditDocument(Directory doc) async {
    try {
      final metadata = await _metadataService.getDocumentMetadata(doc);
      if (metadata == null) {
        return false;
      }

      return await _permissionService.canEdit(metadata);
    } catch (e, stackTrace) {
      logger.e('Failed to check edit permission: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if user can delete a document.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  ///
  /// Returns true if the user has delete permissions, false otherwise.
  Future<bool> canDeleteDocument(Directory doc) async {
    try {
      final metadata = await _metadataService.getDocumentMetadata(doc);
      if (metadata == null) {
        return false;
      }

      return await _permissionService.canDelete(metadata);
    } catch (e, stackTrace) {
      logger.e('Failed to check delete permission: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Gets the user's permission level for a document.
  ///
  /// Parameters:
  /// - [doc]: The document directory
  ///
  /// Returns the permission level, or null if not found or an error occurs.
  Future<PermissionLevel?> getUserPermissionLevel(Directory doc) async {
    try {
      final metadata = await _metadataService.getDocumentMetadata(doc);
      if (metadata == null) {
        return null;
      }

      return await _permissionService.getUserPermission(metadata);
    } catch (e, stackTrace) {
      logger.e('Failed to get user permission level: ${doc.path}',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }
}

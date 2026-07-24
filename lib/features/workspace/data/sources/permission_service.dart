import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permission levels for document access
enum PermissionLevel {
  owner,   // Full control: read, edit, delete, manage permissions
  editor,  // Can read and edit, but cannot delete or change permissions
  viewer;  // Read-only access

  String toJson() => name;
  
  static PermissionLevel fromJson(String json) {
    return PermissionLevel.values.firstWhere(
      (e) => e.name == json,
      orElse: () => PermissionLevel.viewer,
    );
  }
}

/// Provider for permission service
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final userIdentityService = ref.read(userIdentityServiceProvider);
  return PermissionService(userIdentityService);
});

/// Service for managing document permissions
class PermissionService {
  final UserIdentityService _userIdentityService;

  PermissionService(this._userIdentityService);

  /// Checks if the current user has the specified permission level or higher
  Future<bool> hasPermission(
    Map<String, dynamic> metadata,
    PermissionLevel requiredLevel,
  ) async {
    try {
      final userId = await _userIdentityService.getUserId();
      
      // Check if document has permissions field
      if (!metadata.containsKey(PermissionConstants.permissionsKey)) {
        // No permissions set - assume owner for backward compatibility
        return true;
      }

      final permissions = metadata[PermissionConstants.permissionsKey] as Map<String, dynamic>?;
      if (permissions == null) {
        return true;
      }

      // Check if user is owner
      final ownerId = metadata[PermissionConstants.ownerIdKey] as String?;
      if (ownerId != null && ownerId == userId) {
        return true;
      }

      // Check user's permission level
      final userPermissionStr = permissions[userId] as String?;
      if (userPermissionStr == null) {
        return false;
      }

      final userPermission = PermissionLevel.fromJson(userPermissionStr);
      
      // Compare permission levels
      return _hasRequiredLevel(userPermission, requiredLevel);
    } catch (e, stackTrace) {
      logger.e('Failed to check permission', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Checks if a permission level meets the required level
  bool _hasRequiredLevel(PermissionLevel userLevel, PermissionLevel requiredLevel) {
    const levelOrder = [
      PermissionLevel.viewer,
      PermissionLevel.editor,
      PermissionLevel.owner,
    ];
    
    final userIndex = levelOrder.indexOf(userLevel);
    final requiredIndex = levelOrder.indexOf(requiredLevel);
    
    return userIndex >= requiredIndex;
  }

  /// Checks if the current user can edit the document
  Future<bool> canEdit(Map<String, dynamic> metadata) async {
    return await hasPermission(metadata, PermissionLevel.editor);
  }

  /// Checks if the current user can delete the document
  Future<bool> canDelete(Map<String, dynamic> metadata) async {
    return await hasPermission(metadata, PermissionLevel.owner);
  }

  /// Checks if the current user can manage permissions
  Future<bool> canManagePermissions(Map<String, dynamic> metadata) async {
    return await hasPermission(metadata, PermissionLevel.owner);
  }

  /// Gets the current user's permission level for a document
  Future<PermissionLevel?> getUserPermission(Map<String, dynamic> metadata) async {
    try {
      final userId = await _userIdentityService.getUserId();
      
      // Check if document has permissions field
      if (!metadata.containsKey(PermissionConstants.permissionsKey)) {
        // No permissions set - assume owner for backward compatibility
        return PermissionLevel.owner;
      }

      final permissions = metadata[PermissionConstants.permissionsKey] as Map<String, dynamic>?;
      if (permissions == null) {
        return PermissionLevel.owner;
      }

      // Check if user is owner
      final ownerId = metadata[PermissionConstants.ownerIdKey] as String?;
      if (ownerId != null && ownerId == userId) {
        return PermissionLevel.owner;
      }

      // Get user's permission level
      final userPermissionStr = permissions[userId] as String?;
      if (userPermissionStr == null) {
        return null;
      }

      return PermissionLevel.fromJson(userPermissionStr);
    } catch (e, stackTrace) {
      logger.e('Failed to get user permission', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Initializes permissions for a new document
  Future<Map<String, dynamic>> initializePermissions() async {
    try {
      final userId = await _userIdentityService.getUserId();
      
      return {
        PermissionConstants.ownerIdKey: userId,
        PermissionConstants.permissionsKey: {
          userId: PermissionLevel.owner.toJson(),
        },
        PermissionConstants.isLockedKey: false,
        PermissionConstants.lockedByKey: null,
      };
    } catch (e, stackTrace) {
      logger.e('Failed to initialize permissions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Updates permissions for a user
  Map<String, dynamic> updateUserPermission(
    Map<String, dynamic> metadata,
    String targetUserId,
    PermissionLevel level,
  ) {
    final permissions = Map<String, dynamic>.from(
      metadata[PermissionConstants.permissionsKey] as Map<String, dynamic>? ?? {}
    );
    
    permissions[targetUserId] = level.toJson();
    
    return {
      ...metadata,
      PermissionConstants.permissionsKey: permissions,
    };
  }

  /// Removes a user's permission
  Map<String, dynamic> removeUserPermission(
    Map<String, dynamic> metadata,
    String targetUserId,
  ) {
    final permissions = Map<String, dynamic>.from(
      metadata[PermissionConstants.permissionsKey] as Map<String, dynamic>? ?? {}
    );
    
    permissions.remove(targetUserId);
    
    return {
      ...metadata,
      PermissionConstants.permissionsKey: permissions,
    };
  }
}

/// Constants for permission-related fields
class PermissionConstants {
  static const String ownerIdKey = 'ownerId';
  static const String permissionsKey = 'permissions';
  static const String isLockedKey = 'isLocked';
  static const String lockedByKey = 'lockedBy';
}

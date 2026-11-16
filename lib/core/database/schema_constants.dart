class SchemaConstants {
  static const int databaseVersion = 3;
  static const String databaseName = 'find_my_stuff_ai.db';

  // Table Names
  static const String tableMemories = 'memories';
  static const String tableDetectedObjects = 'detected_objects';
  static const String tableItemIdentities = 'item_identities';
  static const String tableItemObservations = 'item_observations';
  static const String tableCollections = 'collections';
  static const String tableCollectionMemberships = 'collection_memberships';
  static const String tableEmbeddings = 'embeddings';
  static const String tableAppSettings = 'app_settings';
  static const String tableRoutines = 'routines';
  static const String tableRoutineItems = 'routine_items';
  static const String tableSearchFeedback = 'search_feedback';

  // Memories columns
  static const String colId = 'id';
  static const String colImagePath = 'image_path';
  static const String colThumbnailPath = 'thumbnail_path';
  static const String colCapturedAt = 'captured_at';
  static const String colCreatedAt = 'created_at';
  static const String colLocationLabel = 'location_label';
  static const String colNotes = 'notes';
  static const String colIndexingStatus = 'indexing_status';
  static const String colErrorMessage = 'error_message';

  // Detected Objects columns
  static const String colMemoryId = 'memory_id';
  static const String colLabel = 'label';
  static const String colConfidence = 'confidence';
  static const String colAttributes = 'attributes';
  static const String colBoundingBox = 'bounding_box';
  static const String colModelMetadata = 'model_metadata';

  // Item Identities columns
  static const String colName = 'name';
  static const String colCategory = 'category';
  static const String colDescription = 'description';
  static const String colReferencePhotoPath = 'reference_photo_path';
  static const String colReferenceObjectId = 'reference_object_id';
  static const String colLastObservedMemoryId = 'last_observed_memory_id';
  static const String colLastObservedAt = 'last_observed_at';
  static const String colLastObservedLocation = 'last_observed_location';
  static const String colStatus = 'status';

  // Item Observations columns
  static const String colItemId = 'item_id';
  static const String colDetectedObjectId = 'detected_object_id';
  static const String colObservedAt = 'observed_at';
  static const String colMatchConfidence = 'match_confidence';
  static const String colUserConfirmation = 'user_confirmation';
  static const String colManualLocationOverride = 'manual_location_override';

  // Collections columns
  static const String colIconName = 'icon_name';
  static const String colCollectionId = 'collection_id';

  // Embeddings columns
  static const String colVectorJson = 'vector_json';
  static const String colDimension = 'dimension';

  // App settings columns
  static const String colKey = 'key';
  static const String colValue = 'value';

  // Routine columns
  static const String colRoutineId = 'routine_id';
  static const String colRoutineCategory = 'routine_category';
  static const String colScheduledTime = 'scheduled_time';
  static const String colIsReminderEnabled = 'is_reminder_enabled';
  static const String colIsVerifiedPacked = 'is_verified_packed';
  static const String colLastVerifiedAt = 'last_verified_at';

  // Search Feedback columns
  static const String colQuery = 'query';
  static const String colMatchedObjectLabel = 'matched_object_label';
  static const String colIsPositive = 'is_positive';
}

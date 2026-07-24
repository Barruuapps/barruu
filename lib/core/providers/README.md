# Provider Registry

This directory contains centralized provider definitions for the Barruu application. Providers are organized by feature and follow clean architecture principles.

## Architecture

```text
Presentation Layer (Widgets)
      ↓ (reads from)
Providers (Dependency Injection)
      ↓ (creates)
Use Cases (Business Logic)
      ↓ (uses)
Repository Interfaces
      ↓ (implemented by)
Repository Implementations (Data Layer)
      ↓ (uses)
Data Sources (Local DB, API, etc.)
```text

## Provider Organization

### 1. **workspace_use_case_providers.dart**

Contains all providers related to workspace/document operations:

- Document repository provider
- Block CRUD use case providers
- Document metadata use case providers

## Usage Guidelines

### 1. Reading Providers in Widgets

Use `ref.watch()` for reactive updates:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch repository - rebuilds when repository changes
    final repository = ref.watch(documentRepositoryProvider(docDir));
    
    // Or watch use case - rebuilds when use case changes
    final useCase = ref.watch(getBlocksUseCaseProvider(docDir));
    
    return ...;
  }
}
```text

### 2. Reading Providers Once

Use `ref.read()` for one-time access (e.g., in event handlers):

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Read once - doesn't listen for changes
        final useCase = ref.read(createBlockUseCaseProvider(docDir));
        final result = await useCase(CreateBlockParams(block: newBlock));
        
        result.when(
          success: (blockId) => print('Created: $blockId'),
          error: (message) => showError(context, message),
        );
      },
      child: Text('Create Block'),
    );
  }
}
```text

### 3. Optimizing with Selectors

Use selectors to rebuild only when specific data changes:

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuilds when block count changes, not when blocks change
    final blockCount = ref.watch(
      blocksProvider.select((blocks) => blocks.length),
    );
    
    return Text('$blockCount blocks');
  }
}
```text

### 4. Testing with Providers

Override providers in tests:

```dart
testWidgets('should create block', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Override with mock repository
        documentRepositoryProvider(docDir).overrideWithValue(mockRepository),
      ],
      child: MyApp(),
    ),
  );
  
  // Test your widget...
});
```text

## Best Practices

### DO

- ✅ Use `ref.watch()` in build methods for reactive updates
- ✅ Use `ref.read()` in event handlers for one-time access
- ✅ Use selectors to optimize rebuilds
- ✅ Keep providers in centralized files by feature
- ✅ Document each provider with usage examples
- ✅ Use interfaces for loose coupling

### DON'T

- ❌ Use `ref.read()` in build methods (causes missed updates)
- ❌ Create circular dependencies between providers
- ❌ Put business logic in providers (use use cases)
- ❌ Mix presentation and data logic
- ❌ Create providers in widget files

## Provider Types

### 1. **Provider** - Immutable, cached values

```dart
final configProvider = Provider<Config>((ref) {
  return Config();
});
```text

### 2. **StateProvider** - Simple mutable state

```dart
final counterProvider = StateProvider<int>((ref) => 0);
```text

### 3. **StateNotifierProvider** - Complex state management

```dart
final todoListProvider = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  return TodoList();
});
```text

### 4. **FutureProvider** - Async data loading

```dart
final userProvider = FutureProvider<User>((ref) async {
  final repository = ref.watch(repositoryProvider);
  return await repository.getUser();
});
```text

### 5. **StreamProvider** - Stream data

```dart
final messagesProvider = StreamProvider<List<Message>>((ref) {
  final repository = ref.watch(repositoryProvider);
  return repository.watchMessages();
});
```text

## Dependency Graph

```text
workspace_use_case_providers.dart
├── documentRepositoryProvider
│   └── DocumentRepository (concrete)
│       └── implements IDocumentRepository (interface)
│
├── getBlocksUseCaseProvider
│   └── GetBlocksUseCase
│       └── uses documentRepositoryProvider
│
├── createBlockUseCaseProvider
│   └── CreateBlockUseCase
│       └── uses documentRepositoryProvider
│
├── updateBlockUseCaseProvider
│   └── UpdateBlockUseCase
│       └── uses documentRepositoryProvider
│
├── deleteBlockUseCaseProvider
│   └── DeleteBlockUseCase
│       └── uses documentRepositoryProvider
│
├── updateBlocksUseCaseProvider
│   └── UpdateBlocksUseCase
│       └── uses documentRepositoryProvider
│
└── getDocumentTagsUseCaseProvider
    └── GetDocumentTagsUseCase
        └── uses documentRepositoryProvider
```text

## Adding New Providers

When adding a new provider:

1. **Create the provider** in the appropriate feature file
1. **Document the provider** with usage examples
1. **Update this README** with the new provider
1. **Write tests** for the provider behavior
1. **Update dependency graph** if needed

Example:

```dart
/// Provider for [MyNewUseCase]
/// 
/// Used to perform specific business operation.
/// 
/// Example:
/// ```dart
/// final useCase = ref.read(myNewUseCaseProvider(param));
/// final result = await useCase(MyParams(...));
/// ```
final myNewUseCaseProvider = Provider.family<MyNewUseCase, Param>((ref, param) {
  final repository = ref.watch(repositoryProvider(param));
  return MyNewUseCase(repository);
});
```text

## Performance Considerations

1. **Use `.family` for parameterized providers** to avoid creating unnecessary instances
1. **Use `.autoDispose` for short-lived data** to free memory automatically
1. **Use selectors** to reduce rebuilds
1. **Keep provider scope minimal** - don't watch providers you don't need
1. **Profile your app** to identify provider-related performance issues

## Resources

- [Riverpod Documentation](https://riverpod.dev/)
- [Provider Best Practices](https://riverpod.dev/docs/concepts/providers)
- [Testing with Riverpod](https://riverpod.dev/docs/cookbooks/testing)

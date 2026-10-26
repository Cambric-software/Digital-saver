# Cambric architecture standard

## Hybrid structure

```
lib/
  core/          # config, storage, logging, security, lifecycle, network, updates, services
  features/      # screens, widgets, theme
  shared/        # design tokens, utils, helpers
  main.dart      # entry point
```

## Rules

- `core/` holds cross-cutting services.
- `features/` holds UI and feature logic.
- `shared/` holds reusable design and utilities.
- No deep nesting beyond 3 levels.
- Imports use package: prefix for shared code.
- Tests mirror lib structure under test/.
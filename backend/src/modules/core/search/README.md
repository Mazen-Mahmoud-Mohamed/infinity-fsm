# Global Search Module

Cross-module search service. Queries registered search providers in parallel.

## Endpoint

| Method | Path | Permission |
|--------|------|------------|
| GET | `/search` | `search:global` |

## Search Providers

Each module registers searchable entities:

```javascript
searchRegistry.register('overtime', {
  collection: 'overtime_records',
  textFields: ['jobDescription', 'completionNotes'],
  filters: ['status', 'type', 'userId', 'departmentId'],
  resultMapper: (doc) => ({ entity: 'overtime', title: doc.jobDescription, ... })
});
```

## Implementation Phases

- **MVP:** MongoDB text indexes + compound filters
- **Phase 2:** MongoDB Atlas Search or Elasticsearch

**Implementation:** Phase 4

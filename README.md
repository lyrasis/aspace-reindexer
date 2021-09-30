# ArchivesSpace Reindexer plugin

This plugin can be used in two ways:

1. On system startup to initiate a reindex
2. Via the api to trigger a reindex

TODO: consider running as a job and making it available that way too.

## On startup

- Set `AppConfig[:reindex_on_startup] = true` in `config.rb`
- Restart ArchivesSpace

## Via the api

```bash
curl -H "X-ArchivesSpace-Session: $SESSION" -X POST http://localhost:4567/plugins/reindex
```

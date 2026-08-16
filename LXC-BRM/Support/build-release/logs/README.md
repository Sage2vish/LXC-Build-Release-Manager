# Release Support Logs

This folder is reserved for logs produced by release-support work if the release process needs a checked-in or locally staged record.

The running app writes build output to the repository being built:

```text
<repository>/build/logs/build-YYYY-MM-DD-HH-MM-SS.log
```

The app can also export the current log to a user-selected location, normally Downloads. Do not confuse this support folder with a target repository's runtime log directory.

See [`../README.md`](../README.md) for the release flow and [the Support Handbook](../../README.md) for the full folder map.

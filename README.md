# Handkerchief framework

Handkerchief requires "Status" RemoteEvent to operate.

## Example usage with rojo

```json
  "$className": "DataModel",
  "ReplicatedStorage": {
   "Handkerchief": {
    "$path": "libs/Handkerchief/Src",
    "Status": {
     "$className": "RemoteEvent"
    }
   },
   "Handkerlib": {
    "$path": "libs/Handkerlib/Src"
   }
  },
```

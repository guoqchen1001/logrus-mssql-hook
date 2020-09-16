# Mssql Hook for [Logrus](https://github.com/sirupsen/logrus) 

Base from [gemnasium/logrus-postgresql-hook](https://github.com/gemnasium/logrus-postgresql-hook) 

Use this hook to send your logs to mssql server.

## Usage

The hook must be configured with:

* A mssql db connection (*`*sql.DB`)
* an optional hash with extra global fields. These fields will be included in all messages sent to mssql

```go
package main

import (
"database/sql"
"github.com/guoqchen1001/logrus-mssql-hook"
log "github.com/sirupsen/logrus"
    )

func main() {
    db, err := sql.Open("sqlserver", "sqlserver://username:password@server?database=database&encrypt=disable")
      if err != nil {
        t.Fatal("Can't connect to mssql database:", err)
      }
    defer db.Close()
    hook := mssqlogrus.NewHook(db, map[string]interface{}{"this": "is logged every time"})
    log.AddHook(hook)
    log.Info("some logging message")
}
```

### Asynchronous logger

This package provides an asynchronous hook, so logging won't block waiting for the data to be inserted in the DB.
Be careful to defer call `hook.Flush()` if you are using this kind of hook.


```go
package main

import (

"database/sql"
"github.com/guoqchen1001/logrus-mssql-hook"
log "github.com/sirupsen/logrus"
)

func main() {
    db, err := sql.Open("sqlserver", "sqlserver://username:password@server?database=database&encrypt=disable")
      if err != nil {
        t.Fatal("Can't connect to mssql database:", err)
      }
    defer db.Close()
    hook := mssqlogrus.NewAsyncHook(db, map[string]interface{}{"this": "is logged every time"})
    defer hook.Flush()
    log.AddHook(hook)
    log.Info("some logging message")
}
```


### Customize insertion

By defaults, the hook will log into a `logs` table (cf the test schema in `migrations`).
To change this behavior, set the `InsertFunc` of the hook:

```go
package main

import (
    "database/sql"
    "encoding/json"
    mssqlogrus "github.com/guoqchen1001/logrus-mssql-hook"
    log "github.com/sirupsen/logrus"
    )

func main() {
   db, err := sql.Open("sqlserver", "sqlserver://username:password@server?database=database&encrypt=disable")
      if err != nil {
        t.Fatal("Can't connect to mssql database:", err)
      }
    defer db.Close()

    hook := mssqlogrus.NewHook(db, map[string]interface{}{"this": "is logged every time"})
    hook.InsertFunc = func(db *sql.DB, entry *logrus.Entry) error {
      jsonData, err := json.Marshal(entry.Data)
        if err != nil {
          return err
        }

      _, err = db.Exec("INSERT INTO another_logs_table(level, message, message_data, created_at) VALUES ($1,$2,$3,$4);", entry.Level, entry.Message, jsonData, entry.Time)
        return err
    }
    log.AddHook(hook)
    log.Info("some logging message")

}
```

### Ignore entries

Entries can be completely ignored using a filter.
A filter a `func(*logrus.Entry) *logrus.Entry` that modifies or ignore the entry provided.


```go
package main

import (
    "database/sql"
log "github.com/sirupsen/logrus"
    "gopkg.in/gemnasium/logrus-postgresql-hook.v1"
    )

func main() {
    db, err := sql.Open("sqlserver", "sqlserver://username:password@server?database=database&encrypt=disable")
    if err != nil {
    t.Fatal("Can't connect to postgresql database:", err)
    }
    defer db.Close()
    hook := mssqlogrus.NewAsyncHook(db, map[string]interface{}{"this": "is logged every time"})
    defer hook.Flush()

    hook.AddFilter(func(entry *logrus.Entry) *logrus.Entry {
      if _, ok := entry.Data["ignore"]; ok {
        // ignore entry
        entry = nil
      }
      return entry
    })

    log.Hooks.Add(hook)
    log.Info("some logging message")
    log.WithField("ignore", "me").Info("This message will be ignored")
}
```


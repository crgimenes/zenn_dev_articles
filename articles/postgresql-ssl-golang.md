---
title: "GoでPostgreSQLにSSL接続する"
emoji: "🔒"
type: "tech"
topics: ["go", "postgresql", "ssl", "database"]
published: true
---

## Creating the certificate

First, let's create a test certificate. Of course, in production you should use a certificate issued by a recognized certificate authority.

The command below creates two files, `server.crt` and `server.key`, which we will use to configure [PostgreSQL](https://www.postgresql.org).

```bash
openssl req -new -x509 -days 365 -nodes -text -out server.crt \
  -keyout server.key -subj "/CN=example.com"
```

## Configuring PostgreSQL

Edit the postgresql.conf file to enable the SSL key.

```conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

Restart the service and test the connection with the following command:

```bash
psql "sslmode=require"
```

In the connection string, use `slmode=verify-full` instead of `sslmode=disable`. Since your certificate is not signed by a certificate authority, you will need to mark it as trusted in your operating system.

See the [PostgreSQL documentation](https://www.postgresql.org/docs/11/ssl-tcp.html) for more configuration examples.

## Example using Go

In the example below I used the Connect function from the [sqlx](https://github.com/jmoiron/sqlx) package, which opens the database and then pings the server. This way it immediately returns an error if it cannot establish a full connection to the database.

```golang
dbsource := "postgres://postgres:password@example.com/testdb?sslmode=verify-full"
conn, err := sqlx.Connect("postgres", dbsource)
if err != nil {
    fmt.Printf("error open db: %v\n", err)
    return
}
```

## Bonus

The main PostgreSQL operations using Go.

A simple table to run the examples against:

```sql
CREATE TABLE public.clients
(
    id integer NOT NULL DEFAULT nextval('clientes_id_seq'::regclass),
    name character varying(200),
    address text,
    CONSTRAINT clientes_pkey PRIMARY KEY (id)
);
```

```golang
package main

import (
    "fmt"

    "github.com/jmoiron/sqlx"
    _ "github.com/lib/pq"
)

func open(dbsource string) (db *sqlx.DB, err error) {
    db, err = sqlx.Open("postgres", dbsource)
    if err != nil {
        err = fmt.Errorf("error open db: %v", err)
        return
    }
    err = db.Ping()
    if err != nil {
        err = fmt.Errorf("error ping db: %v", err)
    }
    return
}

func main() {
    /**********************
     ** Open the database **
     **********************/

    //dbsource := "postgres://postgres:password@example.com/testdb?sslmode=verify-full"
    dbsource := "postgres://postgres@localhost/testdb?sslmode=disable"
    db, err := open(dbsource)
    if err != nil {
        fmt.Println(err)
        return
    }
    fmt.Println(db.DriverName())

    /************
     ** Insert **
     ************/

    /*
       In most cases you can use either
       Exec or Query, the difference is in the return value,
       Query is better suited for when you want
       to read returned rows.
    */

    // Simple insert
    // -=-=-=-=-=-=-

    sql := `INSERT INTO "clients" ("name","address") VALUES ($1,$2)`

    _, err = db.Exec(sql,
        "Tyrell Corporation",
        "TC Earth Headquarters")
    if err != nil {
        fmt.Println(err)
        return
    }

    // named insert
    // -=-=-=-=-=-=
    type client struct {
        Name    string `json:"name" db:"name"`
        Address string `json:"address" db:"address"`
    }

    namedSQL := `INSERT INTO "clients" ("name","address") VALUES (:name,:address)`

    _, err = db.NamedExec(namedSQL,
        client{
            Name:    "Cyberdyne Systems",
            Address: "2144 Kramer St",
        })
    if err != nil {
        fmt.Println(err)
        return
    }

    // named insert returning the ID
    // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    id := 0
    rows, err := db.NamedQuery(`INSERT INTO "clients" ("name","address") VALUES (:name,:address) RETURNING id`,
        client{
            Name:    "Umbrella Corporation",
            Address: "545 S Birdneck RD STE 202B Virginia Beach, VA 23451",
        })
    if err != nil {
        fmt.Println(err)
        return
    }
    for rows.Next() {
        err = rows.Scan(&id)
        if err != nil {
            fmt.Println(err)
            return
        }
        fmt.Println("id", id)
    }
    err = rows.Close()
    if err != nil {
        fmt.Println(err)
        return
    }

    // insert inside a transaction
    // -=-=-=-=-=-=-=-=-=-=-=-=-=-
    tx, err := db.Begin()
    if err != nil {
        fmt.Println(err)
        return
    }

    _, err = tx.Exec(sql,
        "OCP Omni Consumer Products",
        "Delta City (formerly Detroit)")
    if err != nil {
        fmt.Println(err)
        return
    }

    _, err = tx.Exec(sql,
        "Weyland-Yutani Corporation",
        "Weyland-Yutani Corporation HQ, Tokyo")
    if err != nil {
        fmt.Println(err)
        return
    }

    _, err = tx.Exec(sql,
        "GeneCo",
        "401 N. Boonville Avenue Springfield")
    if err != nil {
        fmt.Println(err)
        return
    }

    err = tx.Commit()
    if err != nil {
        fmt.Println(err)
        return
    }

    // insert using prepare
    // -=-=-=-=-=-=-=-=-=-=
    stmt, err := db.Prepare(sql)
    if err != nil {
        fmt.Println(err)
        return
    }

    _, err = stmt.Exec("Black Mesa", "Black Mesa, New Mexico, USA")
    if err != nil {
        fmt.Println(err)
        return
    }

    err = stmt.Close()
    if err != nil {
        fmt.Println(err)
        return
    }

    // MustExec (panics on error)
    // -=-=-=-=-=-=-=-=-=-=-=-=-=

    db.MustExec(sql,
        "League of Industrial Nations",
        "CON-AM 27, Io, Jupter")

    db.MustExec(sql,
        "Aperture Laboratories",
        "Upper Michigan, USA")

    /************
     ** Select **
     ************/

    sql = `select "name", "address" from "clients" order by name`

    // Simple select
    // -=-=-=-=-=-=-
    r, err := db.Query(sql)
    if err != nil {
        fmt.Println(err)
        return
    }

    // list := []client{}
    for r.Next() {
        c := client{}                     // new instance to hold the client
        err = r.Scan(&c.Name, &c.Address) // populate the new instance
        if err != nil {                   // check for errors
            fmt.Println(err)
            return
        }
        fmt.Println("Name...:", c.Name)
        fmt.Println("Address:", c.Address)
        fmt.Println("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
        // list = append(list, c)
    }
    err = r.Close()
    if err != nil {
        fmt.Println(err)
        return
    }

    // Select reading item by item with StructScan
    // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    rows, err = db.Queryx(sql)
    if err != nil {
        fmt.Println(err)
        return
    }

    // list := []client{}
    for rows.Next() {
        c := client{}             // new instance to hold the client
        err = rows.StructScan(&c) // populate the new instance
        if err != nil {           // check for errors
            fmt.Println(err)
            return
        }
        fmt.Println("Name...:", c.Name)
        fmt.Println("Address:", c.Address)
        fmt.Println("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
        // list = append(list, c)
    }
    err = rows.Close()
    if err != nil {
        fmt.Println(err)
        return
    }

    // Select reading every item at once with db.Select
    // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

    list := []client{}
    err = db.Select(&list, sql)
    if err != nil {
        fmt.Println(err)
        return
    }

    for k, v := range list {
        fmt.Println("Record.:", k+1) // not the id :D
        fmt.Println("Name...:", v.Name)
        fmt.Println("Address:", v.Address)
        fmt.Println("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
    }

    // Select reading a single item
    // -=-=-=-=-=-=-=-=-=-=-=-=-=-=

    // limit 1
    sql = `select "name", "address" from "clients" limit 1`
    c := client{}
    err = db.Get(&c, sql)
    if err != nil {
        fmt.Println(err)
        return
    }

    fmt.Println("Name...:", c.Name)
    fmt.Println("Address:", c.Address)
    fmt.Println("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")

    // count
    sql = `select count(*) from "clients"`
    count := 0
    err = db.Get(&count, sql)
    if err != nil {
        fmt.Println(err)
        return
    }

    fmt.Println("count:", count)
    fmt.Println("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")

    /***********
     ** Close **
     ***********/

    err = db.Close()
    if err != nil {
        fmt.Println(err)
        return
    }
}
```


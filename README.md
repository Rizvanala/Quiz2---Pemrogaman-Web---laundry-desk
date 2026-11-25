# Laundry Desk (JSP)

A website for a laundry business with three outlets in Surabaya, written with JSP for the EF234301 Web Programming (D) Quiz 2. It continues the Midterm project: the same laundry domain, database design and demo data, now rebuilt as JSP pages with a small Java model.

## What it does

| Code | Feature | Who |
|---|---|---|
| Auth | Register, login, logout | everyone |
| F1 | Customer list and search | staff |
| F2 | Add a customer | staff |
| F3 | Edit a customer | staff |
| F4 | Delete a customer (refused while the customer has bills) | staff |
| F5 | Price list | everyone |
| F6 | Take in a new bill (the server calculates the total) | staff |
| F7 | Move a bill forward: received, finished, collected (every change is logged) | staff |
| F8 | Bill detail, payments and balance | staff |
| F9 | My bills (a customer sees only their own bills) | customer |

Extra: a data model page (`/schema.jsp`) that reads the live database, and a light and dark theme with a toggle button.

## How it is built

- JSP pages with JSTL (`jakarta.tags.core`), a Java model class `Desk` and JDBC with SQLite.
- `Gate` is a servlet filter. It checks the CSRF token of every POST form and the role of the user for each page.
- Passwords use PBKDF2 (`Passwords.java`). Output is escaped with `c:out`.
- The database is created and filled by `Seed.java` every time the website starts, so it always starts with the same demo data.

## Run it with Docker

```bash
docker build -t laundry-desk .
docker run --rm -p 8080:8080 laundry-desk
```

Open http ://localhost:8080

Open Live : https://laundry-desk-lk03.onrender.com/

## Run the checks

```bash
python tests/acceptance_test.py            # needs the website running on port 8080
python docs/contrast.py                    # measures the color contrast of both themes
```

## Demo accounts

The password for all accounts is `password123`.

| Role | Email |
|---|---|
| Staff, Keputih Outlet | rina@laundrydesk.test |
| Staff, Gebang Outlet | dimas@laundrydesk.test |
| Staff, Manyar Outlet | hanif@laundrydesk.test |
| Customer | bayu@laundrydesk.test |

## Photo credits

Photos from Unsplash: hero photo by Yuncho, machines photo by Mathias Reding, folded laundry photo by Victor Volkov.

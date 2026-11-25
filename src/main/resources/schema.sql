CREATE TABLE outlets (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT NOT NULL,
    address TEXT NOT NULL,
    phone   TEXT NOT NULL
);

CREATE TABLE users (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    name      TEXT NOT NULL,
    email     TEXT NOT NULL UNIQUE,
    password  TEXT NOT NULL,
    role      TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('staff', 'customer')),
    outlet_id INTEGER REFERENCES outlets (id) ON DELETE RESTRICT
);

CREATE TABLE customers (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    code    TEXT NOT NULL UNIQUE,
    name    TEXT NOT NULL,
    phone   TEXT NOT NULL,
    address TEXT,
    user_id INTEGER UNIQUE REFERENCES users (id) ON DELETE RESTRICT
);

CREATE TABLE services (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    price       INTEGER NOT NULL CHECK (price > 0)
);

CREATE TABLE bills (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    code        TEXT NOT NULL UNIQUE,
    customer_id INTEGER NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    service_id  INTEGER NOT NULL REFERENCES services (id) ON DELETE RESTRICT,
    outlet_id   INTEGER NOT NULL REFERENCES outlets (id) ON DELETE RESTRICT,
    user_id     INTEGER NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    arrived_at  TEXT NOT NULL,
    unit        INTEGER NOT NULL CHECK (unit BETWEEN 1 AND 100),
    total       INTEGER NOT NULL CHECK (total > 0),
    status      TEXT NOT NULL DEFAULT 'received' CHECK (status IN ('received', 'finished', 'collected', 'cancelled'))
);

CREATE TABLE payments (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_id INTEGER NOT NULL REFERENCES bills (id) ON DELETE RESTRICT,
    user_id INTEGER NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    amount  INTEGER NOT NULL CHECK (amount > 0),
    paid_at TEXT NOT NULL
);

CREATE TABLE status_logs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    bill_id    INTEGER NOT NULL REFERENCES bills (id) ON DELETE RESTRICT,
    user_id    INTEGER NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    status     TEXT NOT NULL,
    changed_at TEXT NOT NULL
);

CREATE INDEX idx_bills_customer ON bills (customer_id);
CREATE INDEX idx_bills_status ON bills (status);
CREATE INDEX idx_payments_bill ON payments (bill_id);
CREATE INDEX idx_logs_bill ON status_logs (bill_id);

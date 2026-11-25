package laundry.desk;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class Desk {

    public static final String PHONE = "^[0-9+\\- ]{6,30}$";
    public static final int PER_PAGE = 10;
    private static final List<String> STATUSES = List.of("received", "finished", "collected", "cancelled");

    private Desk() {
    }

    private static String clean(String text) {
        return text == null ? "" : text.trim();
    }

    private static long num(Object value) {
        return value == null ? 0 : ((Number) value).longValue();
    }

    private static String like(String q) {
        return "%" + q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_") + "%";
    }

    private static Page paged(String select, String from, String order, int page, Object... args) {
        long total = Db.count("SELECT COUNT(*) " + from, args);
        int pages = (int) Math.max(1, (total + PER_PAGE - 1) / PER_PAGE);
        int current = Math.min(Math.max(page, 1), pages);
        Object[] all = java.util.Arrays.copyOf(args, args.length + 2);
        all[args.length] = PER_PAGE;
        all[args.length + 1] = (current - 1) * PER_PAGE;
        List<Map<String, Object>> rows = Db.query(select + " " + from + " " + order + " LIMIT ? OFFSET ?", all);
        return new Page(rows, current, pages, total);
    }

    // ---------- accounts

    public static Map<String, Object> login(String email, String password) {
        Map<String, Object> user = Db.one(
                "SELECT id, name, email, password, role, outlet_id FROM users WHERE email = ?",
                clean(email).toLowerCase());
        if (user == null || !Passwords.verify(password, (String) user.get("password"))) {
            return null;
        }
        user.remove("password");
        return user;
    }

    public static Map<String, String> register(String name, String email, String phone, String password, String again) {
        final String n = clean(name);
        final String mail = clean(email).toLowerCase();
        final String tel = clean(phone);
        Map<String, String> errors = new LinkedHashMap<>();
        if (n.isEmpty()) {
            errors.put("name", "The name is required.");
        } else if (n.length() > 50) {
            errors.put("name", "The name can have 50 characters at most.");
        }
        if (!mail.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$") || mail.length() > 255) {
            errors.put("email", "Enter a valid email address.");
        } else if (Db.one("SELECT id FROM users WHERE email = ?", mail) != null) {
            errors.put("email", "This email is already registered.");
        }
        if (!tel.matches(PHONE)) {
            errors.put("phone", "Use digits, plus, minus and spaces only (6 to 30 characters).");
        }
        if (password == null || password.length() < 8) {
            errors.put("password", "The password needs at least 8 characters.");
        } else if (!password.equals(again)) {
            errors.put("password_again", "The two passwords are not the same.");
        }
        if (!errors.isEmpty()) {
            return errors;
        }
        final String hash = Passwords.hash(password);
        Db.tx(c -> {
            long userId = Db.insert(c, "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'customer')",
                    n, mail, hash);
            long id = Db.insert(c, "INSERT INTO customers (code, name, phone, user_id) VALUES (?, ?, ?, ?)",
                    "tmp" + System.nanoTime(), n, tel, userId);
            Db.exec(c, "UPDATE customers SET code = ? WHERE id = ?", String.format("C%04d", id), id);
        });
        return errors;
    }

    // ---------- customers (F1 to F4)

    public static Page customers(String q, int page) {
        String where = q.isEmpty() ? "" : "WHERE c.name LIKE ? ESCAPE '\\' OR c.code LIKE ? ESCAPE '\\' OR c.phone LIKE ? ESCAPE '\\'";
        Object[] args = q.isEmpty() ? new Object[0] : new Object[]{like(q), like(q), like(q)};
        return paged(
                "SELECT c.id, c.code, c.name, c.phone, c.address, (SELECT COUNT(*) FROM bills b WHERE b.customer_id = c.id) AS bills",
                "FROM customers c " + where,
                "ORDER BY c.name COLLATE NOCASE, c.id",
                page, args);
    }

    public static List<Map<String, Object>> allCustomers() {
        return Db.query("SELECT id, code, name FROM customers ORDER BY name COLLATE NOCASE, id");
    }

    public static Map<String, Object> customer(long id) {
        return Db.one("SELECT id, code, name, phone, address, user_id FROM customers WHERE id = ?", id);
    }

    public static Map<String, String> checkCustomer(String name, String phone, String address) {
        Map<String, String> errors = new LinkedHashMap<>();
        if (clean(name).isEmpty()) {
            errors.put("name", "The name is required.");
        } else if (clean(name).length() > 50) {
            errors.put("name", "The name can have 50 characters at most.");
        }
        if (!clean(phone).matches(PHONE)) {
            errors.put("phone", "Use digits, plus, minus and spaces only (6 to 30 characters).");
        }
        if (clean(address).length() > 120) {
            errors.put("address", "The address can have 120 characters at most.");
        }
        return errors;
    }

    public static String addCustomer(String name, String phone, String address) {
        final String[] code = new String[1];
        Db.tx(c -> {
            long id = Db.insert(c, "INSERT INTO customers (code, name, phone, address) VALUES (?, ?, ?, ?)",
                    "tmp" + System.nanoTime(), clean(name), clean(phone), clean(address).isEmpty() ? null : clean(address));
            code[0] = String.format("C%04d", id);
            Db.exec(c, "UPDATE customers SET code = ? WHERE id = ?", code[0], id);
        });
        return code[0];
    }

    public static void updateCustomer(long id, String name, String phone, String address) {
        Db.tx(c -> Db.exec(c, "UPDATE customers SET name = ?, phone = ?, address = ? WHERE id = ?",
                clean(name), clean(phone), clean(address).isEmpty() ? null : clean(address), id));
    }

    public static Outcome deleteCustomer(long id) {
        Map<String, Object> customer = customer(id);
        if (customer == null) {
            return Outcome.bad("That customer does not exist any more.");
        }
        long bills = Db.count("SELECT COUNT(*) FROM bills WHERE customer_id = ?", id);
        if (bills > 0) {
            return Outcome.bad(customer.get("name") + " cannot be deleted because they still have " + bills + " bill(s).");
        }
        final Object userId = customer.get("user_id");
        Db.tx(c -> {
            Db.exec(c, "DELETE FROM customers WHERE id = ?", id);
            if (userId != null) {
                Db.exec(c, "DELETE FROM users WHERE id = ?", userId);
            }
        });
        return Outcome.good("Customer " + customer.get("code") + " was deleted.");
    }

    // ---------- services and outlets (F5)

    public static List<Map<String, Object>> services() {
        return Db.query("SELECT id, code, description, price FROM services ORDER BY code");
    }

    public static List<Map<String, Object>> outlets() {
        return Db.query("SELECT id, name, address, phone FROM outlets ORDER BY id");
    }

    public static Map<String, Object> outlet(Object id) {
        return id == null ? null : Db.one("SELECT id, name, address, phone FROM outlets WHERE id = ?", id);
    }

    // ---------- bills (F6 to F8)

    private static final String BILL_ROWS =
            "SELECT b.id, b.code, b.total, b.status, b.arrived_at, c.name AS customer, s.description AS service, o.name AS outlet, "
            + "b.total - COALESCE((SELECT SUM(p.amount) FROM payments p WHERE p.bill_id = b.id), 0) AS balance ";

    public static Page bills(String status, int page) {
        boolean filter = STATUSES.contains(status);
        return paged(BILL_ROWS,
                "FROM bills b JOIN customers c ON c.id = b.customer_id JOIN services s ON s.id = b.service_id "
                        + "JOIN outlets o ON o.id = b.outlet_id " + (filter ? "WHERE b.status = ?" : ""),
                "ORDER BY b.arrived_at DESC, b.id DESC",
                page, filter ? new Object[]{status} : new Object[0]);
    }

    public static Map<String, Object> newBill(String customerId, String serviceId, String unit,
                                              Map<String, Object> staff, Map<String, String> errors) {
        long customer = -1;
        long service = -1;
        int amount = 0;
        try {
            customer = Long.parseLong(clean(customerId));
        } catch (NumberFormatException e) {
            // handled below
        }
        try {
            service = Long.parseLong(clean(serviceId));
        } catch (NumberFormatException e) {
            // handled below
        }
        try {
            amount = Integer.parseInt(clean(unit));
        } catch (NumberFormatException e) {
            // handled below
        }
        Map<String, Object> customerRow = customer(customer);
        Map<String, Object> serviceRow = Db.one("SELECT id, price FROM services WHERE id = ?", service);
        if (customerRow == null) {
            errors.put("customer_id", "Choose a customer from the list.");
        }
        if (serviceRow == null) {
            errors.put("service_id", "Choose a service from the list.");
        }
        if (amount < 1 || amount > 100) {
            errors.put("unit", "The quantity must be a whole number from 1 to 100.");
        }
        if (staff.get("outlet_id") == null) {
            errors.put("outlet", "Your account is not linked to an outlet.");
        }
        if (!errors.isEmpty()) {
            return null;
        }
        final long staffId = num(staff.get("id"));
        final long outletId = num(staff.get("outlet_id"));
        final long customerId2 = customer;
        final long serviceId2 = service;
        final int quantity = amount;
        final long total = num(serviceRow.get("price")) * amount;
        final Map<String, Object> made = new LinkedHashMap<>();
        Db.tx(c -> {
            String now = Web.now();
            long id = Db.insert(c,
                    "INSERT INTO bills (code, customer_id, service_id, outlet_id, user_id, arrived_at, unit, total, status) "
                            + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'received')",
                    "tmp" + System.nanoTime(), customerId2, serviceId2, outletId, staffId, now, quantity, total);
            String code = String.format("B%04d", id);
            Db.exec(c, "UPDATE bills SET code = ? WHERE id = ?", code, id);
            Db.exec(c, "INSERT INTO status_logs (bill_id, user_id, status, changed_at) VALUES (?, ?, 'received', ?)",
                    id, staffId, now);
            made.put("id", id);
            made.put("code", code);
        });
        return made;
    }

    public static Map<String, Object> bill(long id) {
        Map<String, Object> head = Db.one(
                "SELECT b.id, b.code, b.unit, b.total, b.status, b.arrived_at, c.name AS customer, c.code AS customer_code, "
                        + "s.description AS service, o.name AS outlet, u.name AS clerk "
                        + "FROM bills b JOIN customers c ON c.id = b.customer_id JOIN services s ON s.id = b.service_id "
                        + "JOIN outlets o ON o.id = b.outlet_id JOIN users u ON u.id = b.user_id WHERE b.id = ?", id);
        if (head == null) {
            return null;
        }
        List<Map<String, Object>> payments = Db.query(
                "SELECT p.amount, p.paid_at, u.name AS clerk FROM payments p JOIN users u ON u.id = p.user_id "
                        + "WHERE p.bill_id = ? ORDER BY p.paid_at, p.id", id);
        List<Map<String, Object>> logs = Db.query(
                "SELECT l.status, l.changed_at, u.name AS clerk FROM status_logs l JOIN users u ON u.id = l.user_id "
                        + "WHERE l.bill_id = ? ORDER BY l.changed_at, l.id", id);
        long paid = 0;
        for (Map<String, Object> p : payments) {
            paid += num(p.get("amount"));
        }
        String status = (String) head.get("status");
        Map<String, Object> view = new LinkedHashMap<>();
        view.put("bill", head);
        view.put("payments", payments);
        view.put("logs", logs);
        view.put("paid", paid);
        view.put("balance", num(head.get("total")) - paid);
        view.put("next", nextStatus(status));
        return view;
    }

    public static String nextStatus(String status) {
        if ("received".equals(status)) {
            return "finished";
        }
        if ("finished".equals(status)) {
            return "collected";
        }
        return null;
    }

    public static Outcome advance(long billId, long staffId) {
        Map<String, Object> bill = Db.one("SELECT code, status FROM bills WHERE id = ?", billId);
        if (bill == null) {
            return Outcome.bad("That bill does not exist.");
        }
        String next = nextStatus((String) bill.get("status"));
        if (next == null) {
            return Outcome.bad("Bill " + bill.get("code") + " is already " + bill.get("status") + " and cannot move on.");
        }
        Db.tx(c -> {
            Db.exec(c, "UPDATE bills SET status = ? WHERE id = ?", next, billId);
            Db.exec(c, "INSERT INTO status_logs (bill_id, user_id, status, changed_at) VALUES (?, ?, ?, ?)",
                    billId, staffId, next, Web.now());
        });
        return Outcome.good("Bill " + bill.get("code") + " is now " + next + ".");
    }

    public static Outcome pay(long billId, long staffId, String amountText) {
        Map<String, Object> view = bill(billId);
        if (view == null) {
            return Outcome.bad("That bill does not exist.");
        }
        Map<String, Object> bill = (Map<String, Object>) view.get("bill");
        if ("cancelled".equals(bill.get("status"))) {
            return Outcome.bad("A cancelled bill cannot receive payments.");
        }
        long amount;
        try {
            amount = Long.parseLong(clean(amountText));
        } catch (NumberFormatException e) {
            return Outcome.bad("Enter the payment as a whole number of rupiah.");
        }
        if (amount < 1) {
            return Outcome.bad("The payment must be at least Rp 1.");
        }
        long balance = (Long) view.get("balance");
        if (amount > balance) {
            return Outcome.bad("The amount is more than the remaining balance.");
        }
        Db.tx(c -> Db.exec(c, "INSERT INTO payments (bill_id, user_id, amount, paid_at) VALUES (?, ?, ?, ?)",
                billId, staffId, amount, Web.now()));
        return Outcome.good("Payment was recorded.");
    }

    // ---------- customer view (F9)

    public static Map<String, Object> myBills(long userId) {
        Map<String, Object> customer = Db.one("SELECT id, code, name, phone FROM customers WHERE user_id = ?", userId);
        Map<String, Object> view = new LinkedHashMap<>();
        view.put("customer", customer);
        if (customer == null) {
            view.put("bills", new ArrayList<Map<String, Object>>());
            view.put("outstanding", 0L);
            return view;
        }
        List<Map<String, Object>> rows = Db.query(BILL_ROWS
                + "FROM bills b JOIN customers c ON c.id = b.customer_id JOIN services s ON s.id = b.service_id "
                + "JOIN outlets o ON o.id = b.outlet_id WHERE b.customer_id = ? ORDER BY b.arrived_at DESC, b.id DESC",
                customer.get("id"));
        long outstanding = 0;
        for (Map<String, Object> row : rows) {
            if (!"cancelled".equals(row.get("status"))) {
                outstanding += num(row.get("balance"));
            }
        }
        view.put("bills", rows);
        view.put("outstanding", outstanding);
        return view;
    }

    // ---------- data model page

    public static List<Map<String, Object>> dataModel() {
        List<Map<String, Object>> out = new ArrayList<>();
        try (java.sql.Connection c = Db.open()) {
            List<Map<String, Object>> tables = Db.query(c,
                    "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY rowid");
            for (Map<String, Object> t : tables) {
                String name = (String) t.get("name");
                Map<String, Object> entry = new LinkedHashMap<>();
                entry.put("name", name);
                entry.put("rows", Db.query(c, "SELECT COUNT(*) AS n FROM " + name).get(0).get("n"));
                entry.put("columns", Db.query(c, "PRAGMA table_info(" + name + ")"));
                entry.put("keys", Db.query(c, "PRAGMA foreign_key_list(" + name + ")"));
                out.add(entry);
            }
        } catch (java.sql.SQLException e) {
            throw new IllegalStateException(e);
        }
        return out;
    }
}

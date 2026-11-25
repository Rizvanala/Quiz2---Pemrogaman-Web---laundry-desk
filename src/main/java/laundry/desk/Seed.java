package laundry.desk;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class Seed {

    private static final String[] NAMES = {
        "Bayu Santoso", "Anisa Putri", "Rizky Pratama", "Salsa Maharani", "Fajar Nugroho",
        "Dewi Lestari", "Hendra Wijaya", "Nadia Safitri", "Yoga Permana", "Citra Ayu",
        "Galih Setiawan", "Intan Permata", "Teguh Hidayat", "Melati Kusuma", "Arif Rahman",
        "Wulan Sari", "Bagas Saputra", "Laras Ningrum", "Doni Firmansyah", "Tiara Anggraini"
    };

    private static final Object[][] SERVICES = {
        {"Wash and fold (per kg)", 8000},
        {"Wash, dry and iron (per kg)", 12000},
        {"Ironing only (per kg)", 6000},
        {"Express 6-hour wash and fold (per kg)", 15000},
        {"Bed cover (per piece)", 35000},
        {"Blanket (per piece)", 30000},
        {"Suit, two pieces (per set)", 45000},
        {"Shoe cleaning (per pair)", 40000}
    };

    private Seed() {
    }

    public static void reset() throws IOException, SQLException {
        Path file = Path.of(Db.path());
        if (file.getParent() != null) {
            Files.createDirectories(file.getParent());
        }
        Files.deleteIfExists(file);
        try (Connection c = Db.open(); InputStream in = Seed.class.getResourceAsStream("/schema.sql")) {
            Db.script(c, new String(in.readAllBytes(), StandardCharsets.UTF_8));
        }
        fill();
    }

    private static void fill() {
        final String password = Passwords.hash("password123");
        Db.tx(c -> {
            String[][] outlets = {
                {"Keputih Outlet", "Jl. Keputih Tegal No. 12, Surabaya", "031-5990121"},
                {"Gebang Outlet", "Jl. Gebang Putih No. 8, Surabaya", "031-5990122"},
                {"Manyar Outlet", "Jl. Manyar Kertoarjo No. 31, Surabaya", "031-5990123"}
            };
            long[] outletIds = new long[3];
            for (int i = 0; i < 3; i++) {
                outletIds[i] = Db.insert(c, "INSERT INTO outlets (name, address, phone) VALUES (?, ?, ?)",
                        outlets[i][0], outlets[i][1], outlets[i][2]);
            }

            String[][] staff = {
                {"Rina Wulandari", "rina@laundrydesk.test"},
                {"Dimas Prakoso", "dimas@laundrydesk.test"},
                {"Hanif Maulana", "hanif@laundrydesk.test"}
            };
            long[] staffIds = new long[3];
            for (int i = 0; i < 3; i++) {
                staffIds[i] = Db.insert(c, "INSERT INTO users (name, email, password, role, outlet_id) VALUES (?, ?, ?, 'staff', ?)",
                        staff[i][0], staff[i][1], password, outletIds[i]);
            }
            long bayuUser = Db.insert(c, "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, 'customer')",
                    "Bayu Santoso", "bayu@laundrydesk.test", password);

            long[] serviceIds = new long[SERVICES.length];
            int[] prices = new int[SERVICES.length];
            for (int i = 0; i < SERVICES.length; i++) {
                prices[i] = (Integer) SERVICES[i][1];
                serviceIds[i] = Db.insert(c, "INSERT INTO services (code, description, price) VALUES (?, ?, ?)",
                        String.format("S%04d", i + 1), SERVICES[i][0], prices[i]);
            }

            long[] customerIds = new long[NAMES.length];
            for (int i = 0; i < NAMES.length; i++) {
                customerIds[i] = Db.insert(c, "INSERT INTO customers (code, name, phone, address, user_id) VALUES (?, ?, ?, 'Surabaya', ?)",
                        String.format("C%04d", i + 1), NAMES[i], String.format("0812%08d", 31000000 + (i + 1) * 7919),
                        i == 0 ? (Object) bayuUser : null);
            }

            LocalDateTime now = LocalDateTime.now(Web.ZONE);
            for (int i = 1; i <= 30; i++) {
                int customer = i % NAMES.length;
                int service = i % SERVICES.length;
                int slot = i % 3;
                int unit = 1 + (i * 3) % 6;
                long total = (long) prices[service] * unit;
                LocalDateTime arrived = now.minusDays(31 - i).withHour(8 + i % 9).withMinute(15).withSecond(0).withNano(0);

                String status;
                switch (i % 4) {
                    case 0, 3 -> status = "collected";
                    case 1 -> status = "received";
                    default -> status = "finished";
                }
                if (i == 7) {
                    status = "cancelled";
                }

                long bill = Db.insert(c,
                        "INSERT INTO bills (code, customer_id, service_id, outlet_id, user_id, arrived_at, unit, total, status) "
                                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        String.format("B%04d", i), customerIds[customer], serviceIds[service], outletIds[slot], staffIds[slot],
                        Web.stamp(arrived), unit, total, status);

                String[] steps;
                switch (status) {
                    case "collected" -> steps = new String[]{"received", "finished", "collected"};
                    case "finished" -> steps = new String[]{"received", "finished"};
                    case "cancelled" -> steps = new String[]{"received", "cancelled"};
                    default -> steps = new String[]{"received"};
                }
                for (int s = 0; s < steps.length; s++) {
                    Db.exec(c, "INSERT INTO status_logs (bill_id, user_id, status, changed_at) VALUES (?, ?, ?, ?)",
                            bill, staffIds[slot], steps[s], Web.stamp(arrived.plusHours(s * 6L)));
                }

                long paid = 0;
                if (status.equals("collected")) {
                    paid = total;
                } else if (status.equals("finished")) {
                    paid = Math.round(total / 2.0);
                } else if (status.equals("received") && i % 3 == 0) {
                    paid = Math.round(total * 0.3);
                }
                if (paid > 0) {
                    Db.exec(c, "INSERT INTO payments (bill_id, user_id, amount, paid_at) VALUES (?, ?, ?, ?)",
                            bill, staffIds[slot], paid, Web.stamp(arrived.plusHours(6)));
                }
            }
        });
    }
}

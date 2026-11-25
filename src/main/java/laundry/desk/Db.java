package laundry.desk;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class Db {

    static {
        try {
            Class.forName("org.sqlite.JDBC");
        } catch (ClassNotFoundException e) {
            throw new IllegalStateException("SQLite driver is missing", e);
        }
    }

    private Db() {
    }

    public interface Work {
        void run(Connection c) throws SQLException;
    }

    public static String path() {
        String p = System.getenv("DB_PATH");
        if (p == null || p.isBlank()) {
            p = System.getProperty("java.io.tmpdir") + java.io.File.separator + "laundry-desk.db";
        }
        return p;
    }

    public static Connection open() throws SQLException {
        Connection c = DriverManager.getConnection("jdbc:sqlite:" + path());
        try (Statement s = c.createStatement()) {
            s.execute("PRAGMA foreign_keys = ON");
            s.execute("PRAGMA busy_timeout = 5000");
        }
        return c;
    }

    private static void bind(PreparedStatement ps, Object[] params) throws SQLException {
        for (int i = 0; i < params.length; i++) {
            ps.setObject(i + 1, params[i]);
        }
    }

    public static List<Map<String, Object>> query(Connection c, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            bind(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                ResultSetMetaData md = rs.getMetaData();
                List<Map<String, Object>> rows = new ArrayList<>();
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= md.getColumnCount(); i++) {
                        row.put(md.getColumnLabel(i), rs.getObject(i));
                    }
                    rows.add(row);
                }
                return rows;
            }
        }
    }

    public static List<Map<String, Object>> query(String sql, Object... params) {
        try (Connection c = open()) {
            return query(c, sql, params);
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    public static Map<String, Object> one(String sql, Object... params) {
        List<Map<String, Object>> rows = query(sql, params);
        return rows.isEmpty() ? null : rows.get(0);
    }

    public static long count(String sql, Object... params) {
        Map<String, Object> row = one(sql, params);
        return ((Number) row.values().iterator().next()).longValue();
    }

    public static int exec(Connection c, String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = c.prepareStatement(sql)) {
            bind(ps, params);
            return ps.executeUpdate();
        }
    }

    public static long insert(Connection c, String sql, Object... params) throws SQLException {
        exec(c, sql, params);
        List<Map<String, Object>> rows = query(c, "SELECT last_insert_rowid() AS id");
        return ((Number) rows.get(0).get("id")).longValue();
    }

    public static void tx(Work work) {
        try (Connection c = open()) {
            c.setAutoCommit(false);
            try {
                work.run(c);
                c.commit();
            } catch (SQLException | RuntimeException e) {
                c.rollback();
                throw e;
            }
        } catch (SQLException e) {
            throw new IllegalStateException(e);
        }
    }

    public static void script(Connection c, String sql) throws SQLException {
        try (Statement s = c.createStatement()) {
            for (String part : sql.split(";")) {
                if (!part.isBlank()) {
                    s.execute(part);
                }
            }
        }
    }
}

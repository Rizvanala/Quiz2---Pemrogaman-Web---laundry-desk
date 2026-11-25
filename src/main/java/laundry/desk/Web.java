package laundry.desk;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;

public final class Web {

    public static final ZoneId ZONE = ZoneId.of("Asia/Jakarta");
    private static final DateTimeFormatter STAMP = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    private Web() {
    }

    public static String now() {
        return LocalDateTime.now(ZONE).format(STAMP);
    }

    public static String stamp(LocalDateTime time) {
        return time.format(STAMP);
    }

    public static String param(HttpServletRequest request, String name) {
        String value = request.getParameter(name);
        return value == null ? "" : value;
    }

    public static long longParam(HttpServletRequest request, String name, long fallback) {
        try {
            return Long.parseLong(param(request, name).trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    public static int intParam(HttpServletRequest request, String name, int fallback) {
        try {
            return Integer.parseInt(param(request, name).trim());
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    public static void flash(HttpSession session, String type, String message) {
        session.setAttribute("flash_type", type);
        session.setAttribute("flash_msg", message);
    }

    public static void go(HttpServletRequest request, HttpServletResponse response, String path) throws IOException {
        response.sendRedirect(request.getContextPath() + path);
    }

    public static String qs(String... pairs) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i + 1 < pairs.length; i += 2) {
            if (pairs[i + 1] != null && !pairs[i + 1].isEmpty()) {
                sb.append('&').append(pairs[i]).append('=')
                  .append(URLEncoder.encode(pairs[i + 1], StandardCharsets.UTF_8));
            }
        }
        return sb.toString();
    }
}

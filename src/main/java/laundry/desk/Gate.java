package laundry.desk;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Map;
import java.util.Set;

@WebFilter("/*")
public class Gate implements Filter {

    private static final Set<String> STAFF_PAGES = Set.of(
            "/customers.jsp", "/customer-form.jsp", "/customer-delete.jsp",
            "/bills.jsp", "/bill-new.jsp", "/bill.jsp", "/bill-advance.jsp", "/bill-pay.jsp");
    private static final Set<String> CUSTOMER_PAGES = Set.of("/my-bills.jsp");
    private static final Set<String> GUEST_PAGES = Set.of("/login.jsp", "/register.jsp");
    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        String path = request.getServletPath();

        boolean isPage = path.equals("/") || path.endsWith(".jsp");
        if (!isPage) {
            chain.doFilter(req, res);
            return;
        }

        HttpSession session = request.getSession(true);
        if (session.getAttribute("csrf") == null) {
            byte[] bytes = new byte[24];
            RANDOM.nextBytes(bytes);
            session.setAttribute("csrf", Base64.getUrlEncoder().withoutPadding().encodeToString(bytes));
        }

        Object flashMessage = session.getAttribute("flash_msg");
        if (flashMessage != null) {
            request.setAttribute("flash_msg", flashMessage);
            request.setAttribute("flash_type", session.getAttribute("flash_type"));
            session.removeAttribute("flash_msg");
            session.removeAttribute("flash_type");
        }

        if ("POST".equals(request.getMethod())) {
            String sent = request.getParameter("_csrf");
            if (sent == null || !sent.equals(session.getAttribute("csrf"))) {
                response.sendError(403, "The form has expired. Go back, reload the page and try again.");
                return;
            }
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        String role = user == null ? null : (String) user.get("role");

        if (STAFF_PAGES.contains(path) || CUSTOMER_PAGES.contains(path)) {
            if (user == null) {
                Web.flash(session, "error", "Please log in first.");
                Web.go(request, response, "/login.jsp");
                return;
            }
            if (STAFF_PAGES.contains(path) && !"staff".equals(role)) {
                response.sendError(403, "This page is for staff only.");
                return;
            }
            if (CUSTOMER_PAGES.contains(path) && !"customer".equals(role)) {
                response.sendError(403, "This page is for customers only.");
                return;
            }
        }
        if (GUEST_PAGES.contains(path) && user != null) {
            Web.go(request, response, "staff".equals(role) ? "/bills.jsp" : "/my-bills.jsp");
            return;
        }

        chain.doFilter(req, res);
    }
}

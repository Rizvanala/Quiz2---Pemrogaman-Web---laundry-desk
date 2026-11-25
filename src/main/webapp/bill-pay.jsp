<%
    long id = Web.longParam(request, "id", -1);
    if ("POST".equals(request.getMethod())) {
        Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
        Outcome result = Desk.pay(id, ((Number) user.get("id")).longValue(), Web.param(request, "amount"));
        Web.flash(session, result.ok ? "ok" : "error", result.message);
    }
    Web.go(request, response, "/bill.jsp?id=" + id);
%>

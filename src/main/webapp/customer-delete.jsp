<%
    if ("POST".equals(request.getMethod())) {
        Outcome result = Desk.deleteCustomer(Web.longParam(request, "id", -1));
        Web.flash(session, result.ok ? "ok" : "error", result.message);
    }
    Web.go(request, response, "/customers.jsp");
%>

<%
    if ("POST".equals(request.getMethod())) {
        session.invalidate();
        Web.flash(request.getSession(true), "ok", "You are logged out.");
    }
    Web.go(request, response, "/index.jsp");
%>

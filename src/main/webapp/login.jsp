<%
    Map<String, String> errors = new LinkedHashMap<>();
    String email = Web.param(request, "email").trim();
    if ("POST".equals(request.getMethod())) {
        Map<String, Object> user = Desk.login(email, Web.param(request, "password"));
        if (user == null) {
            errors.put("email", "Email or password is incorrect.");
        } else {
            request.changeSessionId();
            session.setAttribute("user", user);
            Web.go(request, response, "staff".equals(user.get("role")) ? "/bills.jsp" : "/my-bills.jsp");
            return;
        }
    }
    request.setAttribute("errors", errors);
    request.setAttribute("email", email);
%>
<c:set var="title" value="Login"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="auth-box panel">
  <h1>Login</h1>
  <p class="muted">Staff and customers use the same form.</p>
  <form class="form" method="post" action="${ctx}/login.jsp">
    <ld:csrf/>
    <label for="email">Email</label>
    <input id="email" type="email" name="email" value="<c:out value='${email}'/>" required autofocus>
    <c:if test="${not empty errors.email}"><p class="field-error"><c:out value="${errors.email}"/></p></c:if>
    <label for="password">Password</label>
    <input id="password" type="password" name="password" required>
    <div class="form-actions"><button class="btn" type="submit">Login</button></div>
  </form>
  <p class="muted" style="margin-top:1rem">No account yet? <a href="${ctx}/register.jsp">Register as a customer</a></p>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

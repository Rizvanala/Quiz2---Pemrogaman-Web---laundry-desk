<%
    Map<String, String> errors = new LinkedHashMap<>();
    if ("POST".equals(request.getMethod())) {
        String password = Web.param(request, "password");
        errors = Desk.register(Web.param(request, "name"), Web.param(request, "email"), Web.param(request, "phone"),
                password, Web.param(request, "password_again"));
        if (errors.isEmpty()) {
            Map<String, Object> user = Desk.login(Web.param(request, "email"), password);
            request.changeSessionId();
            session.setAttribute("user", user);
            Web.flash(session, "ok", "Welcome, " + user.get("name") + ". Your account is ready.");
            Web.go(request, response, "/my-bills.jsp");
            return;
        }
    }
    request.setAttribute("errors", errors);
%>
<c:set var="title" value="Register"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="auth-box panel">
  <h1>Register</h1>
  <p class="muted">Create a customer account to follow your bills and balance.</p>
  <form class="form" method="post" action="${ctx}/register.jsp">
    <ld:csrf/>
    <label for="name">Full name</label>
    <input id="name" type="text" name="name" maxlength="50" value="<c:out value='${param.name}'/>" required autofocus>
    <c:if test="${not empty errors.name}"><p class="field-error"><c:out value="${errors.name}"/></p></c:if>
    <label for="email">Email</label>
    <input id="email" type="email" name="email" value="<c:out value='${param.email}'/>" required>
    <c:if test="${not empty errors.email}"><p class="field-error"><c:out value="${errors.email}"/></p></c:if>
    <label for="phone">Phone number</label>
    <input id="phone" type="text" name="phone" placeholder="0812 3456 7890" value="<c:out value='${param.phone}'/>" required>
    <c:if test="${not empty errors.phone}"><p class="field-error"><c:out value="${errors.phone}"/></p></c:if>
    <label for="password">Password (at least 8 characters)</label>
    <input id="password" type="password" name="password" required>
    <c:if test="${not empty errors.password}"><p class="field-error"><c:out value="${errors.password}"/></p></c:if>
    <label for="password_again">Repeat the password</label>
    <input id="password_again" type="password" name="password_again" required>
    <c:if test="${not empty errors.password_again}"><p class="field-error"><c:out value="${errors.password_again}"/></p></c:if>
    <div class="form-actions"><button class="btn" type="submit">Create account</button></div>
  </form>
  <p class="muted" style="margin-top:1rem">Already registered? <a href="${ctx}/login.jsp">Login</a></p>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

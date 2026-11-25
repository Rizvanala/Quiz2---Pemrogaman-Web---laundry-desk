<%@ page isErrorPage="true" %>
<c:set var="title" value="Not allowed"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="auth-box panel">
  <h1>403</h1>
  <p><c:out value="${empty requestScope['jakarta.servlet.error.message'] ? 'You are not allowed to open this page.' : requestScope['jakarta.servlet.error.message']}"/></p>
  <a class="btn" href="${ctx}/index.jsp">Back to the home page</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

<%@ page isErrorPage="true" %>
<c:set var="title" value="Not found"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="auth-box panel">
  <h1>404</h1>
  <p><c:out value="${empty requestScope['jakarta.servlet.error.message'] ? 'This page does not exist.' : requestScope['jakarta.servlet.error.message']}"/></p>
  <a class="btn" href="${ctx}/index.jsp">Back to the home page</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

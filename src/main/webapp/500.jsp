<%@ page isErrorPage="true" %>
<c:set var="title" value="Something went wrong"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="auth-box panel">
  <h1>Something went wrong</h1>
  <p>The server could not finish this request. Please go back and try again.</p>
  <a class="btn" href="${ctx}/index.jsp">Back to the home page</a>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

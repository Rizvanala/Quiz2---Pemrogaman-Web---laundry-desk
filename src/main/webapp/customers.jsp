<%
    String q = Web.param(request, "q").trim();
    Page customers = Desk.customers(q, Web.intParam(request, "page", 1));
    request.setAttribute("customers", customers);
    request.setAttribute("q", q);
    request.setAttribute("extra", Web.qs("q", q));
%>
<c:set var="title" value="Customers"/>
<c:set var="nav" value="customers"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Customers</h1>
  <a class="btn" href="${ctx}/customer-form.jsp">Add customer</a>
</div>
<form class="search" method="get" action="${ctx}/customers.jsp" role="search">
  <label class="muted" for="q" style="position:absolute;left:-9999px">Search customers</label>
  <input id="q" type="text" name="q" value="<c:out value='${q}'/>" placeholder="Search by name, code or phone">
  <button class="btn btn-ghost" type="submit">Search</button>
  <c:if test="${not empty q}"><a href="${ctx}/customers.jsp">Clear</a></c:if>
</form>
<div class="table-wrap">
  <table class="cards">
    <thead><tr><th>Code</th><th>Name</th><th>Phone</th><th class="num">Bills</th><th><span class="small">Actions</span></th></tr></thead>
    <tbody>
      <c:forEach var="row" items="${customers.rows}">
        <tr>
          <td data-label="Code" class="mono"><c:out value="${row.code}"/></td>
          <td data-label="Name"><c:out value="${row.name}"/></td>
          <td data-label="Phone" class="mono"><c:out value="${row.phone}"/></td>
          <td data-label="Bills" class="num">${row.bills}</td>
          <td class="actions">
            <a href="${ctx}/customer-form.jsp?id=${row.id}">Edit</a>
            <form method="post" action="${ctx}/customer-delete.jsp" onsubmit="return confirm('Delete this customer?')">
              <ld:csrf/><input type="hidden" name="id" value="${row.id}">
              <button class="link-danger" type="submit">Delete</button>
            </form>
          </td>
        </tr>
      </c:forEach>
      <c:if test="${empty customers.rows}"><tr><td colspan="5" class="empty">No customers match your search.</td></tr></c:if>
    </tbody>
  </table>
</div>
<ld:pager current="${customers.page}" last="${customers.pages}" path="${ctx}/customers.jsp" extra="${extra}"/>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

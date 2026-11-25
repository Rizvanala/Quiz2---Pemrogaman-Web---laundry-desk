<%
    String status = Web.param(request, "status");
    Page bills = Desk.bills(status, Web.intParam(request, "page", 1));
    request.setAttribute("bills", bills);
    request.setAttribute("status", status);
    request.setAttribute("extra", Web.qs("status", status));
%>
<c:set var="title" value="Bills"/>
<c:set var="nav" value="bills"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Bills</h1>
  <a class="btn" href="${ctx}/bill-new.jsp">New bill</a>
</div>
<nav class="filters" aria-label="Filter by status">
  <a href="${ctx}/bills.jsp" ${empty status ? 'aria-current="true"' : ''}>All</a>
  <a href="${ctx}/bills.jsp?status=received" ${status == 'received' ? 'aria-current="true"' : ''}>Received</a>
  <a href="${ctx}/bills.jsp?status=finished" ${status == 'finished' ? 'aria-current="true"' : ''}>Finished</a>
  <a href="${ctx}/bills.jsp?status=collected" ${status == 'collected' ? 'aria-current="true"' : ''}>Collected</a>
  <a href="${ctx}/bills.jsp?status=cancelled" ${status == 'cancelled' ? 'aria-current="true"' : ''}>Cancelled</a>
</nav>
<div class="table-wrap">
  <table class="cards">
    <thead><tr><th>Bill</th><th>Customer</th><th>Service</th><th>Outlet</th><th class="num">Total</th><th class="num">Balance</th><th>Status</th><th><span class="small">Actions</span></th></tr></thead>
    <tbody>
      <c:forEach var="b" items="${bills.rows}">
        <tr>
          <td data-label="Bill" class="mono"><c:out value="${b.code}"/></td>
          <td data-label="Customer"><c:out value="${b.customer}"/></td>
          <td data-label="Service"><c:out value="${b.service}"/></td>
          <td data-label="Outlet"><c:out value="${b.outlet}"/></td>
          <td data-label="Total" class="num"><ld:rp value="${b.total}"/></td>
          <td data-label="Balance" class="num"><ld:rp value="${b.balance}"/></td>
          <td data-label="Status"><ld:badge status="${b.status}"/></td>
          <td class="actions"><a href="${ctx}/bill.jsp?id=${b.id}">Open</a></td>
        </tr>
      </c:forEach>
      <c:if test="${empty bills.rows}"><tr><td colspan="8" class="empty">No bills with this status.</td></tr></c:if>
    </tbody>
  </table>
</div>
<ld:pager current="${bills.page}" last="${bills.pages}" path="${ctx}/bills.jsp" extra="${extra}"/>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

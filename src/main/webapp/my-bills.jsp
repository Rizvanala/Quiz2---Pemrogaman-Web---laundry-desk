<%
    Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
    request.setAttribute("v", Desk.myBills(((Number) user.get("id")).longValue()));
%>
<c:set var="title" value="My bills"/>
<c:set var="nav" value="my-bills"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head"><h1>My bills</h1></div>
<c:choose>
  <c:when test="${not empty v.customer}">
    <p class="muted">Customer code <span class="mono"><c:out value="${v.customer.code}"/></span> &middot; <c:out value="${v.customer.phone}"/></p>
    <div class="summary">
      <div><span>Bills</span><b>${v.bills.size()}</b></div>
      <div><span>Outstanding balance</span><b class="${v.outstanding > 0 ? 'owed' : ''}"><ld:rp value="${v.outstanding}"/></b></div>
    </div>
    <div class="table-wrap">
      <table class="cards">
        <thead><tr><th>Bill</th><th>Date</th><th>Service</th><th>Outlet</th><th class="num">Total</th><th class="num">Balance</th><th>Status</th></tr></thead>
        <tbody>
          <c:forEach var="b" items="${v.bills}">
            <tr>
              <td data-label="Bill" class="mono"><c:out value="${b.code}"/></td>
              <td data-label="Date"><ld:when value="${b.arrived_at}" day="true"/></td>
              <td data-label="Service"><c:out value="${b.service}"/></td>
              <td data-label="Outlet"><c:out value="${b.outlet}"/></td>
              <td data-label="Total" class="num"><ld:rp value="${b.total}"/></td>
              <td data-label="Balance" class="num"><ld:rp value="${b.balance}"/></td>
              <td data-label="Status"><ld:badge status="${b.status}"/></td>
            </tr>
          </c:forEach>
          <c:if test="${empty v.bills}"><tr><td colspan="7" class="empty">You have no bills yet. Drop your laundry at any outlet and it will appear here.</td></tr></c:if>
        </tbody>
      </table>
    </div>
  </c:when>
  <c:otherwise><p class="muted">Your account is not linked to a customer record. Please ask the staff at any outlet.</p></c:otherwise>
</c:choose>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

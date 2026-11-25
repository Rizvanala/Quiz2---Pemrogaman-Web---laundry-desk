<%
    Map<String, Object> view = Desk.bill(Web.longParam(request, "id", -1));
    if (view == null) {
        response.sendError(404, "That bill does not exist.");
        return;
    }
    request.setAttribute("v", view);
%>
<c:set var="title" value="${'Bill '.concat(v.bill.code)}"/>
<c:set var="nav" value="bills"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head">
  <h1>Bill <c:out value="${v.bill.code}"/> <ld:badge status="${v.bill.status}"/></h1>
  <a class="btn btn-ghost" href="${ctx}/bills.jsp">Back to bills</a>
</div>
<div class="split">
  <section>
    <h2 style="margin-top:0">Details</h2>
    <dl class="facts">
      <dt>Customer</dt><dd><c:out value="${v.bill.customer}"/> <span class="mono muted">(<c:out value="${v.bill.customer_code}"/>)</span></dd>
      <dt>Service</dt><dd><c:out value="${v.bill.service}"/></dd>
      <dt>Quantity</dt><dd>${v.bill.unit}</dd>
      <dt>Outlet</dt><dd><c:out value="${v.bill.outlet}"/></dd>
      <dt>Taken in by</dt><dd><c:out value="${v.bill.clerk}"/></dd>
      <dt>Arrived</dt><dd><ld:when value="${v.bill.arrived_at}"/></dd>
    </dl>
    <div class="summary">
      <div><span>Total</span><b><ld:rp value="${v.bill.total}"/></b></div>
      <div><span>Paid</span><b><ld:rp value="${v.paid}"/></b></div>
      <div><span>Balance</span><b class="${v.balance > 0 ? 'owed' : ''}"><ld:rp value="${v.balance}"/></b></div>
    </div>
    <c:choose>
      <c:when test="${not empty v.next}">
        <form method="post" action="${ctx}/bill-advance.jsp">
          <ld:csrf/><input type="hidden" name="id" value="${v.bill.id}">
          <button class="btn" type="submit">Move to ${v.next}</button>
        </form>
      </c:when>
      <c:otherwise><p class="muted">This bill is ${v.bill.status}. Its status cannot change any more.</p></c:otherwise>
    </c:choose>
  </section>
  <section>
    <h2 style="margin-top:0">Status history</h2>
    <ul class="timeline">
      <c:forEach var="l" items="${v.logs}">
        <li><ld:badge status="${l.status}"/><span><ld:when value="${l.changed_at}"/> &middot; <c:out value="${l.clerk}"/></span></li>
      </c:forEach>
    </ul>
  </section>
</div>

<h2>Payments</h2>
<div class="table-wrap">
  <table class="cards">
    <thead><tr><th>Date</th><th>Recorded by</th><th class="num">Amount</th></tr></thead>
    <tbody>
      <c:forEach var="p" items="${v.payments}">
        <tr>
          <td data-label="Date"><ld:when value="${p.paid_at}"/></td>
          <td data-label="Recorded by"><c:out value="${p.clerk}"/></td>
          <td data-label="Amount" class="num"><ld:rp value="${p.amount}"/></td>
        </tr>
      </c:forEach>
      <c:if test="${empty v.payments}"><tr><td colspan="3" class="empty">No payments yet.</td></tr></c:if>
    </tbody>
  </table>
</div>
<c:choose>
  <c:when test="${v.balance > 0 and v.bill.status != 'cancelled'}">
    <form class="form pay-form" method="post" action="${ctx}/bill-pay.jsp">
      <ld:csrf/><input type="hidden" name="id" value="${v.bill.id}">
      <label for="amount">Record a payment (Rp)</label>
      <div class="inline-fields">
        <input id="amount" type="number" name="amount" min="1" max="${v.balance}" step="1" required>
        <button class="btn" type="submit">Save payment</button>
      </div>
    </form>
  </c:when>
  <c:otherwise><p class="muted">Nothing left to pay on this bill.</p></c:otherwise>
</c:choose>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

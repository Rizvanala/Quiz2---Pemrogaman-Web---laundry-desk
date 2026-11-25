<%
    Map<String, Object> user = (Map<String, Object>) session.getAttribute("user");
    Map<String, String> errors = new LinkedHashMap<>();
    if ("POST".equals(request.getMethod())) {
        Map<String, Object> made = Desk.newBill(Web.param(request, "customer_id"), Web.param(request, "service_id"),
                Web.param(request, "unit"), user, errors);
        if (made != null) {
            Web.flash(session, "ok", "Bill " + made.get("code") + " was taken in.");
            Web.go(request, response, "/bill.jsp?id=" + made.get("id"));
            return;
        }
    }
    request.setAttribute("errors", errors);
    request.setAttribute("customers", Desk.allCustomers());
    request.setAttribute("services", Desk.services());
    request.setAttribute("outlet", Desk.outlet(user.get("outlet_id")));
    request.setAttribute("unit", request.getParameter("unit") == null ? "1" : request.getParameter("unit"));
%>
<c:set var="title" value="New bill"/>
<c:set var="nav" value="bill-new"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head"><h1>Take in a new bill</h1></div>
<form class="form" method="post" action="${ctx}/bill-new.jsp">
  <ld:csrf/>
  <label for="customer_id">Customer</label>
  <select id="customer_id" name="customer_id" required>
    <option value="">Choose a customer</option>
    <c:forEach var="c" items="${customers}">
      <option value="${c.id}" ${param.customer_id == c.id ? 'selected' : ''}><c:out value="${c.code} - ${c.name}"/></option>
    </c:forEach>
  </select>
  <c:if test="${not empty errors.customer_id}"><p class="field-error"><c:out value="${errors.customer_id}"/></p></c:if>

  <label for="service_id">Service</label>
  <select id="service_id" name="service_id" required>
    <option value="">Choose a service</option>
    <c:forEach var="s" items="${services}">
      <option value="${s.id}" data-price="${s.price}" ${param.service_id == s.id ? 'selected' : ''}><c:out value="${s.description}"/> (<ld:rp value="${s.price}"/>)</option>
    </c:forEach>
  </select>
  <c:if test="${not empty errors.service_id}"><p class="field-error"><c:out value="${errors.service_id}"/></p></c:if>

  <label for="unit">Quantity (kg, pieces, sets or pairs)</label>
  <input id="unit" type="number" name="unit" min="1" max="100" step="1" value="<c:out value='${unit}'/>" required>
  <c:if test="${not empty errors.unit}"><p class="field-error"><c:out value="${errors.unit}"/></p></c:if>
  <c:if test="${not empty errors.outlet}"><p class="field-error"><c:out value="${errors.outlet}"/></p></c:if>

  <div class="summary">
    <div><span>Outlet</span><b><c:out value="${empty outlet ? 'Not assigned' : outlet.name}"/></b></div>
    <div><span>Estimated total</span><b id="preview-total">Rp 0</b></div>
  </div>
  <p class="muted small">The server calculates the final total again when you save.</p>
  <div class="form-actions">
    <button class="btn" type="submit">Save bill</button>
    <a class="btn btn-ghost" href="${ctx}/bills.jsp">Cancel</a>
  </div>
</form>
<script>
  (function () {
    var service = document.getElementById("service_id");
    var unit = document.getElementById("unit");
    var out = document.getElementById("preview-total");
    function update() {
      var option = service.options[service.selectedIndex];
      var price = parseInt(option.getAttribute("data-price") || "0", 10);
      var qty = parseInt(unit.value || "0", 10);
      out.textContent = "Rp " + (price * qty).toLocaleString("id-ID");
    }
    service.addEventListener("change", update);
    unit.addEventListener("input", update);
    update();
  })();
</script>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

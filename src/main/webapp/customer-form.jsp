<%
    long id = Web.longParam(request, "id", -1);
    boolean editing = request.getParameter("id") != null;
    Map<String, Object> existing = null;
    if (editing) {
        existing = Desk.customer(id);
        if (existing == null) {
            response.sendError(404, "That customer does not exist.");
            return;
        }
    }
    String name = editing ? Objects.toString(existing.get("name"), "") : "";
    String phone = editing ? Objects.toString(existing.get("phone"), "") : "";
    String address = editing ? Objects.toString(existing.get("address"), "") : "";
    Map<String, String> errors = new LinkedHashMap<>();
    if ("POST".equals(request.getMethod())) {
        name = Web.param(request, "name").trim();
        phone = Web.param(request, "phone").trim();
        address = Web.param(request, "address").trim();
        errors = Desk.checkCustomer(name, phone, address);
        if (errors.isEmpty()) {
            if (editing) {
                Desk.updateCustomer(id, name, phone, address);
                Web.flash(session, "ok", "Customer " + existing.get("code") + " was updated.");
            } else {
                String code = Desk.addCustomer(name, phone, address);
                Web.flash(session, "ok", "Customer " + code + " (" + name + ") was added.");
            }
            Web.go(request, response, "/customers.jsp");
            return;
        }
    }
    request.setAttribute("editing", editing);
    request.setAttribute("existing", existing);
    request.setAttribute("errors", errors);
    request.setAttribute("name", name);
    request.setAttribute("phone", phone);
    request.setAttribute("address", address);
%>
<c:set var="title" value="${editing ? 'Edit customer' : 'Add customer'}"/>
<c:set var="nav" value="customers"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head"><h1><c:choose><c:when test="${editing}">Edit <c:out value="${existing.code}"/></c:when><c:otherwise>Add customer</c:otherwise></c:choose></h1></div>
<form class="form" method="post" action="${ctx}/customer-form.jsp<c:if test='${editing}'>?id=${existing.id}</c:if>">
  <ld:csrf/>
  <label for="name">Full name</label>
  <input id="name" type="text" name="name" maxlength="50" value="<c:out value='${name}'/>" required>
  <c:if test="${not empty errors.name}"><p class="field-error"><c:out value="${errors.name}"/></p></c:if>
  <label for="phone">Phone number</label>
  <input id="phone" type="text" name="phone" placeholder="0812 3456 7890" value="<c:out value='${phone}'/>" required>
  <c:if test="${not empty errors.phone}"><p class="field-error"><c:out value="${errors.phone}"/></p></c:if>
  <label for="address">Address (optional)</label>
  <input id="address" type="text" name="address" maxlength="120" value="<c:out value='${address}'/>">
  <c:if test="${not empty errors.address}"><p class="field-error"><c:out value="${errors.address}"/></p></c:if>
  <div class="form-actions">
    <button class="btn" type="submit"><c:out value="${editing ? 'Update customer' : 'Save customer'}"/></button>
    <a class="btn btn-ghost" href="${ctx}/customers.jsp">Cancel</a>
  </div>
</form>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

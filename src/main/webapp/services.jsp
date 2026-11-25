<%
    request.setAttribute("services", Desk.services());
%>
<c:set var="title" value="Price list"/>
<c:set var="nav" value="services"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head"><h1>Price list</h1></div>
<p class="muted">Prices are per kilogram, piece, set or pair, as written. The total of a bill is calculated by the server when the order is taken in.</p>
<div class="table-wrap">
  <table class="cards">
    <thead><tr><th>Code</th><th>Service</th><th class="num">Price</th></tr></thead>
    <tbody>
      <c:forEach var="s" items="${services}">
        <tr>
          <td data-label="Code" class="mono"><c:out value="${s.code}"/></td>
          <td data-label="Service"><c:out value="${s.description}"/></td>
          <td data-label="Price" class="num"><ld:rp value="${s.price}"/></td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

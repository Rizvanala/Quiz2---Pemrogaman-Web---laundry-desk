<%
    List<Map<String, Object>> all = Desk.services();
    request.setAttribute("popular", all.subList(0, Math.min(4, all.size())));
    request.setAttribute("outlets", Desk.outlets());
%>
<c:set var="title" value="Home"/>
<c:set var="nav" value="home"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<section class="hero">
  <div class="wrap">
    <div class="hero-card">
      <h1>Laundry Desk</h1>
      <p>Order tracking and payments for three laundry outlets in Surabaya. Staff take in the laundry and record payments, and customers can check their own bills online.</p>
      <div class="hero-actions">
        <a class="btn" href="${ctx}/services.jsp">See the price list</a>
        <c:choose>
          <c:when test="${me.role == 'staff'}"><a class="btn btn-ghost" href="${ctx}/bills.jsp">Open the bills</a></c:when>
          <c:when test="${me.role == 'customer'}"><a class="btn btn-ghost" href="${ctx}/my-bills.jsp">Open my bills</a></c:when>
          <c:otherwise><a class="btn btn-ghost" href="${ctx}/register.jsp">Create an account</a></c:otherwise>
        </c:choose>
      </div>
    </div>
  </div>
</section>
<div>
  <div class="split">
    <section>
      <h2>How it works</h2>
      <ol class="steps">
        <li><div><strong>Received.</strong> Staff take in the laundry and the system calculates the total.</div></li>
        <li><div><strong>Finished.</strong> The laundry is done and the status is updated.</div></li>
        <li><div><strong>Collected.</strong> The customer picks it up. Payments are recorded until the balance is zero.</div></li>
      </ol>
    </section>
    <section>
      <h2>Services</h2>
      <ul class="price-lines">
        <c:forEach var="s" items="${popular}">
          <li><span><c:out value="${s.description}"/></span><b><ld:rp value="${s.price}"/></b></li>
        </c:forEach>
      </ul>
      <a href="${ctx}/services.jsp">Full price list</a>
    </section>
  </div>

  <h2>Gallery</h2>
  <div class="gallery">
    <figure><img src="${ctx}/images/machines.jpg" alt="Row of washing machines" loading="lazy"><figcaption>Washing machines</figcaption></figure>
    <figure><img src="${ctx}/images/folding.jpg" alt="Folded towels stacked by color" loading="lazy"><figcaption>Folded laundry</figcaption></figure>
  </div>

  <h2>Outlets</h2>
  <div class="table-wrap">
    <table class="cards">
      <thead><tr><th>Outlet</th><th>Address</th><th>Phone</th></tr></thead>
      <tbody>
        <c:forEach var="o" items="${outlets}">
          <tr>
            <td data-label="Outlet"><c:out value="${o.name}"/></td>
            <td data-label="Address"><c:out value="${o.address}"/></td>
            <td data-label="Phone" class="mono"><c:out value="${o.phone}"/></td>
          </tr>
        </c:forEach>
      </tbody>
    </table>
  </div>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

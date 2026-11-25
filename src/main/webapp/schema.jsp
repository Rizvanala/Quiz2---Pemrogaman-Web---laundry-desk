<%
    request.setAttribute("tables", Desk.dataModel());
%>
<c:set var="title" value="Data model"/>
<%@ include file="/WEB-INF/jspf/header.jspf" %>
<div class="page-head"><h1>Data model</h1></div>
<p class="muted">This page reads the live database. Every table is listed with its columns, primary keys (PK) and foreign keys. All foreign keys use ON DELETE RESTRICT.</p>
<div class="model">
  <c:forEach var="t" items="${tables}">
    <section class="panel">
      <h3><span><c:out value="${t.name}"/></span><span class="small muted">${t.rows} rows</span></h3>
      <table>
        <thead><tr><th>Column</th><th>Type</th><th>Key</th></tr></thead>
        <tbody>
          <c:forEach var="col" items="${t.columns}">
            <tr><td><c:out value="${col.name}"/></td><td class="mono"><c:out value="${col.type}"/></td><td><c:if test="${col.pk > 0}">PK</c:if><c:if test="${col.notnull > 0 and col.pk == 0}">not null</c:if></td></tr>
          </c:forEach>
        </tbody>
      </table>
      <c:forEach var="k" items="${t.keys}">
        <p class="small" style="margin:0.5rem 0 0">FK <c:out value="${k.from}"/> &rarr; <c:out value="${k.table}"/>.<c:out value="${k.to}"/> (<c:out value="${k.on_delete}"/>)</p>
      </c:forEach>
    </section>
  </c:forEach>
</div>
<%@ include file="/WEB-INF/jspf/footer.jspf" %>

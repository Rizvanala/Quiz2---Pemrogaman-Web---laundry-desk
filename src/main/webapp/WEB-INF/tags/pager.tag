<%@ tag body-content="empty" %>
<%@ attribute name="current" required="true" type="java.lang.Integer" %>
<%@ attribute name="last" required="true" type="java.lang.Integer" %>
<%@ attribute name="path" required="true" type="java.lang.String" %>
<%@ attribute name="extra" required="false" type="java.lang.String" %>
<%
    String more = extra == null ? "" : extra.replace("&", "&amp;");
    if (last > 1) {
%>
<nav class="pager" aria-label="Pages">
<% if (current > 1) { %><a href="<%= path %>?page=<%= current - 1 %><%= more %>">Previous</a><% } else { %><span class="off">Previous</span><% } %>
<span>Page <%= current %> of <%= last %></span>
<% if (current < last) { %><a href="<%= path %>?page=<%= current + 1 %><%= more %>">Next</a><% } else { %><span class="off">Next</span><% } %>
</nav>
<% } %>

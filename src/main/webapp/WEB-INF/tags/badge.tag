<%@ tag body-content="empty" %>
<%@ attribute name="status" required="true" type="java.lang.String" %>
<%
    String label = "Received";
    String mark = "&#9675;";
    if ("finished".equals(status)) { label = "Finished"; mark = "&#9680;"; }
    if ("collected".equals(status)) { label = "Collected"; mark = "&#9679;"; }
    if ("cancelled".equals(status)) { label = "Cancelled"; mark = "&#10005;"; }
%>
<span class="badge badge-<%= status %>"><span aria-hidden="true"><%= mark %></span><%= label %></span>

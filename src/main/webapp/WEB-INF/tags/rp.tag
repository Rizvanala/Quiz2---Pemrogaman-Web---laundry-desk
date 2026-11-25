<%@ tag body-content="empty" %>
<%@ attribute name="value" required="true" type="java.lang.Object" %>
<%
    long amount = value == null ? 0 : ((Number) value).longValue();
    out.print("Rp " + java.text.NumberFormat.getIntegerInstance(new java.util.Locale("id", "ID")).format(amount));
%>

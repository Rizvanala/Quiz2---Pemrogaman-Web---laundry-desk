<%@ tag body-content="empty" pageEncoding="UTF-8" %>
<%@ attribute name="value" required="true" type="java.lang.Object" %>
<%@ attribute name="day" required="false" type="java.lang.Boolean" %>
<%
    if (value != null) {
        java.time.LocalDateTime time = java.time.LocalDateTime.parse(value.toString().replace(' ', 'T'));
        String pattern = (day != null && day) ? "dd MMM yyyy" : "dd MMM yyyy, HH:mm";
        out.print(time.format(java.time.format.DateTimeFormatter.ofPattern(pattern, java.util.Locale.ENGLISH)));
    }
%>

<%@include file="../config.jsp" %>
<%@include file="../classes/Redis.jsp" %>
<%
    Redis redis = new Redis();
    redis.setString(request.getRemoteAddr(),"emrahdogan");
    String value = redis.getString(request.getRemoteAddr());
    out.print(value);
%>

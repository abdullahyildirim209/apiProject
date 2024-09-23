<%--
  Created by IntelliJ IDEA.
  User: AbdullahYusuf
  Date: 19.09.2024
  Time: 09:46
  To change this template use File | Settings | File Templates.
--%>
<%@ page errorPage="error.jsp" %>
<%@include file="classes/Request.jsp" %>
<%@include file="classes/Postgre.jsp" %>
<%--<%@include file="classes/Json.jsp" %>--%>
<%
    response.setContentType("application/json");
    Postgre postgre = new Postgre(request.getInputStream());
    postgre.select();
%>
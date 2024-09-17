<%--
  Created by IntelliJ IDEA.
  User: AbdullahYusuf
  Date: 17.09.2024
  Time: 11:37
  To change this template use File | Settings | File Templates.
--%>
<%@ page errorPage="error.jsp" %>
<%@include file="classes/Postgre.jsp" %>

<%
    response.setContentType("application/json");
    Postgre postgre = new Postgre(request.getInputStream());
    out.print(postgre.update());
    //out.print(postgre.query);

%>
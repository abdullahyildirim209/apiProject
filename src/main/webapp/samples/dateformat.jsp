<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.Date" %>
<%--
  Created by IntelliJ IDEA.
  User: AbdullahYusuf
  Date: 19.09.2024
  Time: 09:39
  To change this template use File | Settings | File Templates.
--%>
<%
  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  out.print(sdf.format(new Date()));
%>
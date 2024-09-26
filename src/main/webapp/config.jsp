<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%--
  Created by IntelliJ IDEA.
  User: emrah.dogan
  Date: 20.09.2024
  Time: 09:11
  To change this template use File | Settings | File Templates.
--%>
<%
    Dotenv dotenv = Dotenv
            .configure()
            .directory(request.getServletContext().getRealPath(""))
            .filename(".env")
            .ignoreIfMalformed()
            // .ignoreIfMissing()
            .load();
    //out.print(dotenv.get("POSTGRES_SERVER"));
%>

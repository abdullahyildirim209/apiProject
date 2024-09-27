<%--<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>--%>
<%@ page errorPage="error.jsp" %>
<%@include file="config.jsp" %>
<%@include file="classes/Postgre.jsp" %>
<%
  response.setContentType("application/json");
  Postgre postgre = new Postgre(request.getInputStream());
  //out.print(postgre.error);
  if(postgre.error != 1) {
    //out.print(postgre.sql);
    //out.print(postgre.query);
    out.print(postgre.rawSql());
    //out.print(postgre.select());
  }
 /* Dotenv dotenv = Dotenv
          .configure()
          .directory(request.getServletContext().getRealPath(""))
          .filename(".env")
          .ignoreIfMalformed()
          // .ignoreIfMissing()
          .load();
  out.print(dotenv.get("MY_ENV_VAR1"));*/
%>
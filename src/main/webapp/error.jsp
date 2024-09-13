<%@ page import="java.io.StringWriter" %>
<%@ page import="java.io.PrintWriter" %>
<%@include file="classes/Mongo.jsp" %>
<%@ page isErrorPage="true" %>
<%
    response.setContentType("application/json");
    response.setStatus(500);
    StringWriter sw = new StringWriter();
    PrintWriter pw  = new PrintWriter(sw);
    exception.printStackTrace(pw);

    Mongo mongo   = new Mongo();
    JSONObject jo = new JSONObject();
    jo.put("method","test");
    jo.put("type","error");
    jo.put("file","Mongo.jsp");
    jo.put("message1",exception.getMessage());
    jo.put("message2",exception.toString());
    jo.put("trace",sw.toString());

    mongo.set(jo);
    mongo.insert();

    JSONObject joresponse = new JSONObject();
    joresponse.put("status",500);
    joresponse.put("message","Internal Server Error : "+exception.getMessage());
    out.print(joresponse);
%>
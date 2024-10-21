<%--
  Created by IntelliJ IDEA.
  User: AbdullahYusuf
  Date: 25.09.2024
  Time: 13:47
  To change this template use File | Settings | File Templates.
--%>
<%@ page errorPage="error.jsp" %>
<%@include file="config.jsp" %>
<%@include file="classes/Request.jsp" %>
<%@include file="classes/Postgre.jsp" %>
<%@include file="classes/Redis.jsp" %>
<%@ page import="java.net.*" %>
<%--<%@include file="classes/Json.jsp" %>--%>
<%
    response.setContentType("application/json");
    Request rh        = new Request();
    String token      = rh.getToken();
    Postgre postgre   = new Postgre(request.getInputStream());

    InetAddress inetAddress = InetAddress.getLocalHost();
    String ipAddress        = inetAddress.getHostAddress();

    JSONObject jo    = postgre.select();
    Integer jo_status = (Integer) (jo.get("status"));

    if(jo_status.equals(200)){
        postgre.set       = postgre.set.replace("--token--",token);
        postgre.set       = postgre.set.replace("--ip--",ipAddress);
        JSONObject jou    = postgre.update();
        String jou_status = (String) (jou.get("status"));

        if(jou_status.equals("200")){
            Redis redis = new Redis();
            redis.setString(ipAddress, token);
            //String value = redis.getString(ipAddress);
            response.setStatus(200);
            out.print("{\"status\": 200, \"message\": \"Token successfully up\", \"token\": \"" + token + "\"}");
        } else{
            response.setStatus(500);
            out.print("{\"status\": 500, \"message\": \"Unexpected error\"}");
        }
    } else{
        response.setStatus(401);
        out.print("{\"status\": 401, \"message\": \"Unauthorized\"}");
    }
%>


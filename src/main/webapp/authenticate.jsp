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
<%--<%@include file="classes/Json.jsp" %>--%>
<%
    response.setContentType("application/json");
    Request rh = new Request();
    String token = rh.getToken();
    Postgre postgre = new Postgre(request.getInputStream());
    String ipAddress = request.getRemoteAddr();
    //out.print(postgre.select());
    //out.print(postgre.set);
    //out.print(postgre.filter);
    JSONObject jo = postgre.select();

    if((jo.get("status")).equals(200)){
        JSONArray users = (JSONArray) jo.get("users");
        JSONObject user = users.getJSONObject(0);
        //out.print(users.getJSONObject(0));
        String userId = (String) user.get("id");
        JSONObject updateResponse = postgre.updateToken(userId, token, ipAddress);
        //out.print((String) user.get("id"));
        if(updateResponse.getInt("status") == 200){
            Redis redis = new Redis();
            redis.setString(request.getRemoteAddr(), token);
            String value = redis.getString(request.getRemoteAddr());
            out.print("{\"status\": 200, \"message\": \"Token successfully updated for user with ID: " + userId + "\", \"token\": \"" + value + "\"}");
            //out.print("Token is: " + token);
        }else{
            out.print("{\"status\": " + updateResponse.getInt("status") + ", \"message\": \"" + updateResponse.getString("message") + "\"}");
        }
    }else{
        out.print("{\"status\": " + jo.getInt("status") + ", \"message\": \"" + jo.getString("message") + "\"}");
    }
%>
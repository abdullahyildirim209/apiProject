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
<%--<%@include file="classes/Json.jsp" %>--%>


<%
    response.setContentType("application/json");
    Request rh = new Request();
    String token = rh.getToken();
    Postgre postgre = new Postgre(request.getInputStream());
    //out.print(postgre.select());
    //out.print(postgre.set);
    //out.print(postgre.filter);
    JSONObject jo = postgre.select();

    if((jo.get("status")).equals(200)){
        JSONArray users = (JSONArray) jo.get("users");
        JSONObject user = users.getJSONObject(0);
        //out.print(users.getJSONObject(0));
        out.print((String) user.get("id"));
    }
%>


<%--
<%
    response.setContentType("application/json");

    Request rh = new Request();
    String token = rh.getToken();

    Postgre postgre = new Postgre(request.getInputStream());
    JSONObject updateResponse = postgre.token();

    if (updateResponse.getInt("status") == 200) {
        JSONObject jo = postgre.select();

        if (jo.getInt("status") == 200) {
            JSONArray usersArray = jo.getJSONArray("users");

            for (int i = 0; i < usersArray.length(); i++) {
                JSONObject user = usersArray.getJSONObject(i);

                int userId = user.getInt("id");
                out.print("ID: " + userId + ", Token: " + token);
            }
        } else {
            out.print("you couldnot get the users.");
        }
    } else {
        out.print("you couldnot update the token: " + updateResponse.getString("message"));
    }
%>--%>

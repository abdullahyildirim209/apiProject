<%--
  Created by IntelliJ IDEA.
  User: AbdullahYusuf
  Date: 19.09.2024
  Time: 09:37
  To change this template use File | Settings | File Templates.
--%>
<%@ page import="java.io.*" %>
<%
    BufferedReader in = new BufferedReader(
            new InputStreamReader(request.getInputStream()));
    PrintWriter r = new PrintWriter(response.getOutputStream());

    // response.setContentType("application/json");

    String line = null;
    while((line = in.readLine()) != null) {
        r.printf("%s<br/>\r\n", line);
    }
    r.print("emrah");

    r.flush();
%>
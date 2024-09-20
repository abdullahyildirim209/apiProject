<%@include file="config.jsp" %>
<%@include file="classes/Postgre.jsp" %>
<%
    response.setContentType("application/json");
    Postgre postgre = new Postgre(request.getInputStream());
    if(postgre.error != 1){
        out.print(postgre.select());
        //out.print(postgre.filter);
    }
%>

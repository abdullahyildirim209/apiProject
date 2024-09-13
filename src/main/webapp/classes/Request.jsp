<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Enumeration" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.*" %>
<%--
  Created by IntelliJ IDEA.
  User: omer.kesmez
  Date: 29.08.2024
  Time: 09:20
  To change this template use File | Settings | File Templates.
--%>
<%
    class Request{
        private java.sql.Statement stmt;
        private java.sql.Connection conn;
        private java.sql.ResultSet rs;
        private java.io.BufferedReader reader;
        JSONObject jsonObject;
        private String type;
        private String table;
        public String limit;
        public JSONObject where;
        private String testreturn  = "tanimsiz";

        public Request(){
        }

        public Map<String, String> parameters(){
        //public ArrayList<String> parameters(){
            Enumeration parameterNames       = request.getParameterNames();
            Map<String, String> hm           = new HashMap<String, String>();
            ArrayList<String> parameter_list = new ArrayList<String>(); // Create an ArrayList object
            while(parameterNames.hasMoreElements()){
                String parameterName  = (String) parameterNames.nextElement();
                String parameterValue = request.getParameter(parameterName);
                parameter_list.add(parameterValue);
                hm.put(parameterName,parameterValue);
            }
            return hm;
            //return parameter_list;
        }

        public void setTestreturn(String test) {
            testreturn = test;
        }
    }
%>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>

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

        public JSONObject authenticate() {
            String inputUsername = request.getParameter("username");
            String inputPassword = request.getParameter("password");
            //eger json bir veri gonderldiyse json ile de islem yapabilecek hale getir
            String validUserName = "playstore";
            String validPassword = "123456";

            if (inputUsername.equals(validUserName) && inputPassword.equals(validPassword)) {
                return token(200);
            } else {
                return token(401);
            }
        }

        public JSONObject token(int HttpStatus){
            JSONObject jsonObject = new JSONObject();
            if(HttpStatus == 200){
                String token = UUID.randomUUID().toString();
                jsonObject.put("status",200);
                jsonObject.put("access_token",token);
            } else if (HttpStatus == 401) {
                jsonObject.put("status",401);
                jsonObject.put("message","unauthorized access"+request.getParameter("username"));
            }
            return jsonObject;
        }

        public void setTestreturn(String test) {
            testreturn = test;
        }
    }
%>
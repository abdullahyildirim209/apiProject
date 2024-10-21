<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
<%@ page import="org.json.JSONArray" %>
<%@include file="Mongo.jsp" %>
<%@include file="Json.jsp" %>
<%--
  https://github.com/redisson/redisson/wiki/Table-of-Content
  <%@include file="classes/Postgre.jsp" %>
  --------------------------------------------
  How to Use
  -------------------------------------------
  Postgre postgre = new Postgre();
  out.print(postgre.select());
  -------------------------------------------
--%>
<%
    class Postgre extends Json{
        private java.sql.Statement stmt;
        private java.sql.Connection conn;
        private java.sql.ResultSet rs;
        private java.io.BufferedReader reader;
        JSONObject jsonObject;
        JSONObject rowdata;
        JSONObject requestBodyParameters;
        public int error = 0;
        String query = "";
        JSONObject response    = new JSONObject();
        JSONArray userList     = new JSONArray();

        public Postgre(InputStream inputStream){
            requestBodyParameters = jsonRead(inputStream);
            //if(table == null){
            if(table == null && sql.equals("")){
                //if(sql.equals("")){
                //if(sql == null){
                    error = 1;
                //}
            } else{
                connect();
            }
        }

        public void connect(){
            String url = "jdbc:postgresql://" + dotenv.get("POSTGRES_SERVER") + ":" + dotenv.get("POSTGRES_PORT") + "/" + dotenv.get("POSTGRES_DB") + "?user=" + dotenv.get("POSTGRES_USER") + "&password=" + dotenv.get("POSTGRES_PASSWORD") + "&ssl=" + dotenv.get("POSTGRES_SSL");
            try {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(null,"connect","trace","Postgres.jsp",url);
                Class.forName("org.postgresql.Driver").newInstance();
                conn = java.sql.DriverManager.getConnection(url);
                stmt = conn.createStatement();
               /* Mongo mongo = new Mongo();
                mongo.setAndInsert(null,"connect","trace","Postgres.jsp","");*/
            }
            catch (java.sql.SQLException sqle) {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(sqle,"connect","error","Postgre.sql",null);
            }
            catch (Exception e) {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(e,"connect","error","Postgre.sql",null);
            }
        }

        public JSONObject select(){
            try {
                if(!sql.equals("")){
                    query = sql;
                } else{
                    query = "SELECT * FROM " + table + filter + limit;
                }
                rs = stmt.executeQuery(query);
                ResultSetMetaData rsmd = rs.getMetaData();
                int columnCount = rsmd.getColumnCount();

                while (rs.next()) {
                    JSONObject rowdata = new JSONObject();
                    for (int i = 1; i <= columnCount; i++) {
                        String name = rsmd.getColumnName(i);
                        String columnValue = rs.getString(name);
                        rowdata.put(name, columnValue);
                    }
                    userList.put(rowdata);

                }
                rs.close();
                stmt.close();

                if (userList.length() > 0) {
                    response.put("users", userList);
                    response.put("status", 200);
                }
            } catch (java.sql.SQLException sqle) {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(sqle, "select", "error", "Postgre.sql", query);
                response.put("status", 500);
                response.put("message", "SQL error occurred");
            } catch (Exception e) {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(e, "select", "error", "Postgre.sql", query);
                response.put("status", 500);
                response.put("message", "General error occurred");
            } finally {
                if (response.length() == 0) {
                    response.put("status", 500);
                    response.put("message", "No data found");
                }
                return response;
            }
        }

        public JSONObject update(){
            String message = "";
            try{
                query = "UPDATE "+ table + set + filter;
//                stmt.executeUpdate(query);
//                stmt.close();
                PreparedStatement pstmt;
                pstmt = conn.prepareStatement(query);
                pstmt.executeUpdate();
                pstmt.close();

                Mongo mongo = new Mongo();
                mongo.setAndInsert(null, "update", "watch", "Postgre.jsp", set);
                message     = "{\"status\":\"200\",\"message\":\"Operation is succesfully.\"}";
            } catch (java.sql.SQLException sqle) {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(sqle, "select", "error", "Postgre.sql", query);
                message     = "{\"status\":\"500\",\"message\":\"Operation is not succesfully.\"}";
            } catch (Exception e)	{
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(e,"update","error","Postgre.sql",query);
                message     = "{\"status\":\"500\",\"message\":\"Operation is not succesfully.\"}";
            } finally {
                return new JSONObject(message);
            }
        }

        public JSONObject rawSql(){

            try {
                response = select();
            } catch (Exception e) {
                Mongo mongo = new Mongo();
                mongo.setAndInsert(e, "rawSql", "error", "Postgre.sql", sql);
                response.put("status", 500);
                response.put("message", "General error occurred");
            } finally {
                if (response.length() == 0) {
                    response.put("status", 500);
                    response.put("message", "No data found");
                }
                return response;
            }
        }

    }
%>

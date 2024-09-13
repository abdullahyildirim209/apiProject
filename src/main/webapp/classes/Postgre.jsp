<%--
  Created by IntelliJ IDEA.
  User: omer.kesmez
  Date: 8.09.2024
  Time: 22:39
--%>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.sql.*" %>
<%@ page import="org.json.JSONObject" %>
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
        JSONObject requestBodyParameters;
        public int error = 0;
        String query = "";

        public Postgre(InputStream inputStream){
            /*Scanner s       = new Scanner(inputStream).useDelimiter("\\A");
            String result   = s.hasNext() ? s.next() : "";
            Mongo mongo   = new Mongo();
            mongo.setAndInsert(null,"Postgre","check","Postgre.jsp",result);*/
            requestBodyParameters = jsonRead(inputStream);
            if(table == null){
                error = 1;
            } else{
                connect();
            }
        }

        public void connect(){
            String url = "jdbc:postgresql://localhost:5432/local?user=postgres&password=123456&ssl=false";
            try	{
                Class.forName("org.postgresql.Driver").newInstance();
                //json          = new Json();
                //JSONObject jo = json.jsonRead(request.getInputStream());
                conn = java.sql.DriverManager.getConnection(url);
                stmt = conn.createStatement();
            }
            catch (java.sql.SQLException sqle)	{
                //sqle.printStackTrace();
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(sqle,"connect","error","Postgre.sql",null);
            }
            catch (Exception e)	{
                //e.printStackTrace();
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(e,"connect","error","Postgre.sql",null);
            }
        }

        public JSONObject select(){
            Map<String, String> hm = new HashMap<String, String>();
            JSONObject rowdata     = new JSONObject();
            JSONObject response    = new JSONObject();
            try	{
                query = "SELECT * FROM "+table+filter+" limit "+limit;
                rs                     = stmt.executeQuery(query);
                ResultSetMetaData rsmd = rs.getMetaData();
                int columnCount        = rsmd.getColumnCount();
                while (rs.next()) {
                    //out.print(rs.getString(1));
                    for (int i = 1; i <= columnCount; i++ ) {
                        String name        = rsmd.getColumnName(i);
                        String columnValue = rs.getString(name);
                        rowdata.put(name,columnValue);
                    }
                    response.put(rs.getString(1),rowdata);
                }
                rs.close();
                stmt.close();
            } catch (java.sql.SQLException sqle)	{
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(sqle,"select","error","Postgre.sql",query);
            } catch (Exception e)	{
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(e,"select","error","Postgre.sql",query);
            } finally {
                if(response.length() == 0){
                    response.put("status",500);
                    response.put("message","Postgre error. Please log check. file:Postgre.sql method:select");
                }
                return response;
                //return new JSONObject(hm);
            }
        }
    }
%>
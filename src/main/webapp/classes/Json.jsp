<%@ page import="org.json.JSONObject" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.util.Scanner" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.io.*" %>

<%--
  --------------------------------------------
  How to Use
  -------------------------------------------
  Json json        = new Json();
  JSONObject jo    = json.jsonRead(request.getInputStream());
  String table     = (String) jo.get("table");
  String limit     = (String) jo.get("limit");
  JSONObject where = json.where;
  out.print(where.get("customer_id"));
  -------------------------------------------
--%>
<%
    class Json{
        JSONObject jsonObject;
        public String type;
        public String table = null;
        public String limit;
        public JSONObject where;
        public JSONObject setObject;
        public String filter          = "";
        public String set          = "";
        String name         = "";

        public Json(){}

        public JSONObject jsonRead(InputStream inputStream){
            Scanner s       = new Scanner(inputStream).useDelimiter("\\A");
            String result   = s.hasNext() ? s.next() : "";
            try{
                jsonObject      = new JSONObject(result);
                parseRequestJsonBody(jsonObject);
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(null,"jsonRead","watch","Json.jsp",result);

            } catch (Exception e) {
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(e,"jsonRead","error","Json.sql",null);
            } finally {
                return jsonObject;
            }
        }

        public void parseRequestJsonBody(JSONObject jo){
            int i = 0;
            try{
                type  = (String) jo.get("type");
                table = (String) jo.get("table");
                limit = (String) jo.get("limit");
                where = (JSONObject) jo.get("where");
                if(!jo.isNull("set")){
                    setObject   = (JSONObject) jo.get("set");
                }
                Iterator<String> keys  = where.keys();
                while(keys.hasNext()) {
                    if(i == 0){
                        filter = filter + " WHERE ";
                    } else{
                        filter = filter + " AND ";
                    }
                    String key = keys.next();
                    filter = filter + " " + key + " = '" + (String) where.get(key) + "'";
                    i++;
                }

                i = 0;
                if(!jo.isNull("set")){
                    Iterator<String> setkeys  = setObject.keys();
                    while(setkeys.hasNext()) {
                        if(i == 0){
                            set = " SET ";
                        } else{
                            set = " , ";
                        }
                        String key = setkeys.next();
                        set = set + " " + key + " = '" + (String) setObject.get(key) + "'";
                        i++;
                    }
                }
            } catch (Exception e) {
                Mongo mongo   = new Mongo();
                mongo.setAndInsert(e,"setSqlQueryFromRequestJsonBody","error","Json.sql",null);
            } finally {}
        }
    }
%>
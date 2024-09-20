<%--
  Created by IntelliJ IDEA.
  User: omer.kesmez
  Date: 8.09.2024
  Time: 18:28
--%>
<%@ page import="com.mongodb.client.MongoClients" %>
<%@ page import="com.mongodb.client.MongoDatabase" %>
<%@ page import="org.bson.Document" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.Date" %>
<%@ page import="org.json.JSONObject" %>
<%--
  https://www.mongodb.com/docs/drivers/java/sync/current/usage-examples/
  --------------------------------------------
  How to Use
  -------------------------------------------
  Mongo mongo = new Mongo();
  mongo.setTestData();

  -------------------------------------------
  StringWriter sw = new StringWriter();
  PrintWriter pw  = new PrintWriter(sw);
  exception.printStackTrace(pw);

  Mongo mongo   = new Mongo();
  JSONObject jo = new JSONObject();

  jo.put("method","test");
  jo.put("type","error");
  jo.put("file","Mongo.jsp");
  jo.put("message1",exception.getMessage());
  jo.put("message2",exception.toString());
  jo.put("trace",sw.toString());

  mongo.set(jo);

--%>
<%
    class Mongo{
        private String databaseName   = "api-log";
        private String collectionName = "log";
        private Document insertData;
        private com.mongodb.client.MongoCollection<Document> collection;
        private com.mongodb.client.MongoClient mongoClient;

        public Mongo(){
            try{
                String mongoauth="0";
                if(mongoauth.equals("1")){
                //if(dotenv.get("MONGO_AUTH")){
                    mongoClient  = MongoClients.create("mongodb://usermongo:um123456@127.0.0.1:27017/?authSource=admin&authMechanism=SCRAM-SHA-1");
                } else{
                    mongoClient  = MongoClients.create("mongodb://127.0.0.1:27017");
                }
                MongoDatabase database                      = mongoClient.getDatabase(databaseName);
                collection                                  = database.getCollection(collectionName);
            } catch (Exception e) {
                setAndInsert(e,"Mongo","error","Mongo.sql",null);
            }
        }

        public void insert(){
            try{
                collection.insertOne(insertData);
            } catch (Exception e) {
                setAndInsert(e,"insert","error","Mongo.sql",null);
            }
        }

        public void set(JSONObject jsonObject){
            try{
                String type     = (String) jsonObject.get("type");
                String file     = (String) jsonObject.get("file");
                String message1 = (String) jsonObject.get("message1");
                String message2 = (String) jsonObject.get("message2");
                String method   = (String) jsonObject.get("method");
                String trace    = (String) jsonObject.get("trace");

                insertData = new Document("file", file)
                        .append("type", type)
                        .append("method", method)
                        .append("message1", message1)
                        .append("message2", message2)
                        .append("trace", trace)
                        .append("created_date",new Date());
            }  catch (Exception e) {
                setAndInsert(e,"set","error","Mongo.sql",null);
            }

        }

        /*
         *  How to Use
         *  Mongo mongo   = new Mongo();
         *  mongo.setAndInsert(sqle,"method","error","class",null);
         *  mongo.setAndInsert(null,"method","type","class","Message");
         */
        public void setAndInsert(Exception e, String method, String type, String file, String message){
            try{
                JSONObject jo = new JSONObject();
                if(e != null){
                    StringWriter sw = new StringWriter();
                    PrintWriter pw  = new PrintWriter(sw);
                    e.printStackTrace(pw);

                    jo.put("message1",e.getMessage());
                    jo.put("message2",e.toString());
                    jo.put("trace",sw.toString());

                    if(message != null){
                        jo.put("trace",message);
                    }
                } else{
                    jo.put("message1",message);
                    jo.put("message2",message);
                    jo.put("trace","");
                }
                jo.put("method",method);
                jo.put("type",type);
                jo.put("file",file);

                set(jo);
                insert();
            }  catch (Exception exp) {
                setAndInsert(exp,"setAndInsert","error","Mongo.sql",null);
            }
        }

        public Document setTestData(){
            insertData = new Document("name", "MongoDB")
                    .append("type", "database")
                    .append("count", 1)
                    .append("versions", Arrays.asList("v3.2", "v3.0", "v2.6"))
                    .append("info", new Document("x", 203).append("y", 102))
                    .append("created_date",new Date());

            return insertData;
        }
    }
%>
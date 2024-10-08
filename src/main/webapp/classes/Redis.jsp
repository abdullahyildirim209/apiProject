<%--
  Created by IntelliJ IDEA.
  User: omer.kesmez
  Date: 7.09.2024
  Time: 23:08
--%>
<%@ page import="org.redisson.config.Config" %>
<%@ page import="org.redisson.api.RedissonClient" %>
<%@ page import="org.redisson.Redisson" %>
<%@ page import="org.redisson.api.RBucket" %>
<%@ page import="java.util.concurrent.TimeUnit" %>
<%--
  https://github.com/redisson/redisson/wiki/Table-of-Content
  --------------------------------------------
  How to Use
  -------------------------------------------
  Redis redis = new Redis();
  redis.setString(request.getRemoteAddr(),"omerfarukkesmez");
  String value = redis.getString(request.getRemoteAddr());
  out.print(value);
  -------------------------------------------
--%>
<%
    class Redis{
        private RedissonClient redisson;
        public Redis(){
            Config cnfg = new Config();
            cnfg.useSingleServer().setAddress("redis://" + dotenv.get("REDIS_SERVER") + ":" + dotenv.get("REDIS_PORT")).setPassword(dotenv.get("REDIS_PASSWORD"));
            redisson = Redisson.create(cnfg);
        }

        public void setString(String key, String value){
            RBucket<String> bucket  = redisson.getBucket(key);
            bucket.set(value,2,TimeUnit.MINUTES);
        }


        public String getString(String key){
            RBucket<String> bucket  = redisson.getBucket(key);
            return bucket.get();
        }

        public void shutdown(){
            redisson.shutdown();
        }
    }
%>
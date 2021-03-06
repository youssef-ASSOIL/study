use nuria;
-- getting all pageviews from bots

drop table if exists classifier_training_data_labeled_bot;
create table  classifier_training_data_labeled_bot
AS
select 
    rand(1) row_id,
 --   year,
 --   month,
 --   day,
    dt, 
    ts,
    ip,
    lower(uri_host) AS domain,
    -- long user agents are  asign of bot traffic 
    md5(concat(ip, substr(user_agent,0,200), accept_language, uri_host)) AS sessionId,
    http_status,
    uri_path,
    uri_query,
    user_agent,
    x_analytics_map["nocookies"] as nocookies,
    x_analytics_map["WMF-Last-Access-Global"] as last_access,
    access_method,
    agent_type

from wmf.webrequest 
where agent_type="spider"
and year=2019 and month=10 and day=16
and is_pageview=1 ;


drop table if exists classifier_training_data_bot_sorted_tmp;
drop table if exists distinct_sessions_bot;
drop table if exists classifier_training_data_bot_sorted; 


 create table
    classifier_training_data_bot_sorted_tmp
 as
    select * 
    from classifier_training_data_labeled_bot as A 
    order by A.sessionid,ts limit 10000000 ;

-- there is a lot of data, just get 100000 sessions
SET hive.groupby.orderby.position.alias=false
create table distinct_sessions_bot
as
    select sessionId, count(*) as c  from classifier_training_data_bot_sorted_tmp group by sessionId limit 100000;


create table classifier_training_data_bot_sorted 
as
    select * from classifier_training_data_bot_sorted_tmp b
    where b.sessionId in (select sessionId from nuria.distinct_sessions_bot where c >10) 
    order by b.sessionId,ts limit 10000000;

drop table distinct_sessions_bot;
drop table classifier_training_data_bot_sorted_tmp;
drop table classifier_training_data_labeled_bot;






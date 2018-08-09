# -Ballerina-with-Honeycomb-integration
This repo is created to implement ballerina service integration with honeycomb

This is run using the honeycomb open tracing proxy (https://docs.honeycomb.io/working-with-data/tracing/send-trace-data/). 
This is achieved by obtaining the traces from ballerina services as Zipkin compatible tracing metadata.

To start the honeycomb open tracing proxy Docker is used. 
    
    docker run -p 9411:9411 honeycombio/honeycomb-opentracing-proxy -k APIKEY -d traces 

  -k represents the APIKEY for your honeycomb connection (obtained when you sign in to honeycomb).
  
  -d represents the name of the dataset you are sending your traces to.
  
  
# -Service 
This is basically a small student record system. This service is mainly created focusing on the integration with Honeycomb for observability purpose. 

The student data are stored in the local mysql database.
The sql file has been included in the repo for your ease.


